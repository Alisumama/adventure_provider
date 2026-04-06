const mongoose = require('mongoose');

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
      maxlength: [500, 'Content cannot exceed 500 characters'],
    },
    images: {
      type: [{ type: String }],
      default: [],
      validate: {
        validator(v) {
          return Array.isArray(v) && v.length <= 4;
        },
        message: 'A post can have up to 4 images',
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
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

communityPostSchema.pre('save', function () {
  this.likesCount = Array.isArray(this.likes) ? this.likes.length : 0;
});

module.exports = mongoose.model('CommunityPost', communityPostSchema);

