const mongoose = require('mongoose');
const Group = require('../models/group.model');
const LiveSession = require('../models/live_session.model');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

/**
 * POST /api/groups — create a new group.
 * Body: { name, description }
 */
async function createGroup(req, res) {
  try {
    const { name, description } = req.body;

    const group = new Group({
      name,
      description,
      createdBy: req.user._id,
      members: [
        {
          userId: req.user._id,
          role: 'admin',
          joinedAt: new Date(),
        },
      ],
    });

    await group.save();

    return res.status(201).json(group);
  } catch (err) {
    console.error('createGroup error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/groups/join — join a group via invite code.
 * Body: { inviteCode }
 */
async function joinGroup(req, res) {
  try {
    const { inviteCode } = req.body;

    if (!inviteCode) {
      return res.status(400).json({ message: 'inviteCode is required' });
    }

    const group = await Group.findOne({ inviteCode, isActive: true });
    if (!group) {
      return res.status(404).json({ message: 'Invalid invite code' });
    }

    const existingMember = group.members.find(
      (m) => m.userId.equals(req.user._id) && m.isActive
    );
    if (existingMember) {
      return res.status(200).json(group);
    }

    const activeMembers = group.members.filter((m) => m.isActive);
    if (activeMembers.length >= group.maxMembers) {
      return res.status(400).json({ message: 'Group is full' });
    }

    group.members.push({
      userId: req.user._id,
      role: 'member',
      joinedAt: new Date(),
    });

    await group.save();

    return res.status(200).json(group);
  } catch (err) {
    console.error('joinGroup error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/groups/my — get all groups the user belongs to.
 */
async function getMyGroups(req, res) {
  try {
    const groups = await Group.find({
      'members.userId': req.user._id,
      'members.isActive': true,
      isActive: true,
    })
      .populate('members.userId', 'name profileImage')
      .lean();

    return res.status(200).json(groups);
  } catch (err) {
    console.error('getMyGroups error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/groups/:id — get a single group by ID with populated members.
 */
async function getGroupById(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid group ID' });
    }

    const group = await Group.findById(id)
      .populate('members.userId', 'name profileImage')
      .populate('createdBy', 'name profileImage');

    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    return res.status(200).json(group);
  } catch (err) {
    console.error('getGroupById error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/groups/:id/live-sessions — list all live sessions for this group (member only).
 */
async function getGroupLiveSessions(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid group ID' });
    }

    const group = await Group.findById(id);
    if (!group || !group.isActive) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const member = group.members.find(
      (m) => m.userId.equals(req.user._id) && m.isActive
    );
    if (!member) {
      return res.status(403).json({ message: 'Only group members can view sessions' });
    }

    const sessions = await LiveSession.find({ groupId: group._id })
      .populate('startedBy', 'name profileImage')
      .populate('memberSessions.userId', 'name profileImage')
      .sort({ startedAt: -1 })
      .lean();

    return res.status(200).json(sessions);
  } catch (err) {
    console.error('getGroupLiveSessions error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/groups/:id/start-tracking — start live tracking for a group (admin only).
 */
async function startGroupTracking(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid group ID' });
    }

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const member = group.members.find(
      (m) => m.userId.equals(req.user._id) && m.isActive
    );
    if (!member || member.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can start tracking' });
    }

    const { trackId } = req.body;

    group.isTrackingActive = true;
    group.trackingStartedAt = new Date();
    await group.save();

    const sessionData = {
      groupId: group._id,
      startedBy: req.user._id,
    };
    if (trackId && isValidObjectId(trackId)) {
      sessionData.trackId = trackId;
    }

    const liveSession = new LiveSession(sessionData);
    await liveSession.save();

    return res.status(200).json({
      group,
      liveSessionId: liveSession._id,
    });
  } catch (err) {
    console.error('startGroupTracking error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/groups/:id/stop-tracking — stop live tracking for a group (admin only).
 */
async function stopGroupTracking(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid group ID' });
    }

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const member = group.members.find(
      (m) => m.userId.equals(req.user._id) && m.isActive
    );
    if (!member || member.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can stop tracking' });
    }

    group.isTrackingActive = false;
    await group.save();

    await LiveSession.updateOne(
      { groupId: group._id, isActive: true },
      { isActive: false, endedAt: new Date() }
    );

    return res.status(200).json({ message: 'Tracking stopped successfully' });
  } catch (err) {
    console.error('stopGroupTracking error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * DELETE /api/groups/:id/leave — leave a group.
 */
async function leaveGroup(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid group ID' });
    }

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const member = group.members.find(
      (m) => m.userId.equals(req.user._id) && m.isActive
    );
    if (!member) {
      return res.status(404).json({ message: 'You are not a member of this group' });
    }

    member.isActive = false;
    await group.save();

    return res.status(200).json({ message: 'Left group successfully' });
  } catch (err) {
    console.error('leaveGroup error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/groups/:id/location — update member location in a live session.
 * Body: { liveSessionId, latitude, longitude }
 */
async function updateMemberLocation(req, res) {
  try {
    const { id } = req.params;
    const { liveSessionId, latitude, longitude } = req.body;

    if (!isValidObjectId(id) || !isValidObjectId(liveSessionId)) {
      return res.status(400).json({ message: 'Invalid ID' });
    }

    if (latitude == null || longitude == null) {
      return res.status(400).json({ message: 'latitude and longitude are required' });
    }

    const liveSession = await LiveSession.findOne({
      _id: liveSessionId,
      groupId: id,
      isActive: true,
    });

    if (!liveSession) {
      return res.status(404).json({ message: 'Live session not found' });
    }

    let memberSession = liveSession.memberSessions.find(
      (ms) => ms.userId && ms.userId.equals(req.user._id)
    );

    if (!memberSession) {
      liveSession.memberSessions.push({
        userId: req.user._id,
        joinedAt: new Date(),
        isOnline: true,
        lastLocation: {
          type: 'Point',
          coordinates: [longitude, latitude],
        },
        lastSeenAt: new Date(),
        locationPath: [[longitude, latitude]],
      });
    } else {
      memberSession.lastLocation = {
        type: 'Point',
        coordinates: [longitude, latitude],
      };
      memberSession.lastSeenAt = new Date();
      memberSession.isOnline = true;
      memberSession.locationPath.push([longitude, latitude]);
    }

    await liveSession.save();

    return res.status(200).json({ message: 'Location updated successfully' });
  } catch (err) {
    console.error('updateMemberLocation error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = {
  createGroup,
  joinGroup,
  getMyGroups,
  getGroupById,
  getGroupLiveSessions,
  startGroupTracking,
  stopGroupTracking,
  leaveGroup,
  updateMemberLocation,
};
