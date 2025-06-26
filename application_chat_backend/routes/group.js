const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/firebaseAuth");
const Chat = require("../models/chat");
const User = require("../models/user");

// Helper function to get IST timestamp
const getISTDate = () => {
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000;
  return new Date(now.getTime() + istOffset);
};

// Socket.io event handlers for groups
router.handleSocket = (io, socket) => {
  const userId = socket.user.uid;

  socket.on("join:group", async ({ groupId }) => {
    const chat = await Chat.findById(groupId);
    if (chat && chat.type === 'group' && chat.groupMembers.includes(userId)) {
      socket.join(groupId);
      console.log(`${userId} joined group ${groupId}`);

      // Mark all unread messages as read
      try {
        await Message.updateMany(
          {
            chatId: groupId,
            senderId: { $ne: userId },
            status: { $in: ["sent", "delivered"] },
          },
          { status: "read" }
        );
        io.to(userId).emit("unread:count", { chatId: groupId, count: 0 });
      } catch (error) {
        console.error("Error marking group messages as read:", error);
      }
    }
  });

  socket.on("typing:group", ({ groupId, isTyping }) => {
    const chat = Chat.findById(groupId);
    if (chat && chat.type === 'group') {
      socket.to(groupId).emit("typing:group", { userId, isTyping });
    }
  });
};

// Create group
router.post("/", verifyToken, async (req, res) => {
  try {
    const { groupName, memberIds } = req.body;
    if (!groupName || !memberIds || !Array.isArray(memberIds) || memberIds.length < 1) {
      return res.status(400).json({ error: "Group name and at least one member are required" });
    }
    const members = [...new Set([req.user.uid, ...memberIds])]; // Include creator
    const users = await User.find({ uid: { $in: members } }, "uid displayName photoUrl");
    if (users.length !== members.length) {
      return res.status(404).json({ error: "Some members not found" });
    }
    const chat = new Chat({
      type: 'group',
      groupName,
      groupAdmin: req.user.uid,
      groupMembers: members,
      participants: members,
      updatedAt: getISTDate(),
    });
    await chat.save();
    const chatData = {
      _id: chat._id,
      type: 'group',
      groupName: chat.groupName,
      groupAdmin: chat.groupAdmin,
      groupMembers: users,
      participants: users,
      lastMessage: null,
      updatedAt: chat.updatedAt,
      unreadCount: 0,
    };

    if (req.io) {
      members.forEach(uid => req.io.to(uid).emit("chat:new", chatData));
    }

    res.status(201).json(chatData);
  } catch (error) {
    console.error("Group creation error:", error);
    res.status(500).json({ error: "Failed to create group", details: error.message });
  }
});

// Add members
router.put("/:groupId/members/add", verifyToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { memberIds } = req.body;
    const chat = await Chat.findById(groupId);
    if (!chat || chat.type !== 'group') {
      return res.status(404).json({ error: "Group not found" });
    }
    if (chat.groupAdmin !== req.user.uid) {
      return res.status(403).json({ error: "Only admin can add members" });
    }
    const users = await User.find({ uid: { $in: memberIds } }, "uid displayName photoUrl");
    if (users.length !== memberIds.length) {
      return res.status(404).json({ error: "Some members not found" });
    }
    const newMembers = memberIds.filter(uid => !chat.groupMembers.includes(uid));
    if (newMembers.length === 0) {
      return res.status(400).json({ error: "All users are already members" });
    }
    chat.groupMembers.push(...newMembers);
    chat.participants.push(...newMembers);
    chat.updatedAt = getISTDate();
    await chat.save();
    const chatData = {
      _id: chat._id,
      type: 'group',
      groupName: chat.groupName,
      groupAdmin: chat.groupAdmin,
      groupMembers: await User.find({ uid: { $in: chat.groupMembers } }, "uid displayName photoUrl"),
      participants: await User.find({ uid: { $in: chat.participants } }, "uid displayName photoUrl"),
      lastMessage: chat.lastMessage,
      updatedAt: chat.updatedAt,
      unreadCount: 0,
    };

    if (req.io) {
      chat.groupMembers.forEach(uid => req.io.to(uid).emit("group:updated", chatData));
    }

    res.status(200).json(chatData);
  } catch (error) {
    console.error("Error adding members:", error);
    res.status(500).json({ error: "Failed to add members", details: error.message });
  }
});

// Remove members
router.put("/:groupId/members/remove", verifyToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const { memberId } = req.body;
    const chat = await Chat.findById(groupId);
    if (!chat || chat.type !== 'group') {
      return res.status(404).json({ error: "Group not found" });
    }
    if (chat.groupAdmin !== req.user.uid) {
      return res.status(403).json({ error: "Only admin can remove members" });
    }
    if (!chat.groupMembers.includes(memberId)) {
      return res.status(400).json({ error: "User is not a member" });
    }
    chat.groupMembers = chat.groupMembers.filter(uid => uid !== memberId);
    chat.participants = chat.participants.filter(uid => uid !== memberId);
    chat.updatedAt = getISTDate();
    await chat.save();
    const chatData = {
      _id: chat._id,
      type: 'group',
      groupName: chat.groupName,
      groupAdmin: chat.groupAdmin,
      groupMembers: await User.find({ uid: { $in: chat.groupMembers } }, "uid displayName photoUrl"),
      participants: await User.find({ uid: { $in: chat.participants } }, "uid displayName photoUrl"),
      lastMessage: chat.lastMessage,
      updatedAt: chat.updatedAt,
      unreadCount: 0,
    };

    if (req.io) {
      chat.groupMembers.forEach(uid => req.io.to(uid).emit("group:updated", chatData));
      req.io.to(memberId).emit("group:removed", { groupId });
    }

    res.status(200).json(chatData);
  } catch (error) {
    console.error("Error removing member:", error);
    res.status(500).json({ error: "Failed to remove member", details: error.message });
  }
});

// Delete group
router.delete("/:groupId", verifyToken, async (req, res) => {
  try {
    const { groupId } = req.params;
    const chat = await Chat.findById(groupId);
    if (!chat || chat.type !== 'group') {
      return res.status(404).json({ error: "Group not found" });
    }
    if (chat.groupAdmin !== req.user.uid) {
      return res.status(403).json({ error: "Only admin can delete group" });
    }
    await Chat.findByIdAndDelete(groupId);
    if (req.io) {
      chat.groupMembers.forEach(uid => req.io.to(uid).emit("group:deleted", { groupId }));
    }
    res.status(200).json({ message: "Group deleted successfully" });
  } catch (error) {
    console.error("Error deleting group:", error);
    res.status(500).json({ error: "Failed to delete group", details: error.message });
  }
});

module.exports = router;