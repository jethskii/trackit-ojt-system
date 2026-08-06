const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM hte_companies ORDER BY name ASC');
    res.json({ success: true, companies: result.rows });
  } catch (error) {
    console.error('Get HTE companies error:', error);
    res.status(500).json({ success: false, message: 'Failed to load companies.' });
  }
});

module.exports = router;
