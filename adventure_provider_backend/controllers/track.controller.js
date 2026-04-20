const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const Track = require('../models/track.model');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

/**
 * Removes a file stored under `uploads/...` (relative path or full URL to this server).
 * Ignores missing files and non-local URLs.
 */
async function unlinkUploadSafe(stored) {
  if (!stored || typeof stored !== 'string') return;
  try {
    let relative = stored.trim();
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      const u = new URL(relative);
      relative = (u.pathname || '').replace(/^\//, '');
    } else {
      relative = relative.replace(/^\//, '');
    }
    if (!relative.startsWith('uploads/')) return;
    const diskPath = path.join(__dirname, '..', relative);
    await fs.promises.unlink(diskPath);
  } catch (err) {
    if (err && err.code === 'ENOENT') return;
  }
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
 * POST /draft — minimal track for live recording (Socket.io room id). Body: title, description,
 * type, difficulty, isPublic, isTesting.
 */
async function createDraftTrack(req, res) {
  try {
    const { title, description, type, difficulty, isPublic, isTesting } = req.body;

    const track = await Track.create({
      userId: req.user._id,
      title,
      description,
      type,
      difficulty,
      isPublic: isPublic !== undefined ? Boolean(isPublic) : true,
      isTesting: Boolean(isTesting),
      status: 'recording',
    });

    return res.status(201).json(track);
  } catch (err) {
    console.error('createDraftTrack error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to create draft track' });
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

/**
 * POST /tracks/:id/flag-image — multipart field `image`. Owner only.
 * Returns `{ url }` as a relative path (e.g. uploads/tracks/flags/...) for DB storage; clients resolve with their API origin.
 */
async function uploadTrackFlagImage(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Image file is required' });
    }

    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Not allowed to modify this track' });
    }

    const relativePath = `uploads/tracks/flags/${req.file.filename}`;
    return res.status(200).json({ url: relativePath });
  } catch (err) {
    console.error('uploadTrackFlagImage error:', err);
    return res.status(500).json({ message: 'Could not upload image. Please try again.' });
  }
}

/**
 * POST /:id/photos — multipart field `photo`. Owner only.
 */
async function postTrackPhoto(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Photo file is required' });
    }

    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Only the track owner can add photos' });
    }

    const relativePath = `uploads/tracks/photos/${req.file.filename}`;
    track.photos.push(relativePath);
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('postTrackPhoto error:', err);
    return res.status(500).json({ message: 'Could not save photo. Please try again.' });
  }
}

/**
 * DELETE /:id/photos/:photoIndex — owner only. Removes file from disk when stored under uploads/.
 */
async function deleteTrackPhoto(req, res) {
  try {
    const { id, photoIndex } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }
    if (!/^\d+$/.test(String(photoIndex))) {
      return res.status(400).json({ message: 'Invalid photo index' });
    }
    const idx = parseInt(photoIndex, 10);
    if (idx < 0) {
      return res.status(400).json({ message: 'Invalid photo index' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Only the track owner can remove photos' });
    }
    if (idx >= track.photos.length) {
      return res.status(404).json({ message: 'Photo not found' });
    }

    const removed = track.photos[idx];
    track.photos.splice(idx, 1);
    await track.save();
    await unlinkUploadSafe(removed);
    return res.status(200).json(track);
  } catch (err) {
    console.error('deleteTrackPhoto error:', err);
    return res.status(500).json({ message: 'Could not remove photo. Please try again.' });
  }
}

/**
 * POST /:id/flags — body: { type, description?, location: { lng, lat }, images?[] }. Owner only.
 */
async function postTrackFlag(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const { type, description, location, images } = req.body;
    if (type === undefined || type === null || String(type).trim() === '') {
      return res.status(400).json({ message: 'type is required' });
    }
    const lat = location && location.lat;
    const lng = location && location.lng;
    if (!Number.isFinite(Number(lat)) || !Number.isFinite(Number(lng))) {
      return res.status(400).json({ message: 'location with numeric lng and lat is required' });
    }

    const imagesArr = Array.isArray(images)
      ? images.filter((x) => typeof x === 'string').map((x) => x.trim())
      : [];

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Only the track owner can add flags' });
    }

    track.flags.push({
      type: String(type).trim(),
      description: description != null ? String(description) : '',
      images: imagesArr,
      location: {
        type: 'Point',
        coordinates: [Number(lng), Number(lat)],
      },
    });
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('postTrackFlag error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: 'Invalid flag data' });
    }
    return res.status(500).json({ message: 'Could not add flag. Please try again.' });
  }
}

/**
 * PUT /:id/flags/:flagId — partial update: type, description, location, images. Owner only.
 */
async function putTrackFlag(req, res) {
  try {
    const { id, flagId } = req.params;
    if (!isValidObjectId(id) || !isValidObjectId(flagId)) {
      return res.status(400).json({ message: 'Invalid track or flag id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Only the track owner can edit flags' });
    }

    const flag = track.flags.id(flagId);
    if (!flag) {
      return res.status(404).json({ message: 'Flag not found' });
    }

    const { type, description, location, images } = req.body;

    if (type !== undefined) {
      if (type === null || String(type).trim() === '') {
        return res.status(400).json({ message: 'type cannot be empty' });
      }
      flag.type = String(type).trim();
    }
    if (description !== undefined) {
      flag.description = description == null ? '' : String(description);
    }
    if (location !== undefined) {
      const lat = location.lat;
      const lng = location.lng;
      if (!Number.isFinite(Number(lat)) || !Number.isFinite(Number(lng))) {
        return res.status(400).json({ message: 'location must include numeric lng and lat' });
      }
      flag.location = {
        type: 'Point',
        coordinates: [Number(lng), Number(lat)],
      };
    }
    if (images !== undefined) {
      if (!Array.isArray(images)) {
        return res.status(400).json({ message: 'images must be an array' });
      }
      const oldList = [...(flag.images || [])];
      const newList = images.filter((x) => typeof x === 'string').map((x) => x.trim());
      const removed = oldList.filter((x) => !newList.includes(x));
      for (const r of removed) {
        await unlinkUploadSafe(r);
      }
      flag.images = newList;
    }

    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('putTrackFlag error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: 'Invalid flag data' });
    }
    return res.status(500).json({ message: 'Could not update flag. Please try again.' });
  }
}

/**
 * DELETE /:id/flags/:flagId — owner only. Deletes flag images from disk.
 */
async function deleteTrackFlag(req, res) {
  try {
    const { id, flagId } = req.params;
    if (!isValidObjectId(id) || !isValidObjectId(flagId)) {
      return res.status(400).json({ message: 'Invalid track or flag id' });
    }

    const track = await Track.findById(id);
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }
    if (!track.userId.equals(req.user._id)) {
      return res.status(403).json({ message: 'Only the track owner can delete flags' });
    }

    const flag = track.flags.id(flagId);
    if (!flag) {
      return res.status(404).json({ message: 'Flag not found' });
    }

    const toUnlink = [...(flag.images || [])];
    if (flag.photo) {
      toUnlink.push(flag.photo);
    }
    for (const p of toUnlink) {
      await unlinkUploadSafe(p);
    }

    track.flags.pull({ _id: flagId });
    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('deleteTrackFlag error:', err);
    return res.status(500).json({ message: 'Could not delete flag. Please try again.' });
  }
}

/**
 * POST /:id/sync — owner only. Body: { points: [{ latitude, longitude, altitude, speed, timestamp }], distance?, duration? }
 * Appends [lng, lat] pairs to geoPath.coordinates; optional distance/duration on the track.
 */
async function syncTrackPoints(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const { points, distance, duration } = req.body;
    if (!Array.isArray(points) || points.length === 0) {
      return res.status(400).json({ message: 'points must be a non-empty array' });
    }

    const track = await Track.findOne({ _id: id, userId: req.user._id });
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

    if (!track.geoPath || !Array.isArray(track.geoPath.coordinates)) {
      await Track.updateOne(
        { _id: id, userId: req.user._id },
        { $set: { geoPath: { type: 'LineString', coordinates: [] } } }
      );
    }

    const update = {
      $push: { 'geoPath.coordinates': { $each: coords } },
    };
    const $set = {};
    if (distance !== undefined && distance !== null) {
      $set.distance = Number(distance);
    }
    if (duration !== undefined && duration !== null) {
      $set.duration = Number(duration);
    }
    if (Object.keys($set).length) {
      update.$set = $set;
    }

    await Track.updateOne({ _id: id, userId: req.user._id }, update);

    return res.status(200).json({ success: true, synced: points.length });
  } catch (err) {
    console.error('syncTrackPoints error:', err);
    return res.status(500).json({ message: err.message || 'Failed to sync points' });
  }
}

/**
 * POST /:id/complete — owner only. Final metadata; marks track completed.
 * Body: { title, description, type, difficulty, distance, duration, steps, calories }
 */
async function completeTrack(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid track id' });
    }

    const {
      title,
      description,
      type,
      difficulty,
      distance,
      duration,
      steps,
      calories,
    } = req.body;

    const track = await Track.findOne({ _id: id, userId: req.user._id });
    if (!track) {
      return res.status(404).json({ message: 'Track not found' });
    }

    if (title !== undefined) track.title = title;
    if (description !== undefined) track.description = description;
    if (type !== undefined) track.type = type;
    if (difficulty !== undefined) track.difficulty = difficulty;
    if (distance !== undefined) track.distance = Number(distance);
    if (duration !== undefined) track.duration = Number(duration);
    if (steps !== undefined) track.steps = Number(steps);
    if (calories !== undefined) track.calories = Number(calories);

    track.status = 'completed';
    track.isComplete = true;

    await track.save();
    return res.status(200).json(track);
  } catch (err) {
    console.error('completeTrack error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to complete track' });
  }
}

module.exports = {
  createTrack,
  createDraftTrack,
  getMyTracks,
  getNearbyTracks,
  getTrackById,
  updateTrack,
  deleteTrack,
  likeTrack,
  saveTrack,
  addFlag,
  addPhoto,
  uploadTrackFlagImage,
  postTrackPhoto,
  deleteTrackPhoto,
  postTrackFlag,
  putTrackFlag,
  deleteTrackFlag,
  syncTrackPoints,
  completeTrack,
};
