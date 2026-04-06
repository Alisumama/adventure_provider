const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

const Community = require('../models/community.model');
const CommunityPost = require('../models/communityPost.model');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

function asStringId(v) {
  if (!v) return '';
  return typeof v === 'string' ? v : v.toString();
}

function getMemberRole(community, userId) {
  const uid = asStringId(userId);
  const m = (community?.members ?? []).find((x) => asStringId(x.user) === uid);
  return m?.role ?? null;
}

function isMember(community, userId) {
  return getMemberRole(community, userId) != null;
}

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

// ── CREATE COMMUNITY ──────────────────────────────────
async function createCommunity(req, res) {
  try {
    const { name, description, visibility, category } = req.body;
    const community = await Community.create({
      name,
      description,
      visibility,
      category,
      createdBy: req.user._id,
      members: [{ user: req.user._id, role: 'admin' }],
      membersCount: 1,
    });
    return res.status(201).json(community);
  } catch (err) {
    console.error('createCommunity error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to create community' });
  }
}

// ── GET ALL COMMUNITIES ───────────────────────────────
async function getAllCommunities(req, res) {
  try {
    const userId = req.user?._id;
    const search = (req.query.search ?? '').toString().trim();
    const category = (req.query.category ?? '').toString().trim();

    const query = {
      isActive: true,
      $or: [{ visibility: 'public' }, { 'members.user': userId }],
    };

    if (search) {
      query.name = { $regex: search, $options: 'i' };
    }
    if (category) {
      query.category = category;
    }

    const communities = await Community.find(query)
      .sort({ membersCount: -1 })
      .populate('createdBy', 'name profileImage')
      .lean();

    const uid = asStringId(userId);
    const mapped = communities.map((c) => ({
      ...c,
      isMember: (c.members ?? []).some((m) => asStringId(m.user) === uid),
    }));

    return res.status(200).json({ communities: mapped, count: mapped.length });
  } catch (err) {
    console.error('getAllCommunities error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch communities' });
  }
}

// ── GET COMMUNITY DETAIL ──────────────────────────────
async function getCommunityDetail(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const community = await Community.findById(communityId)
      .populate('createdBy', 'name profileImage')
      .lean();
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const role = getMemberRole(community, req.user._id);
    return res.status(200).json({
      community,
      isMember: role != null,
      userRole: role,
    });
  } catch (err) {
    console.error('getCommunityDetail error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch community' });
  }
}

// ── JOIN COMMUNITY ────────────────────────────────────
async function joinCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const community = await Community.findById(communityId);
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const already = community.members.some((m) => asStringId(m.user) === asStringId(req.user._id));
    if (already) return res.status(400).json({ message: 'Already a member' });

    if (community.visibility === 'private') {
      return res.status(403).json({
        message: 'This community is private. Request access from admin.',
      });
    }

    community.members.push({ user: req.user._id, role: 'member' });
    community.membersCount = (community.membersCount ?? 0) + 1;
    await community.save();

    return res.status(200).json({ message: 'Joined successfully' });
  } catch (err) {
    console.error('joinCommunity error:', err);
    return res.status(500).json({ message: err.message || 'Failed to join community' });
  }
}

// ── LEAVE COMMUNITY ───────────────────────────────────
async function leaveCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const community = await Community.findById(communityId);
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const uid = asStringId(req.user._id);
    const role = getMemberRole(community, req.user._id);
    if (!role) return res.status(400).json({ message: 'Not a member' });

    const admins = community.members.filter((m) => m.role === 'admin');
    if (role === 'admin' && admins.length === 1) {
      return res.status(400).json({ message: 'Transfer admin role before leaving' });
    }

    community.members = community.members.filter((m) => asStringId(m.user) !== uid);
    community.membersCount = Math.max(0, (community.membersCount ?? community.members.length) - 1);
    await community.save();

    return res.status(200).json({ message: 'Left community' });
  } catch (err) {
    console.error('leaveCommunity error:', err);
    return res.status(500).json({ message: err.message || 'Failed to leave community' });
  }
}

// ── UPDATE COMMUNITY ──────────────────────────────────
async function updateCommunity(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const community = await Community.findById(communityId);
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const role = getMemberRole(community, req.user._id);
    if (role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can update this community' });
    }

    const { name, description, visibility, category } = req.body;
    if (name !== undefined) community.name = name;
    if (description !== undefined) community.description = description;
    if (visibility !== undefined) community.visibility = visibility;
    if (category !== undefined) community.category = category;

    await community.save();
    const populated = await Community.findById(community._id).populate('createdBy', 'name profileImage');
    return res.status(200).json(populated);
  } catch (err) {
    console.error('updateCommunity error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to update community' });
  }
}

// ── UPDATE COMMUNITY IMAGE ────────────────────────────
async function updateCommunityImage(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Image file is required' });
    }

    const community = await Community.findById(communityId);
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const role = getMemberRole(community, req.user._id);
    if (role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can update this community' });
    }

    const relativePath = `uploads/communities/${req.file.filename}`;
    await safeDeleteStoredUpload(community.image, 'communities');
    community.image = relativePath;
    await community.save();

    return res.status(200).json(community);
  } catch (err) {
    console.error('updateCommunityImage error:', err);
    return res.status(500).json({ message: err.message || 'Failed to update community image' });
  }
}

// ── GET COMMUNITY POSTS ───────────────────────────────
async function getCommunityPosts(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 15));
    const skip = (page - 1) * limit;

    const community = await Community.findById(communityId).lean();
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    const member = isMember(community, req.user._id);
    if (!member && community.visibility !== 'public') {
      return res.status(403).json({ message: 'Not allowed' });
    }

    const filter = { community: communityId, isActive: true };
    const total = await CommunityPost.countDocuments(filter);
    const totalPages = Math.max(1, Math.ceil(total / limit));

    const posts = await CommunityPost.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('author', 'name profileImage')
      .populate('track', 'title type difficulty distance coverImage')
      .lean();

    const uid = asStringId(req.user._id);
    const mapped = posts.map((p) => ({
      ...p,
      isLiked: (p.likes ?? []).some((x) => asStringId(x) === uid),
    }));

    return res.status(200).json({
      posts: mapped,
      currentPage: page,
      totalPages,
    });
  } catch (err) {
    console.error('getCommunityPosts error:', err);
    return res.status(500).json({ message: err.message || 'Failed to fetch posts' });
  }
}

// ── CREATE POST ───────────────────────────────────────
async function createPost(req, res) {
  try {
    const { communityId } = req.params;
    if (!isValidObjectId(communityId)) {
      return res.status(400).json({ message: 'Invalid communityId' });
    }

    const { content, trackId } = req.body;
    if (!content || typeof content !== 'string' || content.trim().isEmpty) {
      return res.status(400).json({ message: 'content is required' });
    }

    const community = await Community.findById(communityId);
    if (!community || community.isActive === false) {
      return res.status(404).json({ message: 'Community not found' });
    }

    if (!isMember(community, req.user._id)) {
      return res.status(403).json({ message: 'Only members can post' });
    }

    const post = await CommunityPost.create({
      community: communityId,
      author: req.user._id,
      content: content.trim(),
      track: isValidObjectId(trackId) ? trackId : null,
      images: [],
    });

    community.totalPosts = (community.totalPosts ?? 0) + 1;
    await community.save();

    return res.status(201).json(post);
  } catch (err) {
    console.error('createPost error:', err);
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    return res.status(500).json({ message: err.message || 'Failed to create post' });
  }
}

// ── TOGGLE LIKE POST ──────────────────────────────────
async function toggleLikePost(req, res) {
  try {
    const { postId } = req.params;
    if (!isValidObjectId(postId)) {
      return res.status(400).json({ message: 'Invalid postId' });
    }

    const post = await CommunityPost.findById(postId);
    if (!post || post.isActive === false) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const uid = asStringId(req.user._id);
    const liked = post.likes.some((x) => asStringId(x) === uid);

    if (liked) {
      post.likes = post.likes.filter((x) => asStringId(x) !== uid);
    } else {
      post.likes.push(req.user._id);
    }
    post.likesCount = post.likes.length;
    await post.save();

    return res.status(200).json({ isLiked: !liked, likesCount: post.likesCount });
  } catch (err) {
    console.error('toggleLikePost error:', err);
    return res.status(500).json({ message: err.message || 'Failed to toggle like' });
  }
}

// ── DELETE POST ───────────────────────────────────────
async function deletePost(req, res) {
  try {
    const { postId } = req.params;
    if (!isValidObjectId(postId)) {
      return res.status(400).json({ message: 'Invalid postId' });
    }

    const post = await CommunityPost.findById(postId);
    if (!post || post.isActive === false) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const isAuthor = asStringId(post.author) === asStringId(req.user._id);
    let isAdmin = false;
    if (!isAuthor) {
      const community = await Community.findById(post.community).lean();
      const role = getMemberRole(community, req.user._id);
      isAdmin = role === 'admin';
    }

    if (!isAuthor && !isAdmin) {
      return res.status(403).json({ message: 'Not allowed' });
    }

    post.isActive = false;
    await post.save();

    await Community.updateOne(
      { _id: post.community },
      { $inc: { totalPosts: -1 } }
    );

    return res.status(200).json({ message: 'Deleted' });
  } catch (err) {
    console.error('deletePost error:', err);
    return res.status(500).json({ message: err.message || 'Failed to delete post' });
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
};

