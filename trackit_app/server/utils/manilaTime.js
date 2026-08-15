const MANILA_TIMEZONE = 'Asia/Manila';

// Philippine Standard Time is the system timezone for attendance -- "today"
// must be Manila's calendar date, not the server process's own (likely
// UTC) date, or a clock-in/out near midnight could be filed under the
// wrong day. Intl.DateTimeFormat resolves the real Asia/Manila rule set
// (Node ships full ICU by default, so this needs no extra tzdata
// dependency); 'en-CA' conveniently formats as YYYY-MM-DD.
function todayInManila() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: MANILA_TIMEZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

module.exports = { MANILA_TIMEZONE, todayInManila };
