// const AWS = require('aws-sdk');

// const s3 = new AWS.S3({
//   accessKeyId: process.env.AWS_ACCESS_KEY_ID,
//   secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
//   region: process.env.AWS_REGION,
// });

// const uploadToS3 = async (file, userId) => {
//   const params = {
//     Bucket: process.env.AWS_S3_BUCKET,
//     Key: `profile-pics/${userId}-${Date.now()}-${file.originalname}`,
//     Body: file.buffer,
//     ContentType: file.mimetype,
//   };
//   try {
//     const result = await s3.upload(params).promise();
//     return { Location: result.Location };
//   } catch (error) {
//     throw new Error(`S3 upload failed: ${error.message}`);
//   }
// };

// module.exports = { uploadToS3 };
const AWS = require('aws-sdk');

// Debug AWS configuration
console.log('AWS Configuration:', {
  accessKeyId: process.env.AWS_ACCESS_KEY_ID ? 'Set' : 'Not Set',
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ? 'Set' : 'Not Set',
  region: process.env.AWS_REGION,
  bucket: process.env.AWS_S3_BUCKET
});

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION,
  signatureVersion: 'v4', // Explicitly set signature version
});

const uploadToS3 = async (file, userId) => {
  console.log('Uploading to S3:', {
    bucket: process.env.AWS_S3_BUCKET,
    userId: userId,
    fileName: file.originalname,
    fileSize: file.buffer.length,
    contentType: file.mimetype
  });

  const params = {
    Bucket: process.env.AWS_S3_BUCKET,
    Key: `profile-pics/${userId}-${Date.now()}-${file.originalname}`,
    Body: file.buffer,
    ContentType: file.mimetype,
    // ACL: 'public-read', // Make the file publicly readable
  };
  
  try {
    console.log('S3 upload params:', {
      Bucket: params.Bucket,
      Key: params.Key,
      ContentType: params.ContentType,
      BodyLength: params.Body.length
    });
    
    const result = await s3.upload(params).promise();
    console.log('S3 upload successful:', result.Location);
    return { Location: result.Location };
  } catch (error) {
    console.error('S3 upload error details:', {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
      region: error.region,
      hostname: error.hostname,
      retryable: error.retryable
    });
    throw new Error(`S3 upload failed: ${error.message}`);
  }
};

module.exports = { uploadToS3 };