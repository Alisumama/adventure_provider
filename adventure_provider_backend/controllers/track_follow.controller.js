const mongoose = require('mongoose');
const Track = require('../models/track.model');
const TrackFollow = require('../models/track_follow.model');
const User = require('../models/User');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

/** Haversine distance in meters between two [lng, lat] pairs. */
function haversineMeters(a, b) {
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371000;
  const [lng1, lat1] = a;
  const [lng2, lat2] = b;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(x)));
}

/** Reference length (m) for completion %: prefer Track.distance, else sum of geoPath segments. */
function referenceTrackLengthMeters(track) {
  const d = Number(track.distance);
  if (Number.isFinite(d) && d > 0) {
    return d;
  }
  const coords = track.geoPath && Array.isArray(track.geoPath.coordinates) ? track.geoPath.coordinates : [];
  if (coords.length < 2) {
    return 0;
  }
  let sum = 0;
  for (let i = 1; i < coords.length; i++) {
    sum += haversineMeters(coords[i - 1], coords[i]);
  }
  return sum;
}

function computeCompletionPercentage(totalDistance, trackDoc) {
  const walked = Number(totalDistance);
  if (!Number.isFinite(walked) || walked < 0) {
    return 0;
  }
  const refM = referenceTrackLengthMeters(trackDoc);
  if (refM <= 0) {
    return 0;
  }
  return Math.min(100, Math.round((walked / refM) * 100));
}

async function startFollowing(req, res) {
  try {
    const { trackId } = req.body;
    if (!trackId || !isValidObjectId(trackId)) {
      return res.status(400).json({ message: 'Valid trackId is required' });
    }

    const track = await Track.findById(trackId).lean();
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    const uid = req.user._id;
    const existing = await TrackFollow.findOne({
      trackId,
      userId: uid,
      isCompleted: false,
    }).populate({ path: 'trackId' });

    if (existing) {
      const o = existing.toObject();
      return res.status(200).json({
        ...o,
        track: o.trackId,
      });
    }

    const follow = await TrackFollow.create({
      trackId,
      userId: uid,
    });

    const populatedTrack = await Track.findById(trackId).lean();
    return res.status(201).json({
      ...follow.toObject(),
      track: populatedTrack,
    });
  } catch (err) {
    console.error('startFollowing error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to start following' });
  }
}

async function syncFollowPoints(req, res) {
  try {
    const { followId } = req.params;
    if (!isValidObjectId(followId)) {
      return res.status(400).json({ message: 'Invalid follow id' });
    }

    const {
      points,
      totalDistance,
      duration,
      steps,
      calories,
    } = req.body;

    if (!Array.isArray(points) || points.length === 0) {
      return res.status(400).json({ message: 'points must be a non-empty array' });
    }

    const follow = await TrackFollow.findOne({
      _id: followId,
      userId: req.user._id,
      isCompleted: false,
    });
    if (!follow) {
      return res.status(404).json({ message: 'Active follow session not found' });
    }

    const track = await Track.findById(follow.trackId).lean();
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    const coords = [];
    for (const p of points) {
      const lat = Number(p.latitude);
      const lng = Number(p.longitude);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        return res.status(400).json({ message: 'Each point must have valid latitude and longitude' });
      }
      coords.push([lng, lat]);
    }

    const td = totalDistance !== undefined && totalDistance !== null ? Number(totalDistance) : follow.totalDistance;
    const dur = duration !== undefined && duration !== null ? Number(duration) : follow.duration;
    const st = steps !== undefined && steps !== null ? Number(steps) : follow.steps;
    const cal = calories !== undefined && calories !== null ? Number(calories) : follow.calories;

    const completionPercentage = computeCompletionPercentage(td, track);

    const mongoUpdate = {
      $push: { 'followPath.coordinates': { $each: coords } },
      $set: {
        totalDistance: td,
        duration: dur,
        steps: st,
        calories: cal,
        completionPercentage,
        'followPath.type': 'LineString',
      },
    };

    await TrackFollow.updateOne({ _id: follow._id }, mongoUpdate);

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('syncFollowPoints error:', err);
    return res.status(500).json({ message: err.message || 'Failed to sync follow points' });
  }
}

async function recordDeviation(req, res) {
  try {
    const { followId } = req.params;
    if (!isValidObjectId(followId)) {
      return res.status(400).json({ message: 'Invalid follow id' });
    }

    const { latitude, longitude, distanceFromTrack } = req.body;
    const lat = Number(latitude);
    const lng = Number(longitude);
    const dist = Number(distanceFromTrack);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ message: 'Valid latitude and longitude are required' });
    }
    if (!Number.isFinite(dist)) {
      return res.status(400).json({ message: 'Valid distanceFromTrack is required' });
    }

    const follow = await TrackFollow.findOne({
      _id: followId,
      userId: req.user._id,
      isCompleted: false,
    });
    if (!follow) {
      return res.status(404).json({ message: 'Active follow session not found' });
    }

    follow.deviationPoints.push({
      coordinates: [lng, lat],
      timestamp: new Date(),
      distanceFromTrack: dist,
    });
    follow.deviationCount = (follow.deviationCount || 0) + 1;
    const currentMax = follow.maxDeviation == null ? 0 : follow.maxDeviation;
    if (dist > currentMax) {
      follow.maxDeviation = dist;
    }
    await follow.save();

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('recordDeviation error:', err);
    return res.status(500).json({ message: err.message || 'Failed to record deviation' });
  }
}

async function completeFollowing(req, res) {
  try {
    const { followId } = req.params;
    if (!isValidObjectId(followId)) {
      return res.status(400).json({ message: 'Invalid follow id' });
    }

    const {
      totalDistance,
      duration,
      steps,
      calories,
      completionPercentage,
    } = req.body;

    const follow = await TrackFollow.findOne({
      _id: followId,
      userId: req.user._id,
      isCompleted: false,
    });
    if (!follow) {
      return res.status(404).json({ message: 'Active follow session not found' });
    }

    const track = await Track.findById(follow.trackId).lean();
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    const td = totalDistance !== undefined && totalDistance !== null ? Number(totalDistance) : follow.totalDistance;
    const dur = duration !== undefined && duration !== null ? Number(duration) : follow.duration;
    const st = steps !== undefined && steps !== null ? Number(steps) : follow.steps;
    const cal = calories !== undefined && calories !== null ? Number(calories) : follow.calories;
    let pct =
      completionPercentage !== undefined && completionPercentage !== null
        ? Number(completionPercentage)
        : computeCompletionPercentage(td, track);
    pct = Math.min(100, Math.max(0, pct));

    follow.isCompleted = true;
    follow.completedAt = new Date();
    follow.totalDistance = td;
    follow.duration = dur;
    follow.steps = st;
    follow.calories = cal;
    follow.completionPercentage = pct;
    await follow.save();

    await Track.updateOne({ _id: follow.trackId }, { $inc: { followCount: 1 } });
    await User.updateOne({ _id: req.user._id }, { $inc: { totalAdventures: 1 } });

    const completed = await TrackFollow.findById(follow._id)
      .populate({ path: 'trackId' })
      .lean();

    return res.status(200).json(completed);
  } catch (err) {
    console.error('completeFollowing error:', err);
    return res.status(500).json({ message: err.message || 'Failed to complete following' });
  }
}

async function getTrackFollowers(req, res) {
  try {
    const { trackId } = req.params;
    if (!isValidObjectId(trackId)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const rows = await TrackFollow.find({
      trackId,
      isCompleted: true,
    })
      .populate({ path: 'userId', select: 'name profileImage' })
      .sort({ completedAt: -1 })
      .limit(20)
      .lean();

    return res.status(200).json(rows);
  } catch (err) {
    console.error('getTrackFollowers error:', err);
    return res.status(500).json({ message: err.message || 'Failed to load followers' });
  }
}

async function getMyFollowHistory(req, res) {
  try {
    const rows = await TrackFollow.find({ userId: req.user._id })
      .populate({ path: 'trackId' })
      .sort({ startedAt: -1 })
      .lean();

    return res.status(200).json(rows);
  } catch (err) {
    console.error('getMyFollowHistory error:', err);
    return res.status(500).json({ message: err.message || 'Failed to load follow history' });
  }
}

module.exports = {
  startFollowing,
  syncFollowPoints,
  recordDeviation,
  completeFollowing,
  getTrackFollowers,
  getMyFollowHistory,
};
