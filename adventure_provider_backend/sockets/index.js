const { Server } = require('socket.io');
const mongoose = require('mongoose');

const Track = require('../models/track.model');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

function userFriendlyMessage(err) {
  if (!err) return 'Something went wrong. Please try again.';
  if (err.name === 'ValidationError') return 'Invalid track data.';
  if (err.name === 'CastError') return 'Invalid id.';
  return 'Something went wrong. Please try again.';
}

function roomName(trackId) {
  return String(trackId);
}

function parseLngLatPair(coordinates) {
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;
  const lng = Number(coordinates[0]);
  const lat = Number(coordinates[1]);
  if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
  return [lng, lat];
}

function parseEndPoint(endPoint) {
  if (!endPoint || typeof endPoint !== 'object') return null;
  const lng = Number(endPoint.lng);
  const lat = Number(endPoint.lat);
  if (!Number.isFinite(lng) || !Number.isFinite(lat)) return null;
  return {
    type: 'Point',
    coordinates: [lng, lat],
  };
}

/**
 * Live track recording: start_track, location_update, add_flag, end_track.
 * @param {import('http').Server} server
 */
function initLiveTrackSocket(server) {
  const io = new Server(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  io.on('connection', (socket) => {
    socket.on('start_track', async (payload) => {
      try {
        const { userId, trackId } = payload || {};
        if (!userId || !trackId) {
          socket.emit('track_error', { message: 'Track and user are required.' });
          return;
        }
        if (!isValidObjectId(String(userId)) || !isValidObjectId(String(trackId))) {
          socket.emit('track_error', { message: 'Invalid track or user id.' });
          return;
        }

        const track = await Track.findById(trackId);
        if (!track) {
          socket.emit('track_error', { message: 'Track not found.' });
          return;
        }

        const uid = new mongoose.Types.ObjectId(String(userId));
        if (!track.userId.equals(uid)) {
          socket.emit('track_error', { message: 'You are not allowed to record this track.' });
          return;
        }

        await socket.join(roomName(trackId));
      } catch (err) {
        console.error('start_track', err);
        socket.emit('track_error', { message: userFriendlyMessage(err) });
      }
    });

    socket.on('location_update', async (payload) => {
      try {
        const { trackId, coordinates } = payload || {};
        if (!trackId || !isValidObjectId(String(trackId))) {
          socket.emit('track_error', { message: 'Invalid track id.' });
          return;
        }

        const pair = parseLngLatPair(coordinates);
        if (!pair) {
          socket.emit('track_error', { message: 'Invalid coordinates. Expected [lng, lat].' });
          return;
        }
        const [lng, lat] = pair;

        const track = await Track.findById(trackId);
        if (!track) {
          socket.emit('track_error', { message: 'Track not found.' });
          return;
        }

        if (!track.geoPath) {
          track.geoPath = { type: 'LineString', coordinates: [] };
        }
        if (!Array.isArray(track.geoPath.coordinates)) {
          track.geoPath.coordinates = [];
        }
        track.geoPath.type = 'LineString';
        track.geoPath.coordinates.push([lng, lat]);
        track.markModified('geoPath');
        await track.save();

        io.to(roomName(trackId)).emit('path_updated', {
          trackId: String(trackId),
          coordinates: [lng, lat],
          geoPath: track.geoPath,
        });
      } catch (err) {
        console.error('location_update', err);
        socket.emit('track_error', { message: userFriendlyMessage(err) });
      }
    });

    socket.on('add_flag', async (payload) => {
      try {
        const { trackId, flag } = payload || {};
        if (!trackId || !isValidObjectId(String(trackId))) {
          socket.emit('track_error', { message: 'Invalid track id.' });
          return;
        }
        if (!flag || typeof flag !== 'object') {
          socket.emit('track_error', { message: 'Flag data is required.' });
          return;
        }

        const loc = flag.location;
        if (!loc || typeof loc !== 'object') {
          socket.emit('track_error', { message: 'Flag location is required.' });
          return;
        }
        const lng = Number(loc.lng);
        const lat = Number(loc.lat);
        if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
          socket.emit('track_error', { message: 'Invalid flag location.' });
          return;
        }

        const track = await Track.findById(trackId);
        if (!track) {
          socket.emit('track_error', { message: 'Track not found.' });
          return;
        }

        const images = Array.isArray(flag.images)
          ? flag.images.filter((u) => typeof u === 'string' && u.trim().length > 0)
          : [];

        const flagDoc = {
          type: typeof flag.type === 'string' ? flag.type.trim() : undefined,
          description: typeof flag.description === 'string' ? flag.description.trim() : undefined,
          images,
          location: {
            type: 'Point',
            coordinates: [lng, lat],
          },
        };

        track.flags.push(flagDoc);
        await track.save();

        const added = track.flags[track.flags.length - 1];

        io.to(roomName(trackId)).emit('flag_added', {
          trackId: String(trackId),
          flag: added.toObject ? added.toObject() : added,
        });
      } catch (err) {
        console.error('add_flag', err);
        socket.emit('track_error', { message: userFriendlyMessage(err) });
      }
    });

    socket.on('end_track', async (payload) => {
      try {
        const { trackId, endPoint, distance, duration, steps, calories } = payload || {};
        if (!trackId || !isValidObjectId(String(trackId))) {
          socket.emit('track_error', { message: 'Invalid track id.' });
          return;
        }

        const endPointGeo = parseEndPoint(endPoint);
        if (!endPointGeo) {
          socket.emit('track_error', { message: 'Invalid end point. Expected { lng, lat }.' });
          return;
        }

        const d = Number(distance);
        const dur = Number(duration);
        const s = Number(steps);
        const c = Number(calories);
        if (
          !Number.isFinite(d) ||
          !Number.isFinite(dur) ||
          !Number.isFinite(s) ||
          !Number.isFinite(c)
        ) {
          socket.emit('track_error', { message: 'Invalid distance, duration, steps, or calories.' });
          return;
        }

        const track = await Track.findById(trackId);
        if (!track) {
          socket.emit('track_error', { message: 'Track not found.' });
          return;
        }

        track.endPoint = endPointGeo;
        track.distance = d;
        track.duration = dur;
        track.steps = s;
        track.calories = c;
        track.isComplete = true;
        await track.save();

        io.to(roomName(trackId)).emit('track_ended', {
          trackId: String(trackId),
          endPoint: track.endPoint,
          distance: track.distance,
          duration: track.duration,
          steps: track.steps,
          calories: track.calories,
          isComplete: track.isComplete,
        });
      } catch (err) {
        console.error('end_track', err);
        socket.emit('track_error', { message: userFriendlyMessage(err) });
      }
    });
  });

  return io;
}

module.exports = initLiveTrackSocket;
