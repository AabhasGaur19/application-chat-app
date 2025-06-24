// const express = require('express');
// const router = express.Router();
// const multer = require('multer');
// const verifyToken = require('../middleware/firebaseAuth');
// const User = require('../models/user');
// const { uploadToS3 } = require('../utils/s3Upload'); // Adjust path as needed

// // Configure multer for memory storage
// const upload = multer({ 
//   storage: multer.memoryStorage(),
//   limits: {
//     fileSize: 5 * 1024 * 1024, // 5MB limit
//   },
//   fileFilter: (req, file, cb) => {
//     if (file.mimetype.startsWith('image/')) {
//       cb(null, true);
//     } else {
//       cb(new Error('Only image files are allowed'), false);
//     }
//   }
// });




// router.post('/profile', verifyToken, async (req, res) => {
//   try {
//     const { displayName } = req.body;
//     if (!displayName) {
//       return res.status(400).json({ error: 'Display name is required' });
//     }
//     let user = await User.findOne({ uid: req.user.uid });
//     if (user) {
//       user.displayName = displayName;
//       user.updatedAt = new Date();
//       await user.save();
//     } else {
//       user = new User({
//         uid: req.user.uid,
//         displayName,
//         email: req.user.email,
//         photoUrl: req.user.picture,
//       });
//       await user.save();
//     }
//     res.status(200).json(user);
//   } catch (error) {
//     console.error('Error updating profile:', error);
//     res.status(500).json({ error: 'Failed to update profile', details: error.message });
//   }
// });

// router.get('/profile', verifyToken, async (req, res) => {
//   try {
//     const user = await User.findOne({ uid: req.user.uid });
//     if (!user) {
//       return res.status(404).json({ error: 'User not found' });
//     }
//     res.status(200).json(user);
//   } catch (error) {
//     console.error('Error fetching profile:', error);
//     res.status(500).json({ error: 'Failed to fetch profile', details: error.message });
//   }
// });

// router.put('/profile', verifyToken, async (req, res) => {
//   try {
//     const { displayName } = req.body;
//     if (!displayName) {
//       return res.status(400).json({ error: 'Display name is required' });
//     }
//     const user = await User.findOne({ uid: req.user.uid });
//     if (!user) {
//       return res.status(404).json({ error: 'User not found' });
//     }
//     user.displayName = displayName;
//     user.updatedAt = new Date();
//     await user.save();
//     res.status(200).json(user);
//   } catch (error) {
//     console.error('Error updating display name:', error);
//     res.status(500).json({ error: 'Failed to update display name', details: error.message });
//   }
// });

// // ... your existing routes (profile GET, PUT, POST) ...

// router.post('/profile/picture', verifyToken, upload.single('photo'), async (req, res) => {
//   try {
//     console.log('Request file:', req.file);
//     console.log('Request body:', req.body);
    
//     if (!req.file) {
//       return res.status(400).json({ error: 'Photo file is required' });
//     }

//     // Upload to S3
//     const s3Result = await uploadToS3(req.file, req.user.uid);
    
//     if (!s3Result || !s3Result.Location) {
//       return res.status(500).json({ error: 'Failed to upload image to S3' });
//     }

//     // Update user in database
//     const user = await User.findOne({ uid: req.user.uid });
//     if (!user) {
//       return res.status(404).json({ error: 'User not found' });
//     }

//     user.photoUrl = s3Result.Location;
//     user.updatedAt = new Date();
//     await user.save();

//     res.status(200).json({ photoUrl: user.photoUrl });
//   } catch (error) {
//     console.error('Error updating profile picture:', error);
//     res.status(500).json({ 
//       error: 'Failed to update profile picture', 
//       details: error.message 
//     });
//   }
// });

// // ... rest of your existing routes ...
// router.get('/search', verifyToken, async (req, res) => {
//   try {
//     const query = req.query.q || '';
//     let users;
//     if (query.trim() === '') {
//       // Return all users except the current user, sorted by displayName
//       users = await User.find({ uid: { $ne: req.user.uid } })
//         .select('uid displayName email photoUrl')
//         .sort({ displayName: 1 }); // Lexicographical sort
//     } else {
//       // Search by displayName
//       users = await User.find({
//         displayName: { $regex: query, $options: 'i' },
//         uid: { $ne: req.user.uid },
//       }).select('uid displayName email photoUrl');
//     }
//     res.status(200).json(users);
//   } catch (error) {
//     console.error('Error searching users:', error);
//     res.status(500).json({ error: 'Failed to search users', details: error.message });
//   }
// });

// module.exports = router;
const express = require('express');
const router = express.Router();
const multer = require('multer');
const verifyToken = require('../middleware/firebaseAuth');
const User = require('../models/user');
const { uploadToS3 } = require('../utils/s3');

// Configure multer for memory storage
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

router.post('/profile', verifyToken, async (req, res) => {
  try {
    const { displayName } = req.body;
    if (!displayName) {
      return res.status(400).json({ error: 'Display name is required' });
    }
    let user = await User.findOne({ uid: req.user.uid });
    if (user) {
      user.displayName = displayName;
      user.updatedAt = new Date();
      await user.save();
    } else {
      user = new User({
        uid: req.user.uid,
        displayName,
        email: req.user.email,
        photoUrl: req.user.picture,
      });
      await user.save();
    }
    res.status(200).json(user);
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Failed to update profile', details: error.message });
  }
});

router.get('/profile', verifyToken, async (req, res) => {
  try {
    const user = await User.findOne({ uid: req.user.uid });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile', details: error.message });
  }
});

router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { displayName } = req.body;
    if (!displayName) {
      return res.status(400).json({ error: 'Display name is required' });
    }
    const user = await User.findOne({ uid: req.user.uid });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    user.displayName = displayName;
    user.updatedAt = new Date();
    await user.save();
    res.status(200).json(user);
  } catch (error) {
    console.error('Error updating display name:', error);
    res.status(500).json({ error: 'Failed to update display name', details: error.message });
  }
});

router.post('/profile/picture', verifyToken, upload.single('photo'), async (req, res) => {
  try {
    console.log('Request file:', req.file);
    console.log('Request body:', req.body);
    
    if (!req.file) {
      return res.status(400).json({ error: 'Photo file is required' });
    }

    // Upload to S3
    const s3Result = await uploadToS3(req.file, req.user.uid);
    
    if (!s3Result || !s3Result.Location) {
      return res.status(500).json({ error: 'Failed to upload image to S3' });
    }

    // Update user in database
    const user = await User.findOne({ uid: req.user.uid });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    user.photoUrl = s3Result.Location;
    user.updatedAt = new Date();
    await user.save();

    res.status(200).json({ photoUrl: user.photoUrl });
  } catch (error) {
    console.error('Error updating profile picture:', error);
    res.status(500).json({ 
      error: 'Failed to update profile picture', 
      details: error.message 
    });
  }
});

router.get('/search', verifyToken, async (req, res) => {
  try {
    const query = req.query.q || '';
    let users;
    if (query.trim() === '') {
      // Return all users except the current user, sorted by displayName
      users = await User.find({ uid: { $ne: req.user.uid } })
        .select('uid displayName email photoUrl')
        .sort({ displayName: 1 }); // Lexicographical sort
    } else {
      // Search by displayName
      users = await User.find({
        displayName: { $regex: query, $options: 'i' },
        uid: { $ne: req.user.uid },
      }).select('uid displayName email photoUrl');
    }
    res.status(200).json(users);
  } catch (error) {
    console.error('Error searching users:', error);
    res.status(500).json({ error: 'Failed to search users', details: error.message });
  }
});

module.exports = router;