const ExcelJS = require('exceljs');

// Same output shape as csvParse.js's parseCsvRecords -- an array of
// { header: value } objects, header row matched case-insensitively --
// so Import Students can accept an .xlsx template alongside .csv without
// the rest of the import logic caring which format was uploaded.
async function parseXlsxRecords(buffer) {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  const sheet = workbook.worksheets[0];
  if (!sheet) return [];

  let headers = [];
  const records = [];
  sheet.eachRow((row, rowNumber) => {
    const values = row.values; // 1-indexed; values[0] is unused
    if (rowNumber === 1) {
      headers = values.map((v) => (v ?? '').toString().trim().toLowerCase());
      return;
    }
    const record = {};
    let hasValue = false;
    for (let i = 1; i < headers.length; i++) {
      const header = headers[i];
      if (!header) continue;
      const cell = values[i];
      const value = cell === null || cell === undefined ? '' : cell.toString().trim();
      if (value) hasValue = true;
      record[header] = value;
    }
    if (hasValue) records.push(record);
  });
  return records;
}

module.exports = { parseXlsxRecords };
