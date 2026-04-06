const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const Community = require('../models/community.model');
const CommunityPost = require('../models/communityPost.model');
const Track = require('../models/track.model');

function escapeRegex(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function memberRole(community, userId) {
  const uid = userId.toString();
  const m = community.members.find((x) => x.user.toString() === uid);
  return m ? m.role : null;
}

function isMember(community, userId) {
  return memberRole(community, userId) != null;
}

function isCommunityAdmin(community, userId) {
  return memberRole(community, userId) === 'admin';
}

function isModeratorOrAdmin(community, userId) {
  const r = memberRole(community, userId);
  return r === 'admin' || r === 'moderator';
}

const MEMBER_ROLE_ORDER = { admin: 0, moderator: 1, member: 2 };

function sortMembersByRole(members) {
  return [...members].sort(
    (a, b) => (MEMBER_ROLE_ORDER[a.role] ?? 99) - (MEMBER_ROLE_ORDER[b.role] ?? 99)
  );
}

/**
 * Deletes a previously stored upload under uploads/<folderKey>/...
 */
async function safeDeleteStoredUpload(stored, folderKey) {
  if (!stored || typeof stored !== 'string') return;
  const prefixRel = `uploads/${folderKey}/`;
  const prefixUrl = `/uploads/${folderKey}/`;
  try {
    let relative;
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      const parsed = new URL(stored);
      const pathname = parsed.pathname || '';
      if (!pathname.startsWith(prefixUrl)) return;
      relative = pathname.replace(/^\//, '');
    } else {
      const s = stored.replace(/^\//, '');
      if (!s.startsWith(prefixRel)) return;
      relative = s;
    }
    const diskPath = path.join(__dirname, '..', relative);
    await fs.promises.unlink(diskPath);
  } catch (err) {
    if (err && err.code === 'ENOENT') return;
  }
}

function canAccessCommunityPosts(community, userId) {
  if (community.visibility === 'public') return true;
  return isMember(community, userId);
}

/**
 * POST /communities
 * Body: name, description, visibility, category
 */
async function createCommunity(req, res) {
  try {
    const { name, description, visibility, category } = req.body;
    if (!name || !category) {
      return res.status(400).json({ message: 'name and category are required' });
    }

    const community = await Community.create({
      name,
      description: description ?? '',
      visibility: visibility ?? 'public',
      category,
      createdBy: req.user._id,
      members: [{ user: req.user._id, role: 'admin' }],
      membersCount: 1,
    });

    await community.populate('createdBy', 'name profileImage');
    return res.status(201).json({
      community,
      isMember: true,
      userRole: 'admin',
    });
  } catch (err) {
    console.error('createCommunity:', err);
    const message = err.message || 'Failed to create community';
    return res.status(500).json({ message });
  }
}

/**
 * GET /communities
 * Query: search, category
 */
async function getAllCommunities(req, res) {
  try {
    const { search, category } = req.query;
    const userId = req.user._id;

    const filter = {
      isActive: true,
      $or: [{ visibility: 'public' }, { members: { $elemMatch: { user: userId } } }],
    };

    if (search && String(search).trim()) {
      filter.name = { $regex: escapeRegex(String(search).trim()), $options: 'i' };
    }
    if (category && String(category).trim()) {
      filter.category = String(category).trim();
    }

    const communities = await Community.find(filter)
      .sort({ membersCount: -1 })
      .populate('createdBy', 'name profileImage')
      .lean();

    const uid = userId.toString();
    const withFlags = communities.map((c) => ({
      ...c,
      isMember: c.members.some((m) => m.user.toString() === uid),
    }));

    return res.status(200).json({
      communities: withFlags,
      count: withFlags.length,
    });
  } catch (err) {
    console.error('getAllCommunities:', err);
    return res.status(500).json({ message: err.message || 'Failed to list communities' });
  }
}

/**
 * GET /communities/:communityId
 */
async function getCommunityDetail(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findOne({
      _id: communityId,
      isActive: true,
    }).populate('createdBy', 'name profileImage');

    if (!community) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const uid = req.user._id;
    const member = memberRole(community, uid);
    const memberBool = member != null;

    if (community.visibility === 'private' && !memberBool) {
      return res.status(403).json({ message: 'This community is private' });
    }

    const communityObj = community.toObject ? community.toObject() : community;
    return res.status(200).json({
      community: communityObj,
      isMember: memberBool,
      userRole: member,
    });
  } catch (err) {
    console.error('getCommunityDetail:', err);
    return res.status(500).json({ message: err.message || 'Failed to load community' });
  }
}

/**
 * POST /communities/:communityId/join
 */
async function joinCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (isMember(community, req.user._id)) {
      return res.status(400).json({ message: 'Already a member' });
    }

    if (community.visibility === 'private') {
      return res.status(403).json({
        message: 'This community is private. Request access from admin.',
      });
    }

    community.members.push({ user: req.user._id, role: 'member' });
    await community.save();

    return res.status(200).json({ message: 'Joined successfully' });
  } catch (err) {
    console.error('joinCommunity:', err);
    return res.status(500).json({ message: err.message || 'Failed to join' });
  }
}

/**
 * POST /communities/:communityId/leave
 */
async function leaveCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const uid = req.user._id;
    if (!isMember(community, uid)) {
      return res.status(400).json({ message: 'You are not a member of this community' });
    }

    const role = memberRole(community, uid);
    const adminCount = community.members.filter((m) => m.role === 'admin').length;
    if (role === 'admin' && adminCount === 1) {
      return res.status(400).json({ message: 'Transfer admin role before leaving' });
    }

    community.members = community.members.filter((m) => !m.user.equals(uid));
    await community.save();

    return res.status(200).json({ message: 'Left community' });
  } catch (err) {
    console.error('leaveCommunity:', err);
    return res.status(500).json({ message: err.message || 'Failed to leave' });
  }
}

/**
 * PUT /community/:communityId
 * Admin: name, description, image, coverImage, visibility, category
 * Moderator: name, description only
 */
async function updateCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const role = memberRole(community, req.user._id);
    if (role !== 'admin' && role !== 'moderator') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const { name, description, image, coverImage, visibility, category } = req.body;

    if (role === 'moderator') {
      const restricted = ['visibility', 'category', 'image', 'coverImage'];
      const attempted = restricted.filter((k) => req.body[k] !== undefined);
      if (attempted.length > 0) {
        return res.status(403).json({
          message: 'Moderators can only update name and description',
        });
      }
      if (name !== undefined) community.name = name;
      if (description !== undefined) community.description = description;
    } else {
      if (name !== undefined) community.name = name;
      if (description !== undefined) community.description = description;
      if (image !== undefined) community.image = image;
      if (coverImage !== undefined) community.coverImage = coverImage;
      if (visibility !== undefined) community.visibility = visibility;
      if (category !== undefined) community.category = category;
    }

    await community.save();
    await community.populate('createdBy', 'name profileImage');

    return res.status(200).json({ community });
  } catch (err) {
    console.error('updateCommunity:', err);
    const message = err.message || 'Failed to update community';
    return res.status(500).json({ message });
  }
}

/**
 * PUT /communities/:communityId/image
 * Multipart field: image
 */
async function updateCommunityImage(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Image file is required' });
    }

    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isCommunityAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Only an admin can update this image' });
    }

    const relativePath = `uploads/communities/${req.file.filename}`;
    await safeDeleteStoredUpload(community.image, 'communities');

    community.image = relativePath;
    await community.save();
    await community.populate('createdBy', 'name profileImage');

    return res.status(200).json({ community });
  } catch (err) {
    console.error('updateCommunityImage:', err);
    return res.status(500).json({ message: err.message || 'Failed to update image' });
  }
}

/**
 * GET /communities/:communityId/posts
 */
async function getCommunityPosts(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 15));
    const skip = (page - 1) * limit;

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!canAccessCommunityPosts(community, req.user._id)) {
      return res.status(403).json({ message: 'You do not have access to these posts' });
    }

    const filter = { community: communityId, isActive: true };

    const [total, postsRaw] = await Promise.all([
      CommunityPost.countDocuments(filter),
      CommunityPost.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('author', 'name profileImage')
        .populate('track', 'title type difficulty distance coverImage')
        .lean(),
    ]);

    const uid = req.user._id.toString();
    const posts = postsRaw.map((p) => {
      const liked = (p.likes || []).some((id) => id.toString() === uid);
      return { ...p, isLiked: liked };
    });

    const totalPages = total === 0 ? 0 : Math.ceil(total / limit);
    const hasMore = totalPages > 0 && page < totalPages;

    return res.status(200).json({
      posts,
      currentPage: page,
      totalPages,
      hasMore,
    });
  } catch (err) {
    console.error('getCommunityPosts:', err);
    return res.status(500).json({ message: err.message || 'Failed to load posts' });
  }
}

/**
 * POST /communities/:communityId/posts
 * Body: content, trackId (optional)
 */
async function createPost(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const { content, trackId } = req.body;
    if (!content || !String(content).trim()) {
      return res.status(400).json({ message: 'content is required' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isMember(community, req.user._id)) {
      return res.status(403).json({ message: 'You must be a member to post' });
    }

    let trackRef = null;
    if (trackId && String(trackId).trim()) {
      if (!mongoose.Types.ObjectId.isValid(trackId)) {
        return res.status(400).json({ message: 'Invalid track id' });
      }
      const track = await Track.findById(trackId);
      if (!track) {
        return res.status(400).json({ message: 'Track not found' });
      }
      trackRef = track._id;
    }

    const post = await CommunityPost.create({
      community: community._id,
      author: req.user._id,
      content: String(content).trim(),
      track: trackRef,
    });

    community.totalPosts = (community.totalPosts || 0) + 1;
    await community.save();

    await post.populate('author', 'name profileImage');
    await post.populate('track', 'title type difficulty distance coverImage');

    const postObj = post.toObject();
    postObj.isLiked = false;

    return res.status(201).json({ post: postObj });
  } catch (err) {
    console.error('createPost:', err);
    const message = err.message || 'Failed to create post';
    return res.status(500).json({ message });
  }
}

/**
 * POST /posts/:postId/like
 */
async function toggleLikePost(req, res) {
  try {
    const { postId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(400).json({ message: 'Invalid post id' });
    }

    const post = await CommunityPost.findById(postId);
    if (!post || !post.isActive) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const community = await Community.findById(post.community);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!canAccessCommunityPosts(community, req.user._id)) {
      return res.status(403).json({ message: 'You cannot like this post' });
    }

    const uid = req.user._id;
    const idx = post.likes.findIndex((id) => id.equals(uid));

    let isLiked;
    if (idx >= 0) {
      post.likes.splice(idx, 1);
      isLiked = false;
    } else {
      post.likes.push(uid);
      isLiked = true;
    }

    await post.save();

    return res.status(200).json({
      isLiked,
      likesCount: post.likesCount,
    });
  } catch (err) {
    console.error('toggleLikePost:', err);
    return res.status(500).json({ message: err.message || 'Failed to toggle like' });
  }
}

/**
 * DELETE /posts/:postId
 */
async function deletePost(req, res) {
  try {
    const { postId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(400).json({ message: 'Invalid post id' });
    }

    const post = await CommunityPost.findById(postId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }
    if (!post.isActive) {
      return res.status(400).json({ message: 'Post already deleted' });
    }

    const community = await Community.findById(post.community);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const uid = req.user._id;
    const isAuthor = post.author.equals(uid);
    const admin = isCommunityAdmin(community, uid);
    if (!isAuthor && !admin) {
      return res.status(403).json({ message: 'Not allowed to delete this post' });
    }

    post.isActive = false;
    await post.save();

    if (community.totalPosts > 0) {
      community.totalPosts -= 1;
    }
    await community.save();

    return res.status(200).json({ message: 'Post deleted' });
  } catch (err) {
    console.error('deletePost:', err);
    return res.status(500).json({ message: err.message || 'Failed to delete post' });
  }
}

/**
 * GET /community/:communityId/members
 */
async function getCommunityMembers(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findOne({
      _id: communityId,
      isActive: true,
    }).populate('members.user', 'name profileImage totalTracks totalAdventures createdAt');

    if (!community) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isModeratorOrAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const members = sortMembersByRole(community.members);

    return res.status(200).json({
      members,
      totalCount: members.length,
    });
  } catch (err) {
    console.error('getCommunityMembers:', err);
    return res.status(500).json({ message: err.message || 'Failed to load members' });
  }
}

/**
 * DELETE /community/:communityId/members/:userId
 */
async function removeMember(req, res) {
  try {
    const { communityId, userId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId) || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isModeratorOrAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (req.user._id.toString() === userId) {
      return res.status(400).json({ message: 'Cannot remove yourself' });
    }

    const targetRole = memberRole(community, userId);
    if (targetRole == null) {
      return res.status(404).json({ message: 'User is not a member of this community' });
    }

    const requesterRole = memberRole(community, req.user._id);
    if (requesterRole === 'moderator' && (targetRole === 'admin' || targetRole === 'moderator')) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (targetRole === 'admin') {
      const adminCount = community.members.filter((m) => m.role === 'admin').length;
      if (adminCount === 1) {
        return res.status(400).json({ message: 'Transfer admin role before removing this admin' });
      }
    }

    community.members = community.members.filter((m) => m.user.toString() !== userId);
    await community.save();

    return res.status(200).json({ message: 'Member removed' });
  } catch (err) {
    console.error('removeMember:', err);
    return res.status(500).json({ message: err.message || 'Failed to remove member' });
  }
}

/**
 * POST /community/:communityId/members/:userId/promote
 */
async function promoteMember(req, res) {
  try {
    const { communityId, userId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId) || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isCommunityAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Only an admin can promote members' });
    }

    const entry = community.members.find((m) => m.user.toString() === userId);
    if (!entry) {
      return res.status(404).json({ message: 'User is not a member of this community' });
    }

    if (entry.role === 'admin') {
      return res.status(400).json({ message: 'Cannot change admin role' });
    }
    if (entry.role === 'moderator') {
      return res.status(400).json({ message: 'Already a moderator' });
    }

    entry.role = 'moderator';
    await community.save();

    return res.status(200).json({ message: 'Promoted to moderator' });
  } catch (err) {
    console.error('promoteMember:', err);
    return res.status(500).json({ message: err.message || 'Failed to promote member' });
  }
}

/**
 * POST /community/:communityId/members/:userId/demote
 */
async function demoteModerator(req, res) {
  try {
    const { communityId, userId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId) || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isCommunityAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Only an admin can demote moderators' });
    }

    const entry = community.members.find((m) => m.user.toString() === userId);
    if (!entry) {
      return res.status(404).json({ message: 'User is not a member of this community' });
    }

    if (entry.role !== 'moderator') {
      return res.status(400).json({ message: 'User is not a moderator' });
    }

    entry.role = 'member';
    await community.save();

    return res.status(200).json({ message: 'Demoted to member' });
  } catch (err) {
    console.error('demoteModerator:', err);
    return res.status(500).json({ message: err.message || 'Failed to demote moderator' });
  }
}

/**
 * POST /community/:communityId/members/:userId/transfer-admin
 */
async function transferAdmin(req, res) {
  try {
    const { communityId, userId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId) || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: 'Invalid id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isCommunityAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Only the current admin can transfer admin role' });
    }

    if (userId === req.user._id.toString()) {
      return res.status(400).json({ message: 'Choose another member to be the new admin' });
    }

    const target = community.members.find((m) => m.user.toString() === userId);
    if (!target) {
      return res.status(404).json({ message: 'User is not a member' });
    }

    const current = community.members.find((m) => m.user.equals(req.user._id));
    if (!current || current.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    current.role = 'member';
    target.role = 'admin';

    await community.save();

    return res.status(200).json({ message: 'Admin role transferred successfully' });
  } catch (err) {
    console.error('transferAdmin:', err);
    return res.status(500).json({ message: err.message || 'Failed to transfer admin' });
  }
}

/**
 * DELETE /community/:communityId
 */
async function deleteCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(communityId)) {
      return res.status(400).json({ message: 'Invalid community id' });
    }

    const community = await Community.findById(communityId);
    if (!community || !community.isActive) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isCommunityAdmin(community, req.user._id)) {
      return res.status(403).json({ message: 'Only an admin can delete this community' });
    }

    community.isActive = false;
    await community.save();

    await CommunityPost.updateMany(
      { community: communityId },
      { $set: { isActive: false } }
    );

    return res.status(200).json({ message: 'Community deleted' });
  } catch (err) {
    console.error('deleteCommunity:', err);
    return res.status(500).json({ message: err.message || 'Failed to delete community' });
  }
}

module.exports = {
  createCommunity,
  getAllCommunities,
  getCommunityDetail,
  joinCommunity,
  leaveCommunity,
  updateCommunity,
  updateCommunityImage,
  getCommunityPosts,
  createPost,
  toggleLikePost,
  deletePost,
  getCommunityMembers,
  removeMember,
  promoteMember,
  demoteModerator,
  transferAdmin,
  deleteCommunity,
};
