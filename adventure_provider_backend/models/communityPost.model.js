const mongoose = require('mongoose');

const MAX_IMAGES = 4;
const MAX_CONTENT = 500;

const communityPostSchema = new mongoose.Schema(
  {
    community: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Community',
      required: [true, 'Community is required'],
    },
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Author is required'],
    },
    content: {
      type: String,
      required: [true, 'Content is required'],
      trim: true,
      maxlength: [MAX_CONTENT, `Content cannot exceed ${MAX_CONTENT} characters`],
    },
    images: {
      type: [String],
      default: [],
      validate: {
        validator: function (v) {
          return Array.isArray(v) && v.length <= MAX_IMAGES;
        },
        message: `At most ${MAX_IMAGES} images allowed`,
      },
    },
    track: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Track',
      default: null,
    },
    likes: {
      type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
      default: [],
    },
    likesCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

communityPostSchema.pre('save', function () {
  this.likesCount = this.likes.length;
});

const CommunityPost = mongoose.model('CommunityPost', communityPostSchema);

module.exports = CommunityPost;
