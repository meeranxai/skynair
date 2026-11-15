const express = require('express');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: [
        "'self'",
        "'unsafe-inline'",
        "'unsafe-eval'",
        "https://www.gstatic.com",
        "https://accounts.google.com",
        "https://apis.google.com"
      ],
      styleSrc: [
        "'self'",
        "'unsafe-inline'",
        "https://fonts.googleapis.com"
      ],
      fontSrc: [
        "'self'",
        "https://fonts.gstatic.com"
      ],
      connectSrc: [
        "'self'",
        "https://*.firebaseapp.com",
        "https://*.googleapis.com",
        "https://*.google.com",
        "https://www.gstatic.com",
        "https://fonts.gstatic.com",
        "wss://*.firebaseio.com",
        "ws://localhost:*",
        "http://localhost:*"
      ],
      imgSrc: [
        "'self'",
        "data:",
        "https:",
        "blob:"
      ],
      frameSrc: [
        "'self'",
        "https://accounts.google.com"
      ],
      workerSrc: [
        "'self'",
        "blob:"
      ],
      childSrc: [
        "'self'",
        "blob:"
      ]
    }
  }
}));

// Enable CORS for all routes
app.use(cors({
  origin: true,
  credentials: true
}));

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Enable gzip compression
app.use(compression());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: 'G-Network Social Media App',
    socket: io ? 'active' : 'inactive'
  });
});

// API status endpoint
app.get('/api/status', (req, res) => {
  res.status(200).json({
    app: 'G-Network Social Media App',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'production'
  });
});

// Serve Flutter web build
const buildPath = path.join(__dirname, 'build', 'web');

// Static files with proper caching
app.use(express.static(buildPath, {
  maxAge: '1d', // Cache static assets for 1 day
  etag: true,
  lastModified: true,
  setHeaders: (res, path) => {
    // Cache Flutter assets longer
    if (path.endsWith('.js') || path.endsWith('.css')) {
      res.setHeader('Cache-Control', 'public, max-age=86400'); // 1 day
    }
    // Cache images and fonts longer
    if (path.match(/\.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
      res.setHeader('Cache-Control', 'public, max-age=2592000'); // 30 days
    }
    // Don't cache HTML files
    if (path.endsWith('.html')) {
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    }
  }
}));

// Handle Flutter web routing - serve index.html for all routes
app.get('*', (req, res) => {
  // Don't serve index.html for API routes
  if (req.path.startsWith('/api/') || req.path.startsWith('/health')) {
    return res.status(404).json({ error: 'Not found' });
  }
  
  res.sendFile(path.join(buildPath, 'index.html'), (err) => {
    if (err) {
      console.error('Error serving index.html:', err);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to serve application'
      });
    }
  });
});

// Socket.IO Logic
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  const userId = socket.handshake.query.userId;
  if(userId) {
     console.log(`User ID ${userId} linked to socket ${socket.id}`);
     socket.join(userId);
  }

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });

  // Post Events
  socket.on('new_post', (data) => {
    console.log('New post:', data.id);
    io.emit('new_post', data);
  });

  socket.on('post_updated', (data) => {
    console.log('Post updated:', data.id);
    io.emit('post_updated', data);
  });

  socket.on('post_interaction', (data) => {
    console.log('Post interaction:', data.type, data.postId);
    io.emit('post_interaction', data);
  });

  // Follow Events
  socket.on('follow_update', (data) => {
    console.log(`Follow update: ${data.followerId} -> ${data.followingId}`);
    // Notify the followed user specifically if possible, but broadcast for now for all clients to update lists
    io.emit('follow_update', data);
  });

  // Notification Events
  socket.on('new_notification', (data) => {
    console.log('New notification for:', data.userId);
    // If we have rooms, we could emit to specific user room: io.to(data.userId).emit(...)
    // For now broadcast (clients filter by their own ID usually)
    io.emit('new_notification', data);
  });

  socket.on('notification_update', (data) => {
    io.emit('notification_update', data);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 G-Network Social Media App server running on port ${PORT}`);
  console.log(`📱 App URL: http://localhost:${PORT}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  console.log(`⚡ Socket.IO active`);
  
  // Log build directory status
  const fs = require('fs');
  const buildExists = fs.existsSync(buildPath);
  console.log(`📁 Build directory exists: ${buildExists}`);
  
  if (buildExists) {
    const files = fs.readdirSync(buildPath);
    console.log(`📄 Build files: ${files.length} files found`);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  process.exit(0);
});

module.exports = app;