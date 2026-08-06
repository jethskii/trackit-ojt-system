require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const pool = require('./db');

const authRoutes = require('./routes/auth');
const attendanceRoutes = require('./routes/attendance');
const hteCompaniesRoutes = require('./routes/hteCompanies');
const requirementsRoutes = require('./routes/requirements');
const activityReportsRoutes = require('./routes/activityReports');
const notificationsRoutes = require('./routes/notifications');
const profileRoutes = require('./routes/profile');

const app = express();
const PORT = process.env.PORT || 3000;

// multer's disk storage needs these to exist up front.
for (const dir of ['uploads/requirements', 'uploads/avatars']) {
  fs.mkdirSync(path.join(__dirname, dir), { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Basic health check route
app.get('/', (req, res) => {
  res.json({ message: 'TRACKIT server is running' });
});

// Test database connection route
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      success: true,
      message: 'Database connected successfully',
      timestamp: result.rows[0].now,
    });
  } catch (error) {
    console.error('Database connection error:', error);
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: error.message,
    });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/hte-companies', hteCompaniesRoutes);
app.use('/api/requirements', requirementsRoutes);
app.use('/api/activity-reports', activityReportsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/profile', profileRoutes);

app.listen(PORT, () => {
  console.log(`TRACKIT server running on http://localhost:${PORT}`);
});
