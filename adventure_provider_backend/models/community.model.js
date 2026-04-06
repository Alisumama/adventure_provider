const mongoose = require('mongoose');

const VISIBILITY = ['public', 'private'];
const CATEGORY = ['hiking', 'offroading', 'both'];
const MEMBER_ROLES = ['admin', 'moderator', 'member'];

const memberSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    role: {
      type: String,
      enum: MEMBER_ROLES,
      default: 'member',
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const communitySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      maxlength: [60, 'Name cannot exceed 60 characters'],
    },
    description: {
      type: String,
      default: '',
      maxlength: [300, 'Description cannot exceed 300 characters'],
    },
    image: {
      type: String,
      default: null,
    },
    coverImage: {
      type: String,
      default: null,
    },
    visibility: {
      type: String,
      enum: {
        values: VISIBILITY,
        message: `Visibility must be one of: ${VISIBILITY.join(', ')}`,
      },
      default: 'public',
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: {
        values: CATEGORY,
        message: `Category must be one of: ${CATEGORY.join(', ')}`,
      },
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Creator is required'],
    },
    members: {
      type: [memberSchema],
      default: [],
    },
    membersCount: {
      type: Number,
      default: 1,
      min: 0,
    },
    totalPosts: {
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

communitySchema.pre('save', function () {
  this.membersCount = this.members.length;
});

const Community = mongoose.model('Community', communitySchema);

module.exports = Community;
