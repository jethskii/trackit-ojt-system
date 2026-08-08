// Minimal RFC4180-ish CSV writer -- no external dependency needed for a
// flat table export. Quotes a field only when it actually needs it
// (contains a comma, quote, or newline), doubling any embedded quotes.
function csvField(value) {
  const str = value === null || value === undefined ? '' : String(value);
  if (/[",\n\r]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function toCsv(columns, rows) {
  const lines = [columns.map((c) => csvField(c.label)).join(',')];
  for (const row of rows) {
    lines.push(columns.map((c) => csvField(row[c.key])).join(','));
  }
  return lines.join('\r\n');
}

module.exports = { toCsv };
