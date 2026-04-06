const mongoose = require('mongoose');

const VISIBILITIES = ['public', 'private'];
const CATEGORIES = ['hiking', 'offroading', 'both'];
const ROLES = ['admin', 'moderator', 'member'];

const memberSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Member user is required'],
    },
    role: {
      type: String,
      enum: {
        values: ROLES,
        message: `Role must be one of: ${ROLES.join(', ')}`,
      },
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
    // Basic Info
    name: {
      type: String,
      required: [true, 'Community name is required'],
      trim: true,
      maxlength: [60, 'Community name cannot exceed 60 characters'],
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
        values: VISIBILITIES,
        message: `Visibility must be one of: ${VISIBILITIES.join(', ')}`,
      },
      default: 'public',
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: {
        values: CATEGORIES,
        message: `Category must be one of: ${CATEGORIES.join(', ')}`,
      },
    },

    // Creator & Members
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
    },

    // Content
    totalPosts: {
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

communitySchema.pre('save', function () {
  this.membersCount = Array.isArray(this.members) ? this.members.length : 0;
});

module.exports = mongoose.model('Community', communitySchema);

