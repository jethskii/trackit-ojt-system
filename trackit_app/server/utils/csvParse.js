// Minimal RFC4180-ish CSV parser for admin-uploaded imports (Import
// Students). Handles quoted fields (with escaped "" inside quotes),
// commas inside quotes, and both \n and \r\n line endings. Not a
// general-purpose CSV library -- just enough for a well-defined,
// admin-controlled input file, matching the hand-rolled rigor already
// used elsewhere in this codebase (e.g. the Archive PDF table layout).
function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  const n = text.length;

  function endField() {
    row.push(field);
    field = '';
  }
  function endRow() {
    endField();
    rows.push(row);
    row = [];
  }

  while (i < n) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      field += c;
      i += 1;
      continue;
    }

    if (c === '"') {
      inQuotes = true;
      i += 1;
      continue;
    }
    if (c === ',') {
      endField();
      i += 1;
      continue;
    }
    if (c === '\r') {
      i += 1;
      continue;
    }
    if (c === '\n') {
      endRow();
      i += 1;
      continue;
    }
    field += c;
    i += 1;
  }
  // Last field/row, if the file doesn't end with a newline.
  if (field.length > 0 || row.length > 0) endRow();

  return rows.filter((r) => r.some((cell) => cell.trim() !== ''));
}

// Parses a CSV with a header row into an array of { header: value }
// objects, matching headers case-insensitively and ignoring surrounding
// whitespace (spreadsheet exports often have inconsistent header casing).
function parseCsvRecords(text) {
  const rows = parseCsv(text);
  if (rows.length === 0) return [];
  const headers = rows[0].map((h) => h.trim().toLowerCase());
  return rows.slice(1).map((row) => {
    const record = {};
    headers.forEach((header, index) => {
      record[header] = (row[index] ?? '').trim();
    });
    return record;
  });
}

module.exports = { parseCsv, parseCsvRecords };
