const { Server } = require('socket.io');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const Track = require('../models/track.model');
const User = require('../models/User');
const LiveSession = require('../models/live_session.model');

const JWT_SECRET = process.env.JWT_SECRET || 'jwt-secret-change-in-production';

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

  // ── Group tracking namespace ──
  const groupNsp = io.of('/group');

  groupNsp.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token) return next(new Error('Authentication required'));

      const decoded = jwt.verify(token, JWT_SECRET);
      const user = await User.findById(decoded.id).select('name profileImage').lean();
      if (!user) return next(new Error('User not found'));

      socket.userId = user._id.toString();
      socket.userName = user.name || '';
      socket.userProfileImage = user.profileImage || '';
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  groupNsp.on('connection', (socket) => {
    console.log(`[group-socket] connected: userId=${socket.userId} name=${socket.userName}`);
    // Track which group rooms this socket has joined
    const joinedRooms = new Map(); // groupId -> liveSessionId

    socket.on('join_group_room', async (payload) => {
      try {
        const { groupId, liveSessionId } = payload || {};
        console.log(`[group-socket] join_group_room userId=${socket.userId} groupId=${groupId} sessionId=${liveSessionId}`);
        if (!groupId || !liveSessionId) return;

        const room = `group_${groupId}`;
        socket.join(room);
        joinedRooms.set(groupId, liveSessionId);

        const uid = new mongoose.Types.ObjectId(socket.userId);
        // Update member isOnline in LiveSession
        const joinRes = await LiveSession.updateOne(
          { _id: liveSessionId, 'memberSessions.userId': new mongoose.Types.ObjectId(socket.userId) },
          { $set: { 'memberSessions.$.isOnline': true, 'memberSessions.$.joinedAt': new Date() } }
        );
        // Ensure member session exists so locationPath is persisted from first update.
        if (!joinRes.matchedCount) {
          await LiveSession.updateOne(
            { _id: liveSessionId },
            {
              $push: {
                memberSessions: {
                  userId: uid,
                  joinedAt: new Date(),
                  isOnline: true,
                  locationPath: [],
                },
              },
            }
          );
        }

        socket.to(room).emit('member_joined', {
          userId: socket.userId,
          name: socket.userName,
          profileImage: socket.userProfileImage,
        });
      } catch (err) {
        console.error('join_group_room', err);
        socket.emit('group_error', { message: 'Failed to join group room' });
      }
    });

    socket.on('location_update', async (payload) => {
      try {
        const { groupId, liveSessionId, latitude, longitude, timestamp } = payload || {};
        if (!groupId || !liveSessionId || latitude == null || longitude == null) return;

        const room = `group_${groupId}`;
        const roomSockets = await groupNsp.in(room).fetchSockets();
        console.log(`[group-socket] location_update userId=${socket.userId} room=${room} socketsInRoom=${roomSockets.length} lat=${latitude} lng=${longitude}`);
        const shortName = (socket.userName || '').split(' ')[0].slice(0, 8);

        groupNsp.to(room).emit('member_location', {
          userId: socket.userId,
          name: socket.userName,
          shortName,
          profileImage: socket.userProfileImage,
          liveSessionId,
          latitude,
          longitude,
          timestamp: timestamp || Date.now(),
        });

        // Update LiveSession in background
        const uid = new mongoose.Types.ObjectId(socket.userId);
        const updateRes = await LiveSession.updateOne(
          { _id: liveSessionId, 'memberSessions.userId': uid },
          {
            $set: {
              'memberSessions.$.lastLocation': {
                type: 'Point',
                coordinates: [longitude, latitude],
              },
              'memberSessions.$.lastSeenAt': new Date(),
              'memberSessions.$.isOnline': true,
            },
            $push: {
              'memberSessions.$.locationPath': [longitude, latitude],
            },
          }
        );
        if (!updateRes.matchedCount) {
          await LiveSession.updateOne(
            { _id: liveSessionId },
            {
              $push: {
                memberSessions: {
                  userId: uid,
                  joinedAt: new Date(),
                  isOnline: true,
                  lastLocation: {
                    type: 'Point',
                    coordinates: [longitude, latitude],
                  },
                  lastSeenAt: new Date(),
                  locationPath: [[longitude, latitude]],
                },
              },
            }
          );
        }
      } catch (err) {
        console.error('group location_update', err);
      }
    });

    socket.on('leave_group_room', async (payload) => {
      try {
        const { groupId, liveSessionId } = payload || {};
        if (!groupId || !liveSessionId) return;

        const room = `group_${groupId}`;
        const uid = new mongoose.Types.ObjectId(socket.userId);

        await LiveSession.updateOne(
          { _id: liveSessionId, 'memberSessions.userId': uid },
          {
            $set: {
              'memberSessions.$.isOnline': false,
              'memberSessions.$.leftAt': new Date(),
            },
          }
        );

        socket.to(room).emit('member_left', {
          userId: socket.userId,
          name: socket.userName,
        });

        socket.leave(room);
        joinedRooms.delete(groupId);
      } catch (err) {
        console.error('leave_group_room', err);
      }
    });

    socket.on('emergency_sos', (payload) => {
      try {
        const { groupId, latitude, longitude } = payload || {};
        if (!groupId) return;

        const room = `group_${groupId}`;
        groupNsp.to(room).emit('emergency_alert', {
          userId: socket.userId,
          name: socket.userName,
          profileImage: socket.userProfileImage,
          latitude,
          longitude,
          timestamp: Date.now(),
        });
      } catch (err) {
        console.error('emergency_sos', err);
      }
    });

    socket.on('disconnect', async () => {
      try {
        for (const [groupId, liveSessionId] of joinedRooms) {
          const room = `group_${groupId}`;
          const uid = new mongoose.Types.ObjectId(socket.userId);

          await LiveSession.updateOne(
            { _id: liveSessionId, 'memberSessions.userId': uid },
            { $set: { 'memberSessions.$.isOnline': false } }
          );

          socket.to(room).emit('member_left', {
            userId: socket.userId,
            name: socket.userName,
          });
        }
        joinedRooms.clear();
      } catch (err) {
        console.error('group disconnect cleanup', err);
      }
    });
  });

  // ── Track recording (default namespace) ──
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
