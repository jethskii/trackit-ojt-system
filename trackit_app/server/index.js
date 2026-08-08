const path = require('path');
// .env lives at trackit_app/.env (one level up from server/) -- see db.js.
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const pool = require('./db');

const authRoutes = require('./routes/auth');
const instructorAuthRoutes = require('./routes/instructorAuth');
const adminAuthRoutes = require('./routes/adminAuth');
const adminClassesRoutes = require('./routes/adminClasses');
const adminAnnouncementsRoutes = require('./routes/adminAnnouncements');
const teacherDashboardRoutes = require('./routes/teacherDashboard');
const teacherClassesRoutes = require('./routes/teacherClasses');
const classesRoutes = require('./routes/classes');
const teacherStudentsRoutes = require('./routes/teacherStudents');
const teacherNotificationsRoutes = require('./routes/teacherNotifications');
const teacherAnnouncementsRoutes = require('./routes/teacherAnnouncements');
const teacherProfileRoutes = require('./routes/teacherProfile');
const teacherRequirementsRoutes = require('./routes/teacherRequirements');
const teacherAttendanceRoutes = require('./routes/teacherAttendance');
const teacherWeeklyReportsRoutes = require('./routes/teacherWeeklyReports');
const attendanceRoutes = require('./routes/attendance');
const hteCompaniesRoutes = require('./routes/hteCompanies');
const requirementsRoutes = require('./routes/requirements');
const customRequirementsRoutes = require('./routes/customRequirements');
const activityReportsRoutes = require('./routes/activityReports');
const notificationsRoutes = require('./routes/notifications');
const announcementsRoutes = require('./routes/announcements');
const profileRoutes = require('./routes/profile');

const app = express();
const PORT = process.env.PORT || 3000;

// multer's disk storage needs these to exist up front.
for (const dir of [
  'uploads/requirements',
  'uploads/avatars',
  'uploads/announcements',
  'uploads/admin-announcements',
]) {
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
app.use('/api/instructor-auth', instructorAuthRoutes);
app.use('/api/admin-auth', adminAuthRoutes);
app.use('/api/admin/classes', adminClassesRoutes);
app.use('/api/admin/announcements', adminAnnouncementsRoutes);
app.use('/api/teacher/dashboard', teacherDashboardRoutes);
app.use('/api/teacher/classes', teacherClassesRoutes);
app.use('/api/teacher/students', teacherStudentsRoutes);
app.use('/api/teacher/notifications', teacherNotificationsRoutes);
app.use('/api/teacher/announcements', teacherAnnouncementsRoutes);
app.use('/api/teacher/profile', teacherProfileRoutes);
app.use('/api/teacher/requirements', teacherRequirementsRoutes);
app.use('/api/teacher/attendance', teacherAttendanceRoutes);
app.use('/api/teacher/weekly-reports', teacherWeeklyReportsRoutes);
app.use('/api/classes', classesRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/hte-companies', hteCompaniesRoutes);
app.use('/api/requirements', requirementsRoutes);
app.use('/api/custom-requirements', customRequirementsRoutes);
app.use('/api/activity-reports', activityReportsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/announcements', announcementsRoutes);
app.use('/api/profile', profileRoutes);

app.listen(PORT, () => {
  console.log(`TRACKIT server running on http://localhost:${PORT}`);
});
