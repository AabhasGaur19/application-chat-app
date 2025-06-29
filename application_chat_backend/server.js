// // application_chat_backend/server.js
// const express = require('express');
// const cors = require('cors');
// const connectDB = require('./config/db');
// const admin = require('firebase-admin');
// const userRoutes = require('./routes/user');
// const chatRoutes = require('./routes/chat');
// const { Server } = require('socket.io');
// const http = require('http');
// require('dotenv').config();

// console.log('Environment check:');
// console.log('MONGO_URI defined:', !!process.env.MONGO_URI);
// console.log('FLUTTER_APP_URL:', process.env.FLUTTER_APP_URL);
// console.log('PORT:', process.env.PORT);

// const serviceAccount = JSON.parse(
//   Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
// );

// const app = express();
// const server = http.createServer(app);
// const io = new Server(server, {
//   cors: {
//     origin: process.env.FLUTTER_APP_URL,
//     methods: ['GET', 'POST'],
//   },
// });

// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// connectDB();

// // Middleware to attach io to req
// app.use((req, res, next) => {
//   req.io = io;
//   next();
// });

// app.use(cors({
//   origin: process.env.FLUTTER_APP_URL,
//   methods: ['GET', 'POST', 'PUT', 'DELETE'],
//   allowedHeaders: ['Content-Type', 'Authorization'],
// }));
// app.use(express.json());

// app.use('/api/users', userRoutes);
// app.use('/api/chats', chatRoutes);

// // Socket.io authentication
// io.use(async (socket, next) => {
//   const token = socket.handshake.auth.token;
//   if (!token) {
//     return next(new Error('Authentication error: No token provided'));
//   }
//   try {
//     const decodedToken = await admin.auth().verifyIdToken(token);
//     socket.user = { uid: decodedToken.uid };
//     next();
//   } catch (error) {
//     next(new Error('Authentication error: Invalid token'));
//   }
// });

// // Socket.io connection handling
// // In server.js, update the Socket.io connection handling section:

// // Socket.io connection handling
// io.on('connection', (socket) => {
//   console.log(`User connected: ${socket.user.uid}`);

//   // Join user-specific room
//   socket.join(socket.user.uid);

//   // Update online status immediately for all users
//   io.emit('user:status', { uid: socket.user.uid, online: true });

//   // Handle disconnection
//   socket.on('disconnect', () => {
//     console.log(`User disconnected: ${socket.user.uid}`);
//     // Broadcast offline status to all users
//     io.emit('user:status', { uid: socket.user.uid, online: false });
//   });

//   // Pass io and socket to chat routes for event handling
//   chatRoutes.handleSocket(io, socket);
// });

// app.use((err, req, res, next) => {
//   console.error(err.stack);
//   res.status(500).json({ error: 'Something went wrong!', details: err.message });
// });

// const PORT = process.env.PORT || 3000;
// server.listen(PORT, () => {
//   console.log(`Server running on port ${PORT}`);
// });


const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const admin = require('firebase-admin');
const userRoutes = require('./routes/user');
const chatRoutes = require('./routes/chat');
const groupRoutes = require('./routes/group');
const { Server } = require('socket.io');
const http = require('http');
require('dotenv').config();

console.log('Environment check:');
console.log('MONGO_URI defined:', !!process.env.MONGO_URI);
console.log('FLUTTER_APP_URL:', process.env.FLUTTER_APP_URL);
console.log('PORT:', process.env.PORT);

const serviceAccount = JSON.parse(
  Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
);

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FLUTTER_APP_URL,
    methods: ['GET', 'POST'],
  },
});

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

connectDB();

app.use((req, res, next) => {
  req.io = io;
  next();
});

app.use(cors({
  origin: process.env.FLUTTER_APP_URL,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/groups', groupRoutes);

io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) {
    return next(new Error('Authentication error: No token provided'));
  }
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    socket.user = { uid: decodedToken.uid };
    next();
  } catch (error) {
    next(new Error('Authentication error: Invalid token'));
  }
});

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.user.uid}`);
  socket.join(socket.user.uid);
  io.emit('user:status', { uid: socket.user.uid, online: true });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.user.uid}`);
    io.emit('user:status', { uid: socket.user.uid, online: false });
  });

  chatRoutes.handleSocket(io, socket);
  groupRoutes.handleSocket(io, socket);
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!', details: err.message });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});