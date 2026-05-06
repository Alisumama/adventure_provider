const express = require('express');
const protect = require('../middleware/protect');
const { uploadCommunityImage, uploadCoverImage } = require('../middleware/upload.middleware');
const communityController = require('../controllers/community.controller');

const router = express.Router();

router.get('/', protect, communityController.getAllCommunities);
router.post('/', protect, communityController.createCommunity);

router.post('/posts/:postId/like', protect, communityController.toggleLikePost);
router.delete('/posts/:postId', protect, communityController.deletePost);

router.get('/:communityId/posts', protect, communityController.getCommunityPosts);
router.post('/:communityId/posts', protect, communityController.createPost);

router.get('/:communityId/announcements', protect, communityController.getAnnouncements);
router.get('/:communityId/events', protect, communityController.getCommunityEvents);
router.get('/:communityId/rules', protect, communityController.getCommunityRules);

// Specific /:communityId/... routes before generic `/:communityId` (GET/PUT/DELETE)
router.get('/:communityId/members', protect, communityController.getCommunityMembers);
router.delete('/:communityId/members/:userId', protect, communityController.removeMember);
router.patch(
  '/:communityId/members/:userId/promote',
  protect,
  communityController.promoteMember
);
router.patch(
  '/:communityId/members/:userId/demote',
  protect,
  communityController.demoteModerator
);
router.patch(
  '/:communityId/transfer-admin/:userId',
  protect,
  communityController.transferAdmin
);

router.delete('/:communityId', protect, communityController.deleteCommunity);

router.post('/:communityId/join', protect, communityController.joinCommunity);
router.post('/:communityId/leave', protect, communityController.leaveCommunity);

router.put(
  '/:communityId/image',
  protect,
  uploadCommunityImage.single('image'),
  communityController.updateCommunityImage
);
router.put(
  '/:communityId/cover-image',
  protect,
  uploadCoverImage.single('coverImage'),
  communityController.updateCommunityCoverImage
);

router.put('/:communityId', protect, communityController.updateCommunity);
router.get('/:communityId', protect, communityController.getCommunityDetail);

module.exports = router;
