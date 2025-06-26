// // application_chat_backend/routes/chat.js
// const express = require("express");
// const router = express.Router();
// const verifyToken = require("../middleware/firebaseAuth");
// const Chat = require("../models/chat");
// const Message = require("../models/message");
// const User = require("../models/user");

// // Helper function to get IST timestamp
// const getISTDate = () => {
//   const now = new Date();
//   const istOffset = 5.5 * 60 * 60 * 1000; // IST is UTC+5:30
//   return new Date(now.getTime() + istOffset);
// };

// // Socket.io event handlers
// router.handleSocket = (io, socket) => {
//   const userId = socket.user.uid;

//   socket.on("join:chat", async ({ chatId }) => {
//     socket.join(chatId);
//     console.log(`${userId} joined chat ${chatId}`);

//     // Mark all unread messages in this chat as read for this user
//     try {
//       await Message.updateMany(
//         {
//           chatId,
//           senderId: { $ne: userId },
//           status: { $in: ["sent", "delivered"] },
//         },
//         { status: "read" }
//       );

//       // Emit updated unread count (should be 0 now)
//       io.to(userId).emit("unread:count", { chatId, count: 0 });
//     } catch (error) {
//       console.error("Error marking messages as read:", error);
//     }
//   });

//   // Typing indicator
//   socket.on("typing", ({ chatId, isTyping }) => {
//     socket.to(chatId).emit("typing", { userId, isTyping });
//   });

//   // Mark message as delivered
//   socket.on("message:delivered", async ({ messageId, chatId }) => {
//     try {
//       const message = await Message.findByIdAndUpdate(
//         messageId,
//         { status: "delivered" },
//         { new: true }
//       );
//       if (message) {
//         io.to(chatId).emit("message:status", {
//           messageId,
//           status: "delivered",
//         });
//       }
//     } catch (error) {
//       console.error("Error updating message status:", error);
//     }
//   });

//   // Mark message as read - Updated handler
//   socket.on("message:read", async ({ messageId, chatId }) => {
//     try {
//       const message = await Message.findByIdAndUpdate(
//         messageId,
//         { status: "read" },
//         { new: true }
//       );
//       if (message) {
//         io.to(chatId).emit("message:status", {
//           messageId,
//           status: "read",
//         });

//         // Get the chat to find participants
//         const chat = await Chat.findById(chatId);
//         if (chat) {
//           // Update unread count for all participants
//           for (const participantId of chat.participants) {
//             const unreadCount = await Message.countDocuments({
//               chatId,
//               status: { $in: ["sent", "delivered"] },
//               senderId: { $ne: participantId },
//             });
//             io.to(participantId).emit("unread:count", {
//               chatId,
//               count: unreadCount,
//             });
//           }
//         }
//       }
//     } catch (error) {
//       console.error("Error updating message status:", error);
//     }
//   });

//   // Update last seen
//   socket.on("last:seen", async () => {
//     try {
//       await User.findOneAndUpdate({ uid: userId }, { lastSeen: getISTDate() });
//       io.emit("user:lastSeen", { uid: userId, lastSeen: getISTDate() });
//     } catch (error) {
//       console.error("Error updating last seen:", error);
//     }
//   });
//   // Handle user room joining for notifications
//   socket.on("join:user", ({ userId }) => {
//     socket.join(userId);
//     console.log(`User ${userId} joined their notification room`);
//   });
// };

// router.post("/", verifyToken, async (req, res) => {
//   try {
//     const { participantId } = req.body;
//     if (!participantId) {
//       return res.status(400).json({ error: "Participant ID is required" });
//     }
//     const participant = await User.findOne(
//       { uid: participantId },
//       "uid displayName photoUrl"
//     );
//     if (!participant) {
//       return res.status(404).json({ error: "Participant not found" });
//     }
//     const participants = [req.user.uid, participantId].sort();
//     let chat = await Chat.findOne({ participants });
//     if (chat) {
//       const populatedChat = await Chat.findById(chat._id).populate({
//         path: "lastMessage",
//         select: "content createdAt",
//       });
//       return res.status(200).json({
//         _id: populatedChat._id,
//         participants: [
//           {
//             uid: req.user.uid,
//             displayName: req.user.name,
//             photoUrl: req.user.picture,
//           },
//           {
//             uid: participant.uid,
//             displayName: participant.displayName,
//             photoUrl: participant.photoUrl,
//           },
//         ],
//         lastMessage: populatedChat.lastMessage,
//         updatedAt: populatedChat.updatedAt,
//         unreadCount: await Message.countDocuments({
//           chatId: chat._id,
//           status: { $in: ["sent", "delivered"] },
//           senderId: { $ne: req.user.uid },
//         }),
//       });
//     }
//     chat = new Chat({ participants, updatedAt: getISTDate() });
//     await chat.save();
//     const chatData = {
//       _id: chat._id,
//       participants: [
//         {
//           uid: req.user.uid,
//           displayName: req.user.name,
//           photoUrl: req.user.picture,
//         },
//         {
//           uid: participant.uid,
//           displayName: participant.displayName,
//           photoUrl: participant.photoUrl,
//         },
//       ],
//       lastMessage: null,
//       updatedAt: chat.updatedAt,
//       unreadCount: 0,
//     };

//     // Emit new chat to both participants
//     if (req.io) {
//       req.io.to(req.user.uid).emit("chat:new", chatData);
//       req.io.to(participantId).emit("chat:new", chatData);
//     }

//     res.status(201).json(chatData);
//   } catch (error) {
//     console.error("Chat creation error:", error);
//     res
//       .status(500)
//       .json({ error: "Failed to start chat", details: error.message });
//   }
// });

// router.get("/", verifyToken, async (req, res) => {
//   try {
//     const chats = await Chat.find({ participants: req.user.uid })
//       .populate({
//         path: "lastMessage",
//         select: "content createdAt",
//       })
//       .sort({ updatedAt: -1 });
//     const populatedChats = await Promise.all(
//       chats.map(async (chat) => {
//         const participants = await User.find(
//           { uid: { $in: chat.participants } },
//           "uid displayName photoUrl"
//         );
//         const unreadCount = await Message.countDocuments({
//           chatId: chat._id,
//           status: { $in: ["sent", "delivered"] },
//           senderId: { $ne: req.user.uid },
//         });
//         return {
//           _id: chat._id,
//           participants,
//           lastMessage: chat.lastMessage,
//           updatedAt: chat.updatedAt,
//           unreadCount,
//         };
//       })
//     );
//     res.status(200).json(populatedChats);
//   } catch (error) {
//     console.error("Error fetching chats:", error);
//     res
//       .status(500)
//       .json({ error: "Failed to fetch chats", details: error.message });
//   }
// });

// router.post("/:chatId/messages", verifyToken, async (req, res) => {
//   try {
//     const { chatId } = req.params;
//     const { content } = req.body;
//     if (!content) {
//       return res.status(400).json({ error: "Message content is required" });
//     }
//     const chat = await Chat.findById(chatId);
//     if (!chat || !chat.participants.includes(req.user.uid)) {
//       return res.status(403).json({ error: "Invalid chat or unauthorized" });
//     }
//     const message = new Message({
//       chatId,
//       senderId: req.user.uid,
//       content,
//       createdAt: getISTDate(),
//       status: "sent",
//     });
//     await message.save();
//     chat.lastMessage = message._id;
//     chat.updatedAt = getISTDate();
//     await chat.save();
//     const sender = await User.findOne(
//       { uid: message.senderId },
//       "uid displayName photoUrl"
//     );
//     const messageData = {
//       _id: message._id,
//       chatId: message.chatId,
//       senderId: {
//         uid: sender.uid,
//         displayName: sender.displayName,
//         photoUrl: sender.photoUrl,
//       },
//       content: message.content,
//       status: message.status,
//       createdAt: message.createdAt,
//     };
//     if (req.io) {
//       // Emit to the chat room
//       req.io.to(chatId).emit("message:new", messageData);

//       // Also emit to each participant's personal room for better delivery
//       for (const participantId of chat.participants) {
//         req.io.to(participantId).emit("message:new", messageData);
//       }

//       // NEW: Also broadcast chat list update to show latest message
//       const updatedChatData = {
//         chatId: chatId,
//         lastMessage: messageData,
//         updatedAt: chat.updatedAt,
//       };

//       for (const participantId of chat.participants) {
//         req.io.to(participantId).emit("chat:updated", updatedChatData);
//       }

//       // Update unread count for other participants
//       const otherParticipants = chat.participants.filter(
//         (uid) => uid !== req.user.uid
//       );
//       for (const uid of otherParticipants) {
//         const unreadCount = await Message.countDocuments({
//           chatId,
//           status: { $in: ["sent", "delivered"] },
//           senderId: { $ne: uid },
//         });
//         req.io.to(uid).emit("unread:count", { chatId, count: unreadCount });
//       }
//     } else {
//       console.warn(
//         "Socket.io instance not available, message saved but not emitted"
//       );
//     }
//     res.status(201).json(messageData);
//   } catch (error) {
//     console.error("Message sending error:", error);
//     res
//       .status(500)
//       .json({ error: "Failed to send message", details: error.message });
//   }
// });

// router.get("/:chatId/messages", verifyToken, async (req, res) => {
//   try {
//     const { chatId } = req.params;
//     const chat = await Chat.findById(chatId);
//     if (!chat || !chat.participants.includes(req.user.uid)) {
//       return res.status(403).json({ error: "Invalid chat or unauthorized" });
//     }
//     const messages = await Message.find({ chatId })
//       .sort({ createdAt: 1 })
//       .limit(50);
//     const populatedMessages = await Promise.all(
//       messages.map(async (message) => {
//         const sender = await User.findOne(
//           { uid: message.senderId },
//           "uid displayName photoUrl"
//         );
//         return {
//           _id: message._id,
//           chatId: message.chatId,
//           senderId: {
//             uid: sender.uid,
//             displayName: sender.displayName,
//             photoUrl: sender.photoUrl,
//           },
//           content: message.content,
//           status: message.status,
//           createdAt: message.createdAt,
//         };
//       })
//     );
//     res.status(200).json(populatedMessages);
//   } catch (error) {
//     console.error("Error fetching messages:", error);
//     res
//       .status(500)
//       .json({ error: "Failed to fetch messages", details: error.message });
//   }
// });

// module.exports = router;

const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/firebaseAuth");
const Chat = require("../models/chat");
const Message = require("../models/message");
const User = require("../models/user");

// Helper function to get IST timestamp
const getISTDate = () => {
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000; // IST is UTC+5:30
  return new Date(now.getTime() + istOffset);
};

// Socket.io event handlers for direct chats
router.handleSocket = (io, socket) => {
  const userId = socket.user.uid;

  socket.on("join:chat", async ({ chatId }) => {
    const chat = await Chat.findById(chatId);
    if (chat && chat.type === 'direct') {
      socket.join(chatId);
      console.log(`${userId} joined direct chat ${chatId}`);

      // Mark all unread messages as read
      try {
        await Message.updateMany(
          {
            chatId,
            senderId: { $ne: userId },
            status: { $in: ["sent", "delivered"] },
          },
          { status: "read" }
        );
        io.to(userId).emit("unread:count", { chatId, count: 0 });
      } catch (error) {
        console.error("Error marking messages as read:", error);
      }
    }
  });

  socket.on("typing", ({ chatId, isTyping }) => {
    const chat = Chat.findById(chatId);
    if (chat && chat.type === 'direct') {
      socket.to(chatId).emit("typing", { userId, isTyping });
    }
  });

  socket.on("message:delivered", async ({ messageId, chatId }) => {
    const chat = await Chat.findById(chatId);
    if (chat && chat.type === 'direct') {
      try {
        const message = await Message.findByIdAndUpdate(
          messageId,
          { status: "delivered" },
          { new: true }
        );
        if (message) {
          io.to(chatId).emit("message:status", {
            messageId,
            status: "delivered",
          });
        }
      } catch (error) {
        console.error("Error updating message status:", error);
      }
    }
  });

  socket.on("message:read", async ({ messageId, chatId }) => {
    const chat = await Chat.findById(chatId);
    if (chat && chat.type === 'direct') {
      try {
        const message = await Message.findByIdAndUpdate(
          messageId,
          { status: "read" },
          { new: true }
        );
        if (message) {
          io.to(chatId).emit("message:status", {
            messageId,
            status: "read",
          });
          const unreadCount = await Message.countDocuments({
            chatId,
            status: { $in: ["sent", "delivered"] },
            senderId: { $ne: userId },
          });
          io.to(userId).emit("unread:count", { chatId, count: unreadCount });
        }
      } catch (error) {
        console.error("Error updating message status:", error);
      }
    }
  });

  socket.on("last:seen", async () => {
    try {
      await User.findOneAndUpdate({ uid: userId }, { lastSeen: getISTDate() });
      io.emit("user:lastSeen", { uid: userId, lastSeen: getISTDate() });
    } catch (error) {
      console.error("Error updating last seen:", error);
    }
  });

  socket.on("join:user", ({ userId }) => {
    socket.join(userId);
    console.log(`User ${userId} joined their notification room`);
  });
};

// Direct chat creation
router.post("/", verifyToken, async (req, res) => {
  try {
    const { participantId } = req.body;
    if (!participantId) {
      return res.status(400).json({ error: "Participant ID is required" });
    }
    const participant = await User.findOne(
      { uid: participantId },
      "uid displayName photoUrl"
    );
    if (!participant) {
      return res.status(404).json({ error: "Participant not found" });
    }
    const participants = [req.user.uid, participantId].sort();
    let chat = await Chat.findOne({ participants, type: 'direct' });
    if (chat) {
      const populatedChat = await Chat.findById(chat._id).populate({
        path: "lastMessage",
        select: "content createdAt senderId",
        populate: { path: "senderId", select: "uid displayName photoUrl" },
      });
      return res.status(200).json({
        _id: populatedChat._id,
        type: 'direct',
        participants: [
          {
            uid: req.user.uid,
            displayName: req.user.name,
            photoUrl: req.user.picture,
          },
          {
            uid: participant.uid,
            displayName: participant.displayName,
            photoUrl: participant.photoUrl,
          },
        ],
        lastMessage: populatedChat.lastMessage ? {
          _id: populatedChat.lastMessage._id,
          content: populatedChat.lastMessage.content,
          createdAt: populatedChat.lastMessage.createdAt,
          senderId: {
            uid: populatedChat.lastMessage.senderId.uid,
            displayName: populatedChat.lastMessage.senderId.displayName,
            photoUrl: populatedChat.lastMessage.senderId.photoUrl,
          },
        } : null,
        updatedAt: populatedChat.updatedAt,
        unreadCount: await Message.countDocuments({
          chatId: chat._id,
          status: { $in: ["sent", "delivered"] },
          senderId: { $ne: req.user.uid },
        }),
      });
    }
    chat = new Chat({ participants, type: 'direct', updatedAt: getISTDate() });
    await chat.save();
    const chatData = {
      _id: chat._id,
      type: 'direct',
      participants: [
        {
          uid: req.user.uid,
          displayName: req.user.name,
          photoUrl: req.user.picture,
        },
        {
          uid: participant.uid,
          displayName: participant.displayName,
          photoUrl: participant.photoUrl,
        },
      ],
      lastMessage: null,
      updatedAt: chat.updatedAt,
      unreadCount: 0,
    };

    if (req.io) {
      req.io.to(req.user.uid).emit("chat:new", chatData);
      req.io.to(participantId).emit("chat:new", chatData);
    }

    res.status(201).json(chatData);
  } catch (error) {
    console.error("Chat creation error:", error);
    res
      .status(500)
      .json({ error: "Failed to start chat", details: error.message });
  }
});

// Fetch all chats (direct and group)
router.get("/", verifyToken, async (req, res) => {
  try {
    const chats = await Chat.find({ participants: req.user.uid })
      .populate({
        path: "lastMessage",
        select: "content createdAt senderId",
        populate: { path: "senderId", select: "uid displayName photoUrl" },
      })
      .sort({ updatedAt: -1 });
    const populatedChats = await Promise.all(
      chats.map(async (chat) => {
        const participants = await User.find(
          { uid: { $in: chat.participants } },
          "uid displayName photoUrl"
        );
        const unreadCount = await Message.countDocuments({
          chatId: chat._id,
          status: { $in: ["sent", "delivered"] },
          senderId: { $ne: req.user.uid },
        });
        return {
          _id: chat._id,
          type: chat.type,
          participants,
          groupName: chat.groupName,
          groupAdmin: chat.groupAdmin,
          groupMembers: chat.groupMembers ? await User.find(
            { uid: { $in: chat.groupMembers } },
            "uid displayName photoUrl"
          ) : [],
          lastMessage: chat.lastMessage ? {
            _id: chat.lastMessage._id,
            content: chat.lastMessage.content,
            createdAt: chat.lastMessage.createdAt,
            senderId: {
              uid: chat.lastMessage.senderId.uid,
              displayName: chat.lastMessage.senderId.displayName,
              photoUrl: chat.lastMessage.senderId.photoUrl,
            },
          } : null,
          updatedAt: chat.updatedAt,
          unreadCount,
        };
      })
    );
    res.status(200).json(populatedChats);
  } catch (error) {
    console.error("Error fetching chats:", error);
    res
      .status(500)
      .json({ error: "Failed to fetch chats", details: error.message });
  }
});

// Send message (direct or group)
router.post("/:chatId/messages", verifyToken, async (req, res) => {
  try {
    const { chatId } = req.params;
    const { content } = req.body;
    if (!content) {
      return res.status(400).json({ error: "Message content is required" });
    }
    const chat = await Chat.findById(chatId);
    if (!chat || !chat.participants.includes(req.user.uid)) {
      return res.status(403).json({ error: "Invalid chat or unauthorized" });
    }
    const message = new Message({
      chatId,
      senderId: req.user.uid,
      content,
      createdAt: getISTDate(),
      status: "sent",
    });
    await message.save();
    chat.lastMessage = message._id;
    chat.updatedAt = getISTDate();
    await chat.save();
    const sender = await User.findOne(
      { uid: message.senderId },
      "uid displayName photoUrl"
    );
    const messageData = {
      _id: message._id,
      chatId: message.chatId,
      senderId: {
        uid: sender.uid,
        displayName: sender.displayName,
        photoUrl: sender.photoUrl,
      },
      content: message.content,
      status: message.status,
      createdAt: message.createdAt,
    };
    if (req.io) {
      req.io.to(chatId).emit("message:new", messageData);
      const otherParticipants = chat.type === 'group' ? chat.groupMembers : chat.participants.filter(
        (uid) => uid !== req.user.uid
      );
      for (const uid of otherParticipants) {
        req.io.to(uid).emit("message:new", messageData);
        const unreadCount = await Message.countDocuments({
          chatId,
          status: { $in: ["sent", "delivered"] },
          senderId: { $ne: uid },
        });
        req.io.to(uid).emit("unread:count", { chatId, count: unreadCount });
      }
      const updatedChatData = {
        chatId: chatId,
        lastMessage: messageData,
        updatedAt: chat.updatedAt,
      };
      for (const uid of otherParticipants) {
        req.io.to(uid).emit("chat:updated", updatedChatData);
      }
    }
    res.status(201).json(messageData);
  } catch (error) {
    console.error("Message sending error:", error);
    res
      .status(500)
      .json({ error: "Failed to send message", details: error.message });
  }
});

// Fetch messages (direct or group)
router.get("/:chatId/messages", verifyToken, async (req, res) => {
  try {
    const { chatId } = req.params;
    const chat = await Chat.findById(chatId);
    if (!chat || !chat.participants.includes(req.user.uid)) {
      return res.status(403).json({ error: "Invalid chat or unauthorized" });
    }
    const messages = await Message.find({ chatId })
      .sort({ createdAt: 1 })
      .limit(50)
      .populate('senderId', 'uid displayName photoUrl');
    const populatedMessages = messages.map((message) => ({
      _id: message._id,
      chatId: message.chatId,
      senderId: {
        uid: message.senderId.uid,
        displayName: message.senderId.displayName,
        photoUrl: message.senderId.photoUrl,
      },
      content: message.content,
      status: message.status,
      createdAt: message.createdAt,
    }));
    res.status(200).json(populatedMessages);
  } catch (error) {
    console.error("Error fetching messages:", error);
    res
      .status(500)
      .json({ error: "Failed to fetch messages", details: error.message });
  }
});

module.exports = router;