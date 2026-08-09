const express = require('express');
const pool = require('../db');
const { requireAdminAuth } = require('../middleware/adminAuth');

const router = express.Router();
router.use(requireAdminAuth);

const SELECT_WITH_CONTACTS = `
  SELECT c.id, c.name, c.industry, c.location, c.address, c.email, c.website,
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
`;

function toCompanyJson(row) {
  return {
    id: Number(row.id),
    name: row.name,
    industry: row.industry,
    location: row.location,
    address: row.address,
    email: row.email,
    website: row.website,
    dateAccredited: row.date_accredited,
    contacts: row.contacts,
  };
}

router.get('/', async (req, res) => {
  try {
    const { search, industry, location } = req.query;
    const conditions = [];
    const params = [];
    if (search) {
      params.push(`%${search.toString().toLowerCase()}%`);
      conditions.push(`(LOWER(c.name) LIKE $${params.length} OR LOWER(c.industry) LIKE $${params.length})`);
    }
    if (industry) {
      params.push(industry.toString());
      conditions.push(`c.industry = $${params.length}`);
    }
    if (location) {
      params.push(location.toString());
      conditions.push(`c.location = $${params.length}`);
    }
    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const result = await pool.query(
      `${SELECT_WITH_CONTACTS} ${where} GROUP BY c.id ORDER BY c.name ASC`,
      params,
    );
    res.json({ success: true, companies: result.rows.map(toCompanyJson) });
  } catch (error) {
    console.error('Get admin HTE companies error:', error);
    res.status(500).json({ success: false, message: 'Failed to load companies.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, industry, location, address, email, website, dateAccredited, contacts } =
      req.body;
    if (!name || !industry || !location || !address || !email) {
      return res.status(400).json({
        success: false,
        message: 'name, industry, location, address, and email are required.',
      });
    }

    const inserted = await pool.query(
      `INSERT INTO hte_companies (name, industry, location, address, email, website, date_accredited)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [
        name.trim(),
        industry.trim(),
        location.trim(),
        address.trim(),
        email.trim(),
        website ? website.toString().trim() : null,
        dateAccredited || null,
      ],
    );
    const companyId = inserted.rows[0].id;

    if (Array.isArray(contacts)) {
      for (const contact of contacts) {
        if (!contact.name || !contact.phone) continue;
        await pool.query(
          'INSERT INTO hte_company_contacts (company_id, name, phone) VALUES ($1, $2, $3)',
          [companyId, contact.name.toString().trim(), contact.phone.toString().trim()],
        );
      }
    }

    const full = await pool.query(`${SELECT_WITH_CONTACTS} WHERE c.id = $1 GROUP BY c.id`, [
      companyId,
    ]);
    res.status(201).json({ success: true, company: toCompanyJson(full.rows[0]) });
  } catch (error) {
    console.error('Create HTE company error:', error);
    res.status(500).json({ success: false, message: 'Failed to create company.' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    const companyId = Number(req.params.id);
    const existing = await pool.query('SELECT id FROM hte_companies WHERE id = $1', [companyId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Company not found.' });
    }

    const { name, industry, location, address, email, website, dateAccredited, contacts } =
      req.body;
    if (!name || !industry || !location || !address || !email) {
      return res.status(400).json({
        success: false,
        message: 'name, industry, location, address, and email are required.',
      });
    }

    await pool.query(
      `UPDATE hte_companies
       SET name = $1, industry = $2, location = $3, address = $4, email = $5,
           website = $6, date_accredited = $7
       WHERE id = $8`,
      [
        name.trim(),
        industry.trim(),
        location.trim(),
        address.trim(),
        email.trim(),
        website ? website.toString().trim() : null,
        dateAccredited || null,
        companyId,
      ],
    );

    if (Array.isArray(contacts)) {
      await pool.query('DELETE FROM hte_company_contacts WHERE company_id = $1', [companyId]);
      for (const contact of contacts) {
        if (!contact.name || !contact.phone) continue;
        await pool.query(
          'INSERT INTO hte_company_contacts (company_id, name, phone) VALUES ($1, $2, $3)',
          [companyId, contact.name.toString().trim(), contact.phone.toString().trim()],
        );
      }
    }

    const full = await pool.query(`${SELECT_WITH_CONTACTS} WHERE c.id = $1 GROUP BY c.id`, [
      companyId,
    ]);
    res.json({ success: true, company: toCompanyJson(full.rows[0]) });
  } catch (error) {
    console.error('Update HTE company error:', error);
    res.status(500).json({ success: false, message: 'Failed to update company.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const companyId = Number(req.params.id);
    const result = await pool.query('DELETE FROM hte_companies WHERE id = $1 RETURNING id', [
      companyId,
    ]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Company not found.' });
    }
    res.json({ success: true });
  } catch (error) {
    console.error('Delete HTE company error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete company.' });
  }
});

module.exports = router;
