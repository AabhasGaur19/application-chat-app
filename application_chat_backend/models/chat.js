// // application_chat_backend/models/chat.js
// const mongoose = require('mongoose');

// const chatSchema = new mongoose.Schema({
//   participants: [{ type: String, required: true }], // Store user UIDs
//   lastMessage: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
//   updatedAt: { type: Date, default: Date.now },
// });

// module.exports = mongoose.model('Chat', chatSchema);


const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  type: { type: String, enum: ['direct', 'group'], default: 'direct' },
  participants: [{ type: String, required: true }], // Store user UIDs
  groupName: { type: String }, // Name for group chats
  groupAdmin: { type: String }, // UID of group admin
  groupMembers: [{ type: String }], // UIDs of group members
  lastMessage: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Chat', chatSchema);