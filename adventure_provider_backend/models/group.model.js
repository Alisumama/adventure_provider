const mongoose = require('mongoose');
const crypto = require('crypto');

const memberSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    role: {
      type: String,
      enum: ['admin', 'member'],
      default: 'member',
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const groupSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      maxlength: 50,
    },
    description: {
      type: String,
      maxlength: 200,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    members: [memberSchema],
    inviteCode: {
      type: String,
      unique: true,
    },
    isTrackingActive: {
      type: Boolean,
      default: false,
    },
    trackingStartedAt: {
      type: Date,
    },
    maxMembers: {
      type: Number,
      default: 10,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    coverImage: {
      type: String,
    },
  },
  { timestamps: true }
);

groupSchema.pre('save', function () {
  if (!this.inviteCode) {
    this.inviteCode = crypto
      .randomBytes(4)
      .toString('hex')
      .slice(0, 6)
      .toUpperCase();
  }
});

module.exports = mongoose.model('Group', groupSchema);
