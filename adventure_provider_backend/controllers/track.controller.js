const mongoose = require('mongoose');
const Track = require('../models/track.model');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

/**
 * POST — create track (body: title, description, type, difficulty, geoPath, startPoint, endPoint,
 * distance, duration, steps, calories, isPublic). userId from JWT.
 */
async function createTrack(req, res) {
  try {
    const {
      title,
      description,
      type,
      difficulty,
      geoPath,
      startPoint,
      endPoint,
      distance,
      duration,
      steps,
      calories,
      isPublic,
    } = req.body;

    const track = await Track.create({
      userId: req.user._id,
      title,
      description,
      type,
      difficulty,
      geoPath,
      startPoint,
      endPoint,
      distance,
      duration,
      steps,
      calories,
      isPublic,
    });

    return res.status(201).json(track);
  } catch (err) {
    console.error('createTrack error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to create track' });
  }
}

/**
 * GET — all tracks for logged-in user, newest first.
 */
async function getMyTracks(req, res) {
  try {
    const tracks = await Track.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .lean();
    return res.status(200).json(tracks);
  } catch (err) {
    console.error('getMyTracks error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch tracks' });
  }
}

/**
 * GET — query: lat, lng, radius (meters, default 10000). Public tracks near startPoint, max 20.
 */
async function getNearbyTracks(req, res) {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const radius = parseFloat(req.query.radius);
    const maxDistance = Number.isFinite(radius) && radius > 0 ? radius : 10000;

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ message: 'Query params lat and lng are required numbers' });
    }

    const tracks = await Track.find({
      isPublic: true,
      startPoint: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [lng, lat],
          },
          $maxDistance: maxDistance,
        },
      },
    }).limit(20);

    return res.status(200).json(tracks);
  } catch (err) {
    console.error('getNearbyTracks error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch nearby tracks' });
  }
}

/**
 * GET — single track by id; userId populated (name, profileImage).
 */
async function getTrackById(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id).populate('userId', 'name profileImage');
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    return res.status(200).json(track);
  } catch (err) {
    console.error('getTrackById error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch track' });
  }
}

/**
 * PUT — update track; only owner. Same body fields as create (excluding userId).
 */
async function updateTrack(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Not allowed to update this track' });
    }

    const {
      title,
      description,
      type,
      difficulty,
      geoPath,
      startPoint,
      endPoint,
      distance,
      duration,
      steps,
      calories,
      isPublic,
    } = req.body;

    if (title !== undefined) track.title = title;
    if (description !== undefined) track.description = description;
    if (type !== undefined) track.type = type;
    if (difficulty !== undefined) track.difficulty = difficulty;
    if (geoPath !== undefined) track.geoPath = geoPath;
    if (startPoint !== undefined) track.startPoint = startPoint;
    if (endPoint !== undefined) track.endPoint = endPoint;
    if (distance !== undefined) track.distance = distance;
    if (duration !== undefined) track.duration = duration;
    if (steps !== undefined) track.steps = steps;
    if (calories !== undefined) track.calories = calories;
    if (isPublic !== undefined) track.isPublic = isPublic;

    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('updateTrack error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to update track' });
  }
}

/**
 * DELETE — only owner.
 */
async function deleteTrack(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Not allowed to delete this track' });
    }

    await track.deleteOne();
    return res.status(200).json({ message: 'Track deleted' });
  } catch (err) {
    console.error('deleteTrack error:', err);
    return res.status(500).json({ message: err.message || 'Failed to delete track' });
  }
}

/**
 * POST — toggle like for track :id.
 */
async function likeTrack(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    const uid = req.user._id;
    const idx = track.likes.findIndex((likeId) => likeId.equals(uid));
    if (idx === -1) {
      track.likes.push(uid);
    } else {
      track.likes.splice(idx, 1);
    }
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('likeTrack error:', err);
    return res.status(500).json({ message: err.message || 'Failed to toggle like' });
  }
}

/**
 * POST — toggle save for track :id.
 */
async function saveTrack(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    const uid = req.user._id;
    const idx = track.saves.findIndex((saveId) => saveId.equals(uid));
    if (idx === -1) {
      track.saves.push(uid);
    } else {
      track.saves.splice(idx, 1);
    }
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('saveTrack error:', err);
    return res.status(500).json({ message: err.message || 'Failed to toggle save' });
  }
}

/**
 * POST — body: title, description, photo, coordinates ([lng, lat]). Track id from :id or body.trackId. Owner only.
 */
async function addFlag(req, res) {
  try {
    const trackId = req.params.id || req.body.trackId;
    const { title, description, photo, coordinates } = req.body;
    if (!trackId || !isValidObjectId(trackId)) {
      return res.status(400).json({ message: 'Valid track id is required' });
    }
    if (!Array.isArray(coordinates) || coordinates.length < 2) {
      return res.status(400).json({ message: 'coordinates must be [lng, lat]' });
    }

    const track = await Track.findById(trackId);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Not allowed to modify this track' });
    }

    track.flags.push({
      title,
      description,
      photo,
      location: {
        type: 'Point',
        coordinates,
      },
    });
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('addFlag error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to add flag' });
  }
}

/**
 * POST — body: photoUrl. Track id from :id or body.trackId. Owner only.
 */
async function addPhoto(req, res) {
  try {
    const trackId = req.params.id || req.body.trackId;
    const { photoUrl } = req.body;
    if (!trackId || !isValidObjectId(trackId)) {
      return res.status(400).json({ message: 'Valid track id is required' });
    }
    if (!photoUrl || typeof photoUrl !== 'string') {
      return res.status(400).json({ message: 'photoUrl is required' });
    }

    const track = await Track.findById(trackId);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Not allowed to modify this track' });
    }

    track.photos.push(photoUrl.trim());
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('addPhoto error:', err);
    return res.status(500).json({ message: err.message || 'Failed to add photo' });
  }
}

module.exports = {
  createTrack,
  getMyTracks,
  getNearbyTracks,
  getTrackById,
  updateTrack,
  deleteTrack,
  likeTrack,
  saveTrack,
  addFlag,
  addPhoto,
};
