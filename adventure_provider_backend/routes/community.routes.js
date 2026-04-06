const express = require('express');

const protect = require('../middleware/protect');
const communityController = require('../controllers/community.controller');
const { uploadCommunityImage } = require('../middleware/upload.middleware');

const router = express.Router();

// All routes protected
router.use(protect);

router.get('/', communityController.getAllCommunities);
router.post('/', communityController.createCommunity);

router.get('/:communityId', communityController.getCommunityDetail);
router.put('/:communityId', communityController.updateCommunity);

router.post('/:communityId/join', communityController.joinCommunity);
router.post('/:communityId/leave', communityController.leaveCommunity);

router.put(
  '/:communityId/image',
  uploadCommunityImage.single('image'),
  communityController.updateCommunityImage
);

router.get('/:communityId/posts', communityController.getCommunityPosts);
router.post('/:communityId/posts', communityController.createPost);

router.post('/posts/:postId/like', communityController.toggleLikePost);
router.delete('/posts/:postId', communityController.deletePost);

module.exports = router;

