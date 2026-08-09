const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// Read-only for students -- name, industry, location, address, email,
// website, date accredited, and contact persons, exactly what the Admin
// entered. No positions/slots/application data: this directory is a pure
// reference/recommendation list, not an application tracker.
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.id, c.name, c.industry, c.location, c.address, c.email, c.website,
              c.date_accredited,
        COALESCE(
          json_agg(
            json_build_object('id', ct.id, 'name', ct.name, 'phone', ct.phone)
            ORDER BY ct.id
          ) FILTER (WHERE ct.id IS NOT NULL),
          '[]'
        ) AS contacts
       FROM hte_companies c
       LEFT JOIN hte_company_contacts ct ON ct.company_id = c.id
       GROUP BY c.id
       ORDER BY c.name ASC`,
    );
    res.json({
      success: true,
      companies: result.rows.map((row) => ({
        id: Number(row.id),
        name: row.name,
        industry: row.industry,
        location: row.location,
        address: row.address,
        email: row.email,
        website: row.website,
        dateAccredited: row.date_accredited,
        contacts: row.contacts,
      })),
    });
  } catch (error) {
    console.error('Get HTE companies error:', error);
    res.status(500).json({ success: false, message: 'Failed to load companies.' });
  }
});

module.exports = router;
