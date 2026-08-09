const nodemailer = require('nodemailer');

// Real SMTP -- requires SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS in .env
// (e.g. a Gmail App Password, or any SMTP provider). Built lazily so a
// server without these configured yet can still boot; sending will just
// fail with a clear error at the point of use instead of crashing startup.
let transporter = null;
function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
    throw new Error(
      'Email is not configured -- set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS in .env.',
    );
  }
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: Number(process.env.SMTP_PORT) === 465,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
  return transporter;
}

async function sendOtpEmail(toEmail, code) {
  const from = process.env.SMTP_FROM || process.env.SMTP_USER;
  await getTransporter().sendMail({
    from: `TRACKIT <${from}>`,
    to: toEmail,
    subject: 'Your TRACKIT verification code',
    text: `Your verification code is ${code}. It expires in 10 minutes. If you did not request this, you can ignore this email.`,
    html: `
      <p>Your TRACKIT verification code is:</p>
      <p style="font-size: 28px; font-weight: bold; letter-spacing: 4px;">${code}</p>
      <p>This code expires in 10 minutes and can only be used once.</p>
      <p>If you did not request this, you can safely ignore this email.</p>
    `,
  });
}

module.exports = { sendOtpEmail };
