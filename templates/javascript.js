<script>
// Shared JavaScript for all tabs. index.cgi appends it to every template and
// runs it through HTML::Template, so the texts below come from the language
// file. All data is fetched from ajax.cgi; errors arrive as keys and are
// translated here.

var SM_L = {
	"COMMON.MINISERVER": "<TMPL_VAR COMMON.MINISERVER ESCAPE=JS>",
	"COMMON.LOADING": "<TMPL_VAR COMMON.LOADING ESCAPE=JS>",
	"COMMON.SAVED": "<TMPL_VAR COMMON.SAVED ESCAPE=JS>",
	"COMMON.CANCEL": "<TMPL_VAR COMMON.CANCEL ESCAPE=JS>",
	"COMMON.CLOSE": "<TMPL_VAR COMMON.CLOSE ESCAPE=JS>",
	"COMMON.OPEN_APP": "<TMPL_VAR COMMON.OPEN_APP ESCAPE=JS>",
	"COMMON.OPEN_APP_SHORT": "<TMPL_VAR COMMON.OPEN_APP_SHORT ESCAPE=JS>",
	"COMMON.RETRY": "<TMPL_VAR COMMON.RETRY ESCAPE=JS>",
	"COMMON.AUTORETRY": "<TMPL_VAR COMMON.AUTORETRY ESCAPE=JS>",
	"COMMON.CHECKING": "<TMPL_VAR COMMON.CHECKING ESCAPE=JS>",
	"COMMON.NO": "<TMPL_VAR COMMON.NO ESCAPE=JS>",
	"COMMON.RESET": "<TMPL_VAR COMMON.RESET ESCAPE=JS>",
	"COMMON.MORE": "<TMPL_VAR COMMON.MORE ESCAPE=JS>",
	"COMMON.REACHABLE": "<TMPL_VAR COMMON.REACHABLE ESCAPE=JS>",
	"COMMON.UNREACHABLE": "<TMPL_VAR COMMON.UNREACHABLE ESCAPE=JS>",
	"COMMON.FW": "<TMPL_VAR COMMON.FW ESCAPE=JS>",
	"COMMON.SHOW_PASSWORD": "<TMPL_VAR COMMON.SHOW_PASSWORD ESCAPE=JS>",
	"COMMON.DATE_FMT": "<TMPL_VAR COMMON.DATE_FMT ESCAPE=JS>",
	"COMMON.TODAY": "<TMPL_VAR COMMON.TODAY ESCAPE=JS>",
	"COMMON.SUN": "<TMPL_VAR COMMON.SUN ESCAPE=JS>",
	"COMMON.MON": "<TMPL_VAR COMMON.MON ESCAPE=JS>",
	"COMMON.TUE": "<TMPL_VAR COMMON.TUE ESCAPE=JS>",
	"COMMON.WED": "<TMPL_VAR COMMON.WED ESCAPE=JS>",
	"COMMON.THU": "<TMPL_VAR COMMON.THU ESCAPE=JS>",
	"COMMON.FRI": "<TMPL_VAR COMMON.FRI ESCAPE=JS>",
	"COMMON.SAT": "<TMPL_VAR COMMON.SAT ESCAPE=JS>",
	"COMMON.PILL_WATCH": "<TMPL_VAR COMMON.PILL_WATCH ESCAPE=JS>",
	"COMMON.PILL_WATCH_OFF": "<TMPL_VAR COMMON.PILL_WATCH_OFF ESCAPE=JS>",
	"COMMON.PILL_BACKUP": "<TMPL_VAR COMMON.PILL_BACKUP ESCAPE=JS>",
	"COMMON.PILL_BACKUP_NONE": "<TMPL_VAR COMMON.PILL_BACKUP_NONE ESCAPE=JS>",
	"CARD.SORTINGS": "<TMPL_VAR CARD.SORTINGS ESCAPE=JS>",
	"CARD.SORTINGS_V": "<TMPL_VAR CARD.SORTINGS_V ESCAPE=JS>",
	"CARD.USERS_TABLETS": "<TMPL_VAR CARD.USERS_TABLETS ESCAPE=JS>",
	"CARD.WATCH": "<TMPL_VAR CARD.WATCH ESCAPE=JS>",
	"CARD.WATCH_EVERY": "<TMPL_VAR CARD.WATCH_EVERY ESCAPE=JS>",
	"CARD.WATCH_OFF": "<TMPL_VAR CARD.WATCH_OFF ESCAPE=JS>",
	"CARD.WATCH_LAST": "<TMPL_VAR CARD.WATCH_LAST ESCAPE=JS>",
	"CARD.WATCH_NOTSET": "<TMPL_VAR CARD.WATCH_NOTSET ESCAPE=JS>",
	"CARD.LINK_WATCH": "<TMPL_VAR CARD.LINK_WATCH ESCAPE=JS>",
	"CARD.BACKUP": "<TMPL_VAR CARD.BACKUP ESCAPE=JS>",
	"CARD.BACKUP_SUB": "<TMPL_VAR CARD.BACKUP_SUB ESCAPE=JS>",
	"CARD.BACKUP_NONE": "<TMPL_VAR CARD.BACKUP_NONE ESCAPE=JS>",
	"CARD.LINK_BACKUP": "<TMPL_VAR CARD.LINK_BACKUP ESCAPE=JS>",
	"OVERVIEW.TITLE": "<TMPL_VAR OVERVIEW.TITLE ESCAPE=JS>",
	"OVERVIEW.LEAD": "<TMPL_VAR OVERVIEW.LEAD ESCAPE=JS>",
	"OVERVIEW.FROM": "<TMPL_VAR OVERVIEW.FROM ESCAPE=JS>",
	"OVERVIEW.TO": "<TMPL_VAR OVERVIEW.TO ESCAPE=JS>",
	"OVERVIEW.QUICK_USERS": "<TMPL_VAR OVERVIEW.QUICK_USERS ESCAPE=JS>",
	"OVERVIEW.QUICK_TABLETS": "<TMPL_VAR OVERVIEW.QUICK_TABLETS ESCAPE=JS>",
	"OVERVIEW.QUICK_NONE": "<TMPL_VAR OVERVIEW.QUICK_NONE ESCAPE=JS>",
	"OVERVIEW.NOSOURCE_LIST": "<TMPL_VAR OVERVIEW.NOSOURCE_LIST ESCAPE=JS>",
	"OVERVIEW.TYPE_ADMIN": "<TMPL_VAR OVERVIEW.TYPE_ADMIN ESCAPE=JS>",
	"OVERVIEW.TYPE_USER": "<TMPL_VAR OVERVIEW.TYPE_USER ESCAPE=JS>",
	"OVERVIEW.TYPE_TABLET": "<TMPL_VAR OVERVIEW.TYPE_TABLET ESCAPE=JS>",
	"OVERVIEW.STAND": "<TMPL_VAR OVERVIEW.STAND ESCAPE=JS>",
	"OVERVIEW.NOSORTING": "<TMPL_VAR OVERVIEW.NOSORTING ESCAPE=JS>",
	"OVERVIEW.TOKEN_OK": "<TMPL_VAR OVERVIEW.TOKEN_OK ESCAPE=JS>",
	"OVERVIEW.TOKEN_EXPIRED": "<TMPL_VAR OVERVIEW.TOKEN_EXPIRED ESCAPE=JS>",
	"OVERVIEW.TOKEN_NONE": "<TMPL_VAR OVERVIEW.TOKEN_NONE ESCAPE=JS>",
	"OVERVIEW.METHOD_TOKEN": "<TMPL_VAR OVERVIEW.METHOD_TOKEN ESCAPE=JS>",
	"OVERVIEW.METHOD_REBOOT": "<TMPL_VAR OVERVIEW.METHOD_REBOOT ESCAPE=JS>",
	"OVERVIEW.ORPHANS": "<TMPL_VAR OVERVIEW.ORPHANS ESCAPE=JS>",
	"OVERVIEW.SUM_TARGETS": "<TMPL_VAR OVERVIEW.SUM_TARGETS ESCAPE=JS>",
	"OVERVIEW.SUM_TARGET": "<TMPL_VAR OVERVIEW.SUM_TARGET ESCAPE=JS>",
	"OVERVIEW.SUM_NONE": "<TMPL_VAR OVERVIEW.SUM_NONE ESCAPE=JS>",
	"OVERVIEW.SUM_HINT": "<TMPL_VAR OVERVIEW.SUM_HINT ESCAPE=JS>",
	"OVERVIEW.SUM_NOSOURCE": "<TMPL_VAR OVERVIEW.SUM_NOSOURCE ESCAPE=JS>",
	"OVERVIEW.PW_COUNT1": "<TMPL_VAR OVERVIEW.PW_COUNT1 ESCAPE=JS>",
	"OVERVIEW.PW_COUNTN": "<TMPL_VAR OVERVIEW.PW_COUNTN ESCAPE=JS>",
	"OVERVIEW.REBOOT_TOGGLE": "<TMPL_VAR OVERVIEW.REBOOT_TOGGLE ESCAPE=JS>",
	"OVERVIEW.BTN_SAVE": "<TMPL_VAR OVERVIEW.BTN_SAVE ESCAPE=JS>",
	"OVERVIEW.BTN_COPY": "<TMPL_VAR OVERVIEW.BTN_COPY ESCAPE=JS>",
	"OVERVIEW.PW_FOR": "<TMPL_VAR OVERVIEW.PW_FOR ESCAPE=JS>",
	"OVERVIEW.PW_ONCE": "<TMPL_VAR OVERVIEW.PW_ONCE ESCAPE=JS>",
	"OVERVIEW.NO_ENTRIES": "<TMPL_VAR OVERVIEW.NO_ENTRIES ESCAPE=JS>",
	"OVERVIEW.SAVED_DEFAULT": "<TMPL_VAR OVERVIEW.SAVED_DEFAULT ESCAPE=JS>",
	"COPY.WAIT": "<TMPL_VAR COPY.WAIT ESCAPE=JS>",
	"COPY.RUN": "<TMPL_VAR COPY.RUN ESCAPE=JS>",
	"COPY.OK": "<TMPL_VAR COPY.OK ESCAPE=JS>",
	"COPY.OK_REBOOT": "<TMPL_VAR COPY.OK_REBOOT ESCAPE=JS>",
	"COPY.RUNNING": "<TMPL_VAR COPY.RUNNING ESCAPE=JS>",
	"COPY.DONE_ALL": "<TMPL_VAR COPY.DONE_ALL ESCAPE=JS>",
	"COPY.DONE_PART": "<TMPL_VAR COPY.DONE_PART ESCAPE=JS>",
	"COPY.DONE_AT": "<TMPL_VAR COPY.DONE_AT ESCAPE=JS>",
	"COPY.RETRY": "<TMPL_VAR COPY.RETRY ESCAPE=JS>",
	"COPY.RETRY_N": "<TMPL_VAR COPY.RETRY_N ESCAPE=JS>",
	"COPY.NOTE_REBOOT_TITLE": "<TMPL_VAR COPY.NOTE_REBOOT_TITLE ESCAPE=JS>",
	"COPY.NOTE_REBOOT_BODY": "<TMPL_VAR COPY.NOTE_REBOOT_BODY ESCAPE=JS>",
	"COPY.NOTE_PENDING_TITLE": "<TMPL_VAR COPY.NOTE_PENDING_TITLE ESCAPE=JS>",
	"COPY.NOTE_PENDING_BODY": "<TMPL_VAR COPY.NOTE_PENDING_BODY ESCAPE=JS>",
	"COPY.NOTE_FAIL_TITLE": "<TMPL_VAR COPY.NOTE_FAIL_TITLE ESCAPE=JS>",
	"COPY.NOTE_FAIL_BODY": "<TMPL_VAR COPY.NOTE_FAIL_BODY ESCAPE=JS>",
	"WATCH.TITLE": "<TMPL_VAR WATCH.TITLE ESCAPE=JS>",
	"WATCH.LEAD": "<TMPL_VAR WATCH.LEAD ESCAPE=JS>",
	"WATCH.ACTIVE": "<TMPL_VAR WATCH.ACTIVE ESCAPE=JS>",
	"WATCH.ACTIVE_HOURLY": "<TMPL_VAR WATCH.ACTIVE_HOURLY ESCAPE=JS>",
	"WATCH.ACTIVE_DAILY": "<TMPL_VAR WATCH.ACTIVE_DAILY ESCAPE=JS>",
	"WATCH.OFF": "<TMPL_VAR WATCH.OFF ESCAPE=JS>",
	"WATCH.OFF_SUB": "<TMPL_VAR WATCH.OFF_SUB ESCAPE=JS>",
	"WATCH.NEXT": "<TMPL_VAR WATCH.NEXT ESCAPE=JS>",
	"WATCH.BTN_NOW": "<TMPL_VAR WATCH.BTN_NOW ESCAPE=JS>",
	"WATCH.CHECKING": "<TMPL_VAR WATCH.CHECKING ESCAPE=JS>",
	"WATCH.WATCHED": "<TMPL_VAR WATCH.WATCHED ESCAPE=JS>",
	"WATCH.CHANGE": "<TMPL_VAR WATCH.CHANGE ESCAPE=JS>",
	"WATCH.NOTCONF_TITLE": "<TMPL_VAR WATCH.NOTCONF_TITLE ESCAPE=JS>",
	"WATCH.NOTCONF": "<TMPL_VAR WATCH.NOTCONF ESCAPE=JS>",
	"WATCH.HIST_EMPTY": "<TMPL_VAR WATCH.HIST_EMPTY ESCAPE=JS>",
	"WATCH.H_UNCHANGED": "<TMPL_VAR WATCH.H_UNCHANGED ESCAPE=JS>",
	"WATCH.H_CHANGED": "<TMPL_VAR WATCH.H_CHANGED ESCAPE=JS>",
	"WATCH.H_CHANGED_ALL": "<TMPL_VAR WATCH.H_CHANGED_ALL ESCAPE=JS>",
	"WATCH.H_CHANGED_ONE": "<TMPL_VAR WATCH.H_CHANGED_ONE ESCAPE=JS>",
	"WATCH.H_REBOOT_PENDING": "<TMPL_VAR WATCH.H_REBOOT_PENDING ESCAPE=JS>",
	"WATCH.H_REBOOT_DONE": "<TMPL_VAR WATCH.H_REBOOT_DONE ESCAPE=JS>",
	"WATCH.H_MANUAL": "<TMPL_VAR WATCH.H_MANUAL ESCAPE=JS>",
	"WATCH.SETTINGS": "<TMPL_VAR WATCH.SETTINGS ESCAPE=JS>",
	"WATCH.INTERVAL": "<TMPL_VAR WATCH.INTERVAL ESCAPE=JS>",
	"WATCH.I5": "<TMPL_VAR WATCH.I5 ESCAPE=JS>",
	"WATCH.I15": "<TMPL_VAR WATCH.I15 ESCAPE=JS>",
	"WATCH.I30": "<TMPL_VAR WATCH.I30 ESCAPE=JS>",
	"WATCH.I60": "<TMPL_VAR WATCH.I60 ESCAPE=JS>",
	"WATCH.I1440": "<TMPL_VAR WATCH.I1440 ESCAPE=JS>",
	"WATCH.TABLETS": "<TMPL_VAR WATCH.TABLETS ESCAPE=JS>",
	"WATCH.RB_NOTIFY": "<TMPL_VAR WATCH.RB_NOTIFY ESCAPE=JS>",
	"WATCH.RB_NOTIFY_SUB": "<TMPL_VAR WATCH.RB_NOTIFY_SUB ESCAPE=JS>",
	"WATCH.RB_AUTO": "<TMPL_VAR WATCH.RB_AUTO ESCAPE=JS>",
	"WATCH.RB_AUTO_SUB": "<TMPL_VAR WATCH.RB_AUTO_SUB ESCAPE=JS>",
	"BACKUP.TITLE": "<TMPL_VAR BACKUP.TITLE ESCAPE=JS>",
	"BACKUP.LEAD": "<TMPL_VAR BACKUP.LEAD ESCAPE=JS>",
	"BACKUP.NEXT": "<TMPL_VAR BACKUP.NEXT ESCAPE=JS>",
	"BACKUP.NEXT_OFF": "<TMPL_VAR BACKUP.NEXT_OFF ESCAPE=JS>",
	"BACKUP.NEXT_OFF_SUB": "<TMPL_VAR BACKUP.NEXT_OFF_SUB ESCAPE=JS>",
	"BACKUP.NEXT_NONE": "<TMPL_VAR BACKUP.NEXT_NONE ESCAPE=JS>",
	"BACKUP.NEXT_NONE_SUB": "<TMPL_VAR BACKUP.NEXT_NONE_SUB ESCAPE=JS>",
	"BACKUP.IN_HOURS": "<TMPL_VAR BACKUP.IN_HOURS ESCAPE=JS>",
	"BACKUP.IN_DAYS": "<TMPL_VAR BACKUP.IN_DAYS ESCAPE=JS>",
	"BACKUP.KEEP": "<TMPL_VAR BACKUP.KEEP ESCAPE=JS>",
	"BACKUP.KEEP_V": "<TMPL_VAR BACKUP.KEEP_V ESCAPE=JS>",
	"BACKUP.KEEP_SUB": "<TMPL_VAR BACKUP.KEEP_SUB ESCAPE=JS>",
	"BACKUP.SPACE": "<TMPL_VAR BACKUP.SPACE ESCAPE=JS>",
	"BACKUP.SPACE_FREE": "<TMPL_VAR BACKUP.SPACE_FREE ESCAPE=JS>",
	"BACKUP.BTN_NOW": "<TMPL_VAR BACKUP.BTN_NOW ESCAPE=JS>",
	"BACKUP.RUNNING": "<TMPL_VAR BACKUP.RUNNING ESCAPE=JS>",
	"BACKUP.DONE": "<TMPL_VAR BACKUP.DONE ESCAPE=JS>",
	"BACKUP.SCHED": "<TMPL_VAR BACKUP.SCHED ESCAPE=JS>",
	"BACKUP.SCHED_ON": "<TMPL_VAR BACKUP.SCHED_ON ESCAPE=JS>",
	"BACKUP.WHEN": "<TMPL_VAR BACKUP.WHEN ESCAPE=JS>",
	"BACKUP.TIME": "<TMPL_VAR BACKUP.TIME ESCAPE=JS>",
	"BACKUP.REPEAT": "<TMPL_VAR BACKUP.REPEAT ESCAPE=JS>",
	"BACKUP.REP1": "<TMPL_VAR BACKUP.REP1 ESCAPE=JS>",
	"BACKUP.REPN": "<TMPL_VAR BACKUP.REPN ESCAPE=JS>",
	"BACKUP.KEEP_LBL": "<TMPL_VAR BACKUP.KEEP_LBL ESCAPE=JS>",
	"BACKUP.KEEP_OPT": "<TMPL_VAR BACKUP.KEEP_OPT ESCAPE=JS>",
	"BACKUP.KEEP_HINT": "<TMPL_VAR BACKUP.KEEP_HINT ESCAPE=JS>",
	"BACKUP.NODAYS": "<TMPL_VAR BACKUP.NODAYS ESCAPE=JS>",
	"BACKUP.ARCHIVES": "<TMPL_VAR BACKUP.ARCHIVES ESCAPE=JS>",
	"BACKUP.COUNT": "<TMPL_VAR BACKUP.COUNT ESCAPE=JS>",
	"BACKUP.NONE_YET": "<TMPL_VAR BACKUP.NONE_YET ESCAPE=JS>",
	"BACKUP.T_SCHEDULE": "<TMPL_VAR BACKUP.T_SCHEDULE ESCAPE=JS>",
	"BACKUP.T_MANUAL": "<TMPL_VAR BACKUP.T_MANUAL ESCAPE=JS>",
	"BACKUP.ENTRIES": "<TMPL_VAR BACKUP.ENTRIES ESCAPE=JS>",
	"BACKUP.MISSING1": "<TMPL_VAR BACKUP.MISSING1 ESCAPE=JS>",
	"BACKUP.MISSINGN": "<TMPL_VAR BACKUP.MISSINGN ESCAPE=JS>",
	"BACKUP.PICK": "<TMPL_VAR BACKUP.PICK ESCAPE=JS>",
	"BACKUP.SAVED_AT": "<TMPL_VAR BACKUP.SAVED_AT ESCAPE=JS>",
	"BACKUP.NOW_AT": "<TMPL_VAR BACKUP.NOW_AT ESCAPE=JS>",
	"BACKUP.NOW_NONE": "<TMPL_VAR BACKUP.NOW_NONE ESCAPE=JS>",
	"BACKUP.GONE": "<TMPL_VAR BACKUP.GONE ESCAPE=JS>",
	"BACKUP.DELETE": "<TMPL_VAR BACKUP.DELETE ESCAPE=JS>",
	"BACKUP.DELETE_ASK": "<TMPL_VAR BACKUP.DELETE_ASK ESCAPE=JS>",
	"BACKUP.BTN_DELETE": "<TMPL_VAR BACKUP.BTN_DELETE ESCAPE=JS>",
	"BACKUP.BTN_RESTORE": "<TMPL_VAR BACKUP.BTN_RESTORE ESCAPE=JS>",
	"BACKUP.R_WAIT": "<TMPL_VAR BACKUP.R_WAIT ESCAPE=JS>",
	"BACKUP.R_RUN": "<TMPL_VAR BACKUP.R_RUN ESCAPE=JS>",
	"BACKUP.R_OK": "<TMPL_VAR BACKUP.R_OK ESCAPE=JS>",
	"BACKUP.R_OK_REBOOT": "<TMPL_VAR BACKUP.R_OK_REBOOT ESCAPE=JS>",
	"BACKUP.R_DONE_TITLE": "<TMPL_VAR BACKUP.R_DONE_TITLE ESCAPE=JS>",
	"BACKUP.R_NOTHING": "<TMPL_VAR BACKUP.R_NOTHING ESCAPE=JS>",
	"ERR.NOTREACHABLE": "<TMPL_VAR ERR.NOTREACHABLE ESCAPE=JS>",
	"ERR.NOCREDENTIALS": "<TMPL_VAR ERR.NOCREDENTIALS ESCAPE=JS>",
	"ERR.BADCREDENTIALS": "<TMPL_VAR ERR.BADCREDENTIALS ESCAPE=JS>",
	"ERR.VERIFYFAILED": "<TMPL_VAR ERR.VERIFYFAILED ESCAPE=JS>",
	"ERR.NOTFOUND": "<TMPL_VAR ERR.NOTFOUND ESCAPE=JS>",
	"ERR.BADPATH": "<TMPL_VAR ERR.BADPATH ESCAPE=JS>",
	"ERR.JOBRUNNING": "<TMPL_VAR ERR.JOBRUNNING ESCAPE=JS>",
	"ERR.NOBACKUPDIR": "<TMPL_VAR ERR.NOBACKUPDIR ESCAPE=JS>",
	"ERR.UNKNOWNACTION": "<TMPL_VAR ERR.UNKNOWNACTION ESCAPE=JS>",
	"ERR.FTPFAILED": "<TMPL_VAR ERR.FTPFAILED ESCAPE=JS>",
	"ERR.NOTCONFIGURED": "<TMPL_VAR ERR.NOTCONFIGURED ESCAPE=JS>",
	"ERR.POSTREQUIRED": "<TMPL_VAR ERR.POSTREQUIRED ESCAPE=JS>",
	"ERR.BADDATA": "<TMPL_VAR ERR.BADDATA ESCAPE=JS>",
	"ERR.SAVEFAILED": "<TMPL_VAR ERR.SAVEFAILED ESCAPE=JS>",
	"ERR.NOTARGETS": "<TMPL_VAR ERR.NOTARGETS ESCAPE=JS>",
	"ERR.NOSOURCE": "<TMPL_VAR ERR.NOSOURCE ESCAPE=JS>",
	"ERR.NOMSNR": "<TMPL_VAR ERR.NOMSNR ESCAPE=JS>",
	"ERR.FORKFAILED": "<TMPL_VAR ERR.FORKFAILED ESCAPE=JS>",
	"ERR.NOJOBDIR": "<TMPL_VAR ERR.NOJOBDIR ESCAPE=JS>",
	"ERR.MISSINGINARCHIVE": "<TMPL_VAR ERR.MISSINGINARCHIVE ESCAPE=JS>",
	"ERR.NOMINISERVER": "<TMPL_VAR ERR.NOMINISERVER ESCAPE=JS>",
	"ERR.CONNECTION": "<TMPL_VAR ERR.CONNECTION ESCAPE=JS>",
	"ERR.UNREACHABLE": "<TMPL_VAR ERR.UNREACHABLE ESCAPE=JS>",
	"ERR.PARSEERROR": "<TMPL_VAR ERR.PARSEERROR ESCAPE=JS>",
	"ERR.HTTPERROR": "<TMPL_VAR ERR.HTTPERROR ESCAPE=JS>",
	"ERR.NOPASSWORD": "<TMPL_VAR ERR.NOPASSWORD ESCAPE=JS>",
	"ERR.NOTOKEN": "<TMPL_VAR ERR.NOTOKEN ESCAPE=JS>",
	"ERR.REVOKED": "<TMPL_VAR ERR.REVOKED ESCAPE=JS>",
	"ERR.MISSINGRIGHT": "<TMPL_VAR ERR.MISSINGRIGHT ESCAPE=JS>",
	"ERR.MSNOTFOUND": "<TMPL_VAR ERR.MSNOTFOUND ESCAPE=JS>",
	"ERR.FWTOOOLD": "<TMPL_VAR ERR.FWTOOOLD ESCAPE=JS>",
	"ERR.WRITEFAILED": "<TMPL_VAR ERR.WRITEFAILED ESCAPE=JS>",
	"ERR.DELETEFAILED": "<TMPL_VAR ERR.DELETEFAILED ESCAPE=JS>",
	"ERR.UNREADABLE": "<TMPL_VAR ERR.UNREADABLE ESCAPE=JS>",
	"ERR.NOMANIFEST": "<TMPL_VAR ERR.NOMANIFEST ESCAPE=JS>",
	"ERR.INVENTORYFAILED": "<TMPL_VAR ERR.INVENTORYFAILED ESCAPE=JS>",
	"ERR.UNKNOWN": "<TMPL_VAR ERR.UNKNOWN ESCAPE=JS>"
};

(function ($) {
"use strict";

// ======================================================================
// Basics
// ======================================================================

// Text with %s/%d filled in order
function T(key) {
	var s = SM_L[key];
	if (s === undefined) { return key; }
	var args = Array.prototype.slice.call(arguments, 1), i = 0;
	return s.replace(/%[sd]/g, function () { var a = args[i++]; return a === undefined ? "" : String(a); });
}
function esc(s) {
	return String(s === null || s === undefined ? "" : s)
		.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function errText(key) {
	var k = "ERR." + String(key || "unknown").toUpperCase();
	return SM_L[k] || (SM_L["ERR.UNKNOWN"] + " (" + esc(key) + ")");
}
function smGet(action, params) {
	params = $.extend({ action: action }, params || {});
	return $.ajax({ url: "ajax.cgi", type: "GET", data: params, dataType: "json", cache: false });
}
function smPost(action, params) {
	params = $.extend({ action: action }, params || {});
	return $.ajax({ url: "ajax.cgi", type: "POST", data: params, dataType: "json" });
}
// jQuery promise that never rejects: failed requests become { ok: 0 }
function safe(p) {
	var d = $.Deferred();
	p.done(function (r) { d.resolve(r || { ok: 0, error: "unknown" }); })
	 .fail(function () { d.resolve({ ok: 0, error: "connection" }); });
	return d.promise();
}

var FORM = $("#sm-page").data("form");
var MSNR = null;

function url(form) { return "index.cgi?form=" + form + (MSNR ? "&msnr=" + MSNR : ""); }

function pad(n) { return (n < 10 ? "0" : "") + n; }
// "YYYY-MM-DD HH:MM" (from ajax.cgi) or a Date -> localized; today shows "heute HH:MM"
function fmt(v) {
	if (!v) { return "–"; }
	var d = v instanceof Date ? v : null;
	if (!d) {
		var m = String(v).match(/^(\d{4})-(\d\d)-(\d\d)[ T](\d\d):(\d\d)/);
		if (!m) { return esc(v); }
		d = new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]);
	}
	var now = new Date(), time = pad(d.getHours()) + ":" + pad(d.getMinutes());
	if (d.toDateString() === now.toDateString()) { return T("COMMON.TODAY") + " " + time; }
	return T("COMMON.DATE_FMT").replace("DD", pad(d.getDate())).replace("MM", pad(d.getMonth() + 1))
		.replace("YYYY", d.getFullYear()) + " " + time;
}
function fmtDay(v) { return fmt(v).replace(/ \d\d:\d\d$/, ""); }
// Seconds since 2009-01-01 UTC
function lox2date(lox) { return lox ? new Date((Date.UTC(2009, 0, 1) / 1000 + Number(lox)) * 1000) : null; }
function size(bytes) {
	if (bytes === null || bytes === undefined) { return "–"; }
	var u = ["B", "kB", "MB", "GB", "TB"], i = 0, n = Number(bytes);
	while (n >= 1000 && i < u.length - 1) { n /= 1000; i++; }
	return n.toLocaleString(undefined, { maximumFractionDigits: (i > 1 ? 1 : 0) }) + " " + u[i];
}

function pill(kind, html) { return '<span class="sm-pill ' + (kind || "") + '">' + html + "</span>"; }
var STATE_ICON = { wait: "pi-clock", run: "pi-spin pi-spinner", ok: "pi-check-circle", err: "pi-times-circle" };
function state(kind, text) { return '<span class="sm-state ' + kind + '"><i class="pi ' + STATE_ICON[kind] + '"></i>' + text + "</span>"; }
function callout(kind, title, body, closable) {
	return '<div class="lb-callout ' + (kind || "") + ' sm-note' + (closable ? " has-close" : "") + '"><span class="lb-callout-title">' + title + "</span>" +
		(body ? "<p>" + body + "</p>" : "") +
		(closable ? '<button type="button" class="sm-close" data-close aria-label="' + esc(T("COMMON.CLOSE")) + '" title="' + esc(T("COMMON.CLOSE")) + '"><i class="pi pi-times"></i></button>' : "") +
		"</div>";
}
function errorBox($el, key) { $el.html(callout("lb-callout-warning", errText(key), "", true)); }
$(document).on("click", "[data-close]", function () { $(this).closest(".sm-note").remove(); });

// A page that could not load its data. Reload by button; when the Miniserver
// itself is the reason - typically while it reboots - ask it every ten seconds
// and reload as soon as it answers, so the message goes away by itself.
var REACH_KEYS = ["unreachable", "notreachable", "connection", "ftpfailed", "parseerror", "httperror", "inventoryfailed"];
var reachTimer = null;
function loadError($el, key) {
	var auto = REACH_KEYS.indexOf(String(key)) >= 0;
	$el.html('<div class="lb-callout lb-callout-warning sm-note"><span class="lb-callout-title">' + errText(key) + "</span>" +
		(auto ? "<p>" + esc(T("COMMON.AUTORETRY")) + "</p>" : "") +
		'<div class="sm-retry"><button type="button" class="lb-btn lb-btn-sm" data-retry><i class="pi pi-refresh"></i> ' + esc(T("COMMON.RETRY")) +
		'</button><span class="sm-sub" data-retry-state></span></div></div>');
	if (auto && !reachTimer) {
		reachTimer = setInterval(function () {
			$("[data-retry-state]").text(T("COMMON.CHECKING"));
			safe(smGet("reach", { msnr: MSNR })).done(function (r) {
				if (r.ok) { clearInterval(reachTimer); location.reload(); return; }
				$("[data-retry-state]").text("");
			});
		}, 10000);
	}
}
$(document).on("click", "[data-retry]", function () {
	$(this).prop("disabled", true).find("i").attr("class", "pi pi-spin pi-spinner");
	location.reload();
});

// Password field with the eye button known from the core (mailserver.html)
function pwField(id, name, value) {
	// data-pw, not the type, finds the field again: the eye turns it into type=text
	return '<div class="sm-pw"><input class="lb-input" type="password" data-pw id="' + id + '" autocomplete="new-password"' +
		' placeholder="' + esc(T("OVERVIEW.PW_FOR", name)) + '" aria-label="' + esc(T("OVERVIEW.PW_FOR", name)) + '"' +
		(value ? ' value="' + esc(value) + '"' : "") + ">" +
		'<button type="button" class="lb-btn lb-btn-sm lb-btn-icon" data-eye="' + id + '" title="' + esc(T("COMMON.SHOW_PASSWORD")) +
		'"><i class="pi pi-eye"></i></button></div>';
}
$(document).on("click", "[data-eye]", function () {
	var f = document.getElementById($(this).data("eye"));
	if (!f) { return; }
	var show = f.type === "password";
	f.type = show ? "text" : "password";
	$(this).find("i").attr("class", "pi " + (show ? "pi-eye-slash" : "pi-eye"));
});

function toast($el, errKey) {
	clearTimeout($el.data("t"));
	if (errKey) {
		$el.addClass("err on").html('<i class="pi pi-times-circle"></i>' + errText(errKey));
		return;
	}
	$el.removeClass("err").html('<i class="pi pi-check"></i>' + T("COMMON.SAVED")).addClass("on");
	$el.data("t", setTimeout(function () { $el.removeClass("on"); }, 1600));
}

// Settings save themselves: every change posts the branch, debounced
function autoSave(dataFn, $toast) {
	var timer = null;
	return function () {
		clearTimeout(timer);
		timer = setTimeout(function () {
			safe(smPost("saveconfig", { msnr: MSNR, data: JSON.stringify(dataFn()) })).done(function (r) {
				toast($toast, r.ok ? null : r.error);
			});
		}, 400);
	};
}

// ======================================================================
// Miniserver selection
// ======================================================================

function loadMiniservers() {
	return safe(smGet("miniservers")).then(function (r) {
		var list = (r.ok && r.miniservers) || [];
		var want = (location.search.match(/[?&]msnr=(\d+)/) || [])[1];
		var cur = null;
		$.each(list, function (i, m) { if (String(m.msnr) === want) { cur = m; } });
		cur = cur || list[0] || null;
		MSNR = cur ? cur.msnr : null;
		return { list: list, cur: cur };
	});
}
function go(n) { location.href = "index.cgi?form=" + FORM + "&msnr=" + encodeURIComponent(n); }
function reachPill(m, withFw) {
	if (m && m.serial) {
		return pill("ok", '<span class="sm-dot"></span>' + esc(T("COMMON.REACHABLE")) +
			(withFw && m.firmware ? " · " + esc(T("COMMON.FW", m.firmware)) : ""));
	}
	return pill("err", '<span class="sm-dot bad"></span>' + esc(T("COMMON.UNREACHABLE")));
}
function msSelect(ms) {
	return '<select class="lb-select" id="ms-select" data-role="none" aria-label="' + esc(T("COMMON.MINISERVER")) + '">' +
		$.map(ms.list, function (m) {
			return '<option value="' + esc(m.msnr) + '"' + (ms.cur && m.msnr === ms.cur.msnr ? " selected" : "") + ">" + esc(m.name || m.msnr) + "</option>";
		}).join("") + "</select>";
}
$(document).on("change", "#ms-select", function () { go($(this).val()); });
$(document).on("change", "input[name=ms-radio]", function () { go($(this).val()); });

// Overview: button group for two to four Miniservers, a select beyond that
function renderSwitch($el, ms) {
	var pick = "";
	if (ms.list.length > 4) { pick = msSelect(ms); }
	else if (ms.list.length > 1) {
		pick = '<div class="lb-btn-group" role="radiogroup" aria-label="' + esc(T("COMMON.MINISERVER")) + '">' +
			$.map(ms.list, function (m) {
				var id = "ms-r" + esc(m.msnr);
				return '<input type="radio" name="ms-radio" id="' + id + '" value="' + esc(m.msnr) + '"' +
					(ms.cur && m.msnr === ms.cur.msnr ? " checked" : "") + '><label for="' + id + '">' + esc(m.name || m.msnr) + "</label>";
			}).join("") + "</div>";
	}
	// Choose, then open: the app button sits right next to the choice
	$el.html('<span class="sm-pick">' + pick + appButton(ms.cur) + "</span>");
}
// Watch and backup: one row with select, reachability and one more pill
function renderContext($el, ms, rightHtml) {
	$el.html('<span class="sm-pick"><label class="sm-ctx-ms"><i class="pi pi-server"></i>' + msSelect(ms) + "</label>" + appButton(ms.cur) + "</span>" +
		reachPill(ms.cur, true) + '<div class="sm-ctx-right">' + (rightHtml || "") + "</div>");
}
// Deeplink into the Loxone App, built like exo.loxone.com does it: the serial
// as twelve hex digits. Without a valid serial no button - it could never work.
function appButton(m) {
	var mac = String((m && m.serial) || "").replace(/[^0-9A-Fa-f]/g, "").toUpperCase();
	if (mac.length !== 12) { return ""; }
	return '<a class="lb-btn lb-btn-icon sm-app" href="loxone://ms?mac=' + mac + '" title="' + esc(T("COMMON.OPEN_APP")) +
		'" aria-label="' + esc(T("COMMON.OPEN_APP")) + '"><i class="pi pi-external-link"></i>' + esc(T("COMMON.OPEN_APP_SHORT")) + "</a>";
}
function lastBackup(list) {
	var b = (list || [])[0];
	return b ? fmt(b.created_local) : null;
}

// ======================================================================
// Jobs: copy, backup, restore run detached; the page polls their state
// ======================================================================

function poll(onTick, onDone) {
	(function tick() {
		safe(smGet("jobstatus")).done(function (r) {
			var j = (r.ok && r.job) || {};
			if (!r.ok) { setTimeout(tick, 3000); return; }
			onTick(j);
			if (!j.state || j.state === "done") { onDone(j); return; }
			setTimeout(tick, 1500);
		});
	})();
}
function jobStart(action, params, onTick, onDone, onErr) {
	safe(smPost(action, $.extend({ msnr: MSNR }, params))).done(function (r) {
		if (!r.ok) { onErr(r.error); return; }
		poll(onTick, onDone);
	});
}
// A job may already run - started in another tab or by the watch
function jobResume(kinds, onStart, onTick, onDone) {
	safe(smGet("jobstatus")).done(function (r) {
		var j = (r.ok && r.job) || {};
		if (j.state && j.state !== "done" && kinds.indexOf(j.kind) >= 0 && String(j.msnr) === String(MSNR)) {
			onStart(j);
			poll(onTick, onDone);
		}
	});
}
// Per-entry state from a job: wait, run, ok, okr (written, waiting for reboot), err
function entryState(j, uuid, isTablet) {
	var res = null;
	$.each(j.results || [], function (i, x) { if (x.uuid === uuid) { res = x; } });
	if (res) {
		if (!res.ok) { return { s: "err", error: res.error }; }
		return { s: (isTablet && !j.reboot_ok) ? "okr" : "ok" };
	}
	return { s: j.current === uuid ? "run" : "wait" };
}

var TYPE = { admin: "OVERVIEW.TYPE_ADMIN", user: "OVERVIEW.TYPE_USER", tablet: "OVERVIEW.TYPE_TABLET" };
function typeText(t) { return T(TYPE[t] || "OVERVIEW.TYPE_USER"); }
function tokenPill(state) {
	if (state === "ok") { return pill("ok", esc(T("OVERVIEW.TOKEN_OK"))); }
	if (state === "expired") { return pill("warn", esc(T("OVERVIEW.TOKEN_EXPIRED"))); }
	if (state === "none") { return pill("none", esc(T("OVERVIEW.TOKEN_NONE"))); }
	return "";
}

// ======================================================================
// Overview
// ======================================================================

function overview() {
	var S = {
		ms: null, inv: [], orphans: [], tok: {}, tokLoaded: false, watch: null, backups: [],
		src: null, tgt: {}, meth: {}, pw: {}, status: {}, errs: {}, runSet: {},
		phase: "idle", job: null, reboot: false, ok: true
	};

	function byUuid(u) { var e = null; $.each(S.inv, function (i, x) { if (x.uuid === u) { e = x; } }); return e; }
	function isTablet(e) { return e.type === "tablet"; }
	function way(e) { return isTablet(e) ? "reboot" : (S.meth[e.uuid] || "token"); }
	function targets() { return $.grep(S.inv, function (e) { return S.tgt[e.uuid] && e.uuid !== S.src; }); }
	function needsPw(e) { return !isTablet(e) && way(e) === "token" && S.tokLoaded && S.tok[e.uuid] !== "ok"; }
	function keepPw() { $("#ov-tgt input[data-pw]").each(function () { S.pw[this.id] = this.value; }); }

	function card() {
		var m = S.ms.cur;
		if (!m) { $("#ov-card").empty(); return; }
		var users = $.grep(S.inv, function (e) { return !isTablet(e); }).length;
		var tabs = S.inv.length - users;
		var withSort = $.grep(S.inv, function (e) { return e.has_sorting; }).length;
		var w = S.watch && S.watch.watch;
		var watchV = !S.watch ? "–" : (!S.watch.source ? T("CARD.WATCH_NOTSET") : (w && w.enabled ? T("CARD.WATCH_EVERY", w.interval_min) : T("CARD.WATCH_OFF")));
		var watchSub = S.watch && S.watch.last_run_local ? T("CARD.WATCH_LAST", fmt(S.watch.last_run_local)) : "";
		var total = 0; $.each(S.backups, function (i, b) { total += Number(b.bytes || 0); });
		var lb = lastBackup(S.backups);
		$("#ov-card").html('<div class="lb-card sm-card">' +
			'<div><div class="sm-card-name"><span class="sm-dot' + (m.serial ? "" : " bad") + '"></span>' + esc(m.name || m.msnr) + "</div>" +
				'<span class="sm-sub sm-tnum">' + esc(m.host || "") + (m.firmware ? " · " + esc(T("COMMON.FW", m.firmware)) : "") + "</span>" +
				"<div>" + reachPill(m, false) + "</div></div>" +
			'<div><span class="sm-k">' + esc(T("CARD.SORTINGS")) + '</span><span class="sm-v">' + (S.ok ? esc(T("CARD.SORTINGS_V", withSort, S.inv.length)) : "–") + "</span>" +
				'<span class="sm-sub">' + (S.ok ? esc(T("CARD.USERS_TABLETS", users, tabs)) : "") + "</span></div>" +
			'<div><span class="sm-k">' + esc(T("CARD.WATCH")) + '</span><span class="sm-v">' + esc(watchV) + "</span>" +
				'<span class="sm-sub">' + esc(watchSub) + '</span><a class="sm-link" href="' + url("watch") + '">' + esc(T("CARD.LINK_WATCH")) + "</a></div>" +
			'<div><span class="sm-k">' + esc(T("CARD.BACKUP")) + '</span><span class="sm-v">' + esc(lb || T("CARD.BACKUP_NONE")) + "</span>" +
				'<span class="sm-sub">' + (lb ? esc(T("CARD.BACKUP_SUB", S.backups.length, size(total))) : "") + '</span><a class="sm-link" href="' + url("backup") + '">' + esc(T("CARD.LINK_BACKUP")) + "</a></div>" +
			"</div>");
	}

	function slot(e) {
		var st = S.status[e.uuid];
		var id = "ov-pw-" + e.uuid;
		if (st) {
			var text = { wait: T("COPY.WAIT"), run: T("COPY.RUN"), ok: T("COPY.OK"), okr: T("COPY.OK_REBOOT"), err: errText(S.errs[e.uuid]) }[st];
			var html = state(st === "okr" ? "ok" : st, esc(text));
			if (st === "err" && (S.errs[e.uuid] === "badcredentials" || S.errs[e.uuid] === "nocredentials")) {
				html += pwField(id, e.name, S.pw[id]);
			}
			return html;
		}
		if (S.phase === "idle" && S.tgt[e.uuid] && needsPw(e)) {
			return pwField(id, e.name, S.pw[id]) + '<span class="sm-sub" style="margin-top:4px">' + esc(T("OVERVIEW.PW_ONCE")) + "</span>";
		}
		return "";
	}

	function lists() {
		keepPw();
		var lock = S.phase === "run" ? " disabled" : "";
		var srcs = $.grep(S.inv, function (e) { return e.has_sorting; });
		$("#ov-quick").toggle(S.ok && S.inv.length > 0);
		if (!S.ok) { $("#ov-src, #ov-tgt, #ov-src-off").empty(); return; }
		if (!S.inv.length) { $("#ov-src").html('<p class="sm-muted">' + esc(T("OVERVIEW.NO_ENTRIES")) + "</p>"); $("#ov-tgt").empty(); return; }
		$("#ov-src").html($.map(srcs, function (e) {
			return '<label class="sm-opt"><input type="radio" name="ov-src" value="' + esc(e.uuid) + '"' + (S.src === e.uuid ? " checked" : "") + lock + ">" +
				'<span class="nm">' + esc(e.name) + '</span><span class="meta">' + esc(typeText(e.type)) + " · " + fmt(e.ts_local) + "</span></label>";
		}).join(""));
		var off = $.grep(S.inv, function (e) { return !e.has_sorting; });
		$("#ov-src-off").text(off.length ? T("OVERVIEW.NOSOURCE_LIST", $.map(off, function (e) { return e.name; }).join(", ")) : "");
		$("#ov-tgt").html($.map($.grep(S.inv, function (e) { return e.uuid !== S.src; }), function (e) {
			var id = "ov-t-" + e.uuid, w = way(e), right;
			if (isTablet(e)) {
				right = pill("", esc(T("OVERVIEW.METHOD_REBOOT")));
			} else {
				right = '<span class="lb-btn-group">' +
					'<input type="radio" name="ov-w-' + esc(e.uuid) + '" id="' + id + '-t" value="token" data-way="' + esc(e.uuid) + '"' + (w === "token" ? " checked" : "") + lock + '><label for="' + id + '-t">' + esc(T("OVERVIEW.METHOD_TOKEN")) + "</label>" +
					'<input type="radio" name="ov-w-' + esc(e.uuid) + '" id="' + id + '-r" value="reboot" data-way="' + esc(e.uuid) + '"' + (w === "reboot" ? " checked" : "") + lock + '><label for="' + id + '-r">' + esc(T("OVERVIEW.METHOD_REBOOT")) + "</label>" +
					"</span>" + tokenPill(S.tok[e.uuid]);
			}
			return '<div class="sm-opt' + (S.status[e.uuid] === "err" ? " st-err" : "") + '"><input type="checkbox" id="' + id + '" value="' + esc(e.uuid) + '" data-tgt' + (S.tgt[e.uuid] ? " checked" : "") + lock + ">" +
				'<label for="' + id + '" class="nm">' + esc(e.name) + "</label>" +
				'<span class="right">' + right + "</span>" +
				'<span class="meta">' + esc(typeText(e.type)) + " · " + (e.has_sorting ? esc(T("OVERVIEW.STAND", fmt(e.ts_local))) : esc(T("OVERVIEW.NOSORTING"))) + "</span>" +
				'<div class="slot">' + slot(e) + "</div></div>";
		}).join(""));
		$("#ov-tgt input[data-pw]").each(function () { if (S.pw[this.id]) { this.value = S.pw[this.id]; } });
		$("#ov-quick button").prop("disabled", S.phase === "run");
	}

	function bar() {
		var t = targets(), $b = $("#ov-bar");
		if (!S.ok) { $b.hide(); return; }
		$b.show();
		if (S.phase === "run") {
			var j = S.job || {}, done = j.done || 0, total = j.total || t.length || 1;
			$b.html('<div class="sm-sum"><strong>' + esc(T("COPY.RUNNING", done, total)) + '</strong><div class="sm-prog"><i style="width:' + Math.round(done / total * 100) + '%"></i></div></div>');
			return;
		}
		if (S.phase === "done") {
			var j2 = S.job || {}, res = j2.results || [], failed = $.grep(res, function (x) { return !x.ok; });
			var head = failed.length ? T("COPY.DONE_PART", res.length - failed.length, res.length) : T("COPY.DONE_ALL", res.length);
			var src = byUuid(j2.source);
			$b.html('<div class="sm-sum"><strong>' + esc(head) + "</strong><span>" + esc(T("COPY.DONE_AT", fmt(new Date()).replace(/^.* /, ""), src ? src.name : "")) + "</span></div>" +
				'<div class="lb-actions">' + (failed.length ? '<button type="button" class="lb-btn lb-btn-primary" id="ov-retry">' +
					esc(failed.length === 1 ? T("COPY.RETRY", failed[0].name) : T("COPY.RETRY_N")) + "</button>" : "") +
				'<button type="button" class="lb-btn" id="ov-reset">' + esc(T("COMMON.RESET")) + "</button></div>");
			return;
		}
		var src2 = byUuid(S.src);
		var pw = $.grep(t, needsPw).length;
		var rb = $.grep(t, function (e) { return way(e) === "reboot"; }).length > 0;
		var head2 = !src2 ? T("OVERVIEW.SUM_NOSOURCE") : !t.length ? T("OVERVIEW.SUM_NONE") : t.length === 1 ? T("OVERVIEW.SUM_TARGET", src2.name) : T("OVERVIEW.SUM_TARGETS", src2.name, t.length);
		var sub = t.length ? $.map(t, function (e) { return e.name; }).join(", ") : T("OVERVIEW.SUM_HINT");
		if (pw) { sub += " · " + (pw === 1 ? T("OVERVIEW.PW_COUNT1") : T("OVERVIEW.PW_COUNTN", pw)); }
		$b.html('<div class="sm-sum"><strong>' + esc(head2) + "</strong><span>" + esc(sub) + "</span></div>" +
			(rb ? '<div class="sm-reboot"><label class="lb-toggle"><input type="checkbox" id="ov-rb"' + (S.reboot ? " checked" : "") + '><span class="lb-toggle-slider"></span></label><label for="ov-rb">' + esc(T("OVERVIEW.REBOOT_TOGGLE")) + "</label></div>" : "") +
			'<span class="sm-toast" id="ov-toast" role="status"></span>' +
			'<div class="lb-actions"><button type="button" class="lb-btn" id="ov-save"' + (src2 && t.length ? "" : " disabled") + ">" + esc(T("OVERVIEW.BTN_SAVE")) + "</button>" +
			'<button type="button" class="lb-btn lb-btn-primary" id="ov-copy"' + (src2 && t.length ? "" : " disabled") + '><i class="pi pi-copy"></i> ' + esc(T("OVERVIEW.BTN_COPY")) + "</button></div>");
	}

	function notes() {
		var j = S.job, html = "";
		if (S.phase !== "done" || !j) { $("#ov-notes").empty(); return; }
		var wroteTablet = $.grep(j.results || [], function (x) { return x.ok && x.type === "tablet"; }).length > 0;
		if (wroteTablet && j.reboot_pending) { html += callout("", esc(T("COPY.NOTE_PENDING_TITLE")), esc(T("COPY.NOTE_PENDING_BODY"))); }
		else if (wroteTablet) { html += callout("", esc(T("COPY.NOTE_REBOOT_TITLE")), esc(T("COPY.NOTE_REBOOT_BODY"))); }
		var failed = $.grep(j.results || [], function (x) { return !x.ok; });
		if (failed.length) {
			html += callout("lb-callout-warning", esc(T("COPY.NOTE_FAIL_TITLE", $.map(failed, function (x) { return x.name; }).join(", "))), esc(T("COPY.NOTE_FAIL_BODY")));
		}
		$("#ov-notes").html(html);
	}

	function draw() { card(); lists(); bar(); notes(); }

	function fromJob(j) {
		S.job = j;
		if (j.current) { S.runSet[j.current] = 1; }
		$.each(j.results || [], function (i, x) { S.runSet[x.uuid] = 1; });
		$.each(S.inv, function (i, e) {
			if (!S.runSet[e.uuid]) { return; }
			var st = entryState(j, e.uuid, isTablet(e));
			S.status[e.uuid] = st.s;
			if (st.error) { S.errs[e.uuid] = st.error; }
		});
		draw();
	}
	function finished(j) {
		S.phase = "done";
		fromJob(j);
		// New states of the targets, results stay on screen
		safe(smGet("inventory", { msnr: MSNR })).done(function (r) { if (r.ok) { S.inv = r.entries || []; draw(); } });
	}

	function copy(only) {
		keepPw();
		var t = only || targets(), passwords = {};
		$.each(t, function (i, e) {
			var v = S.pw["ov-pw-" + e.uuid];
			if (v) { passwords[e.name] = v; }
		});
		S.status = only ? S.status : {}; S.errs = only ? S.errs : {}; S.runSet = {};
		$.each(t, function (i, e) { S.status[e.uuid] = "wait"; S.runSet[e.uuid] = 1; delete S.errs[e.uuid]; });
		S.phase = "run"; S.job = { done: 0, total: t.length };
		draw();
		jobStart("copy", {
			source: S.src,
			targets: JSON.stringify($.map(t, function (e) { return { uuid: e.uuid, name: e.name, type: e.type, method: way(e) }; })),
			passwords: JSON.stringify(passwords),
			auto_reboot: S.reboot ? 1 : 0
		}, fromJob, finished, function (key) {
			S.phase = "idle"; S.status = {};
			draw();
			errorBox($("#ov-error"), key);
		});
	}

	function resetResult() { if (S.phase === "run") { return; } S.phase = "idle"; S.status = {}; S.errs = {}; S.runSet = {}; S.job = null; $("#ov-error").empty(); }

	// --- Events
	$("#ov-src").on("change", "input[name=ov-src]", function () { S.src = this.value; resetResult(); draw(); });
	$("#ov-tgt").on("change", "input[data-tgt]", function () { S.tgt[this.value] = this.checked ? 1 : 0; resetResult(); draw(); });
	$("#ov-tgt").on("change", "input[data-way]", function () { S.meth[$(this).data("way")] = this.value; resetResult(); draw(); });
	$("#ov-quick").on("click", "button", function () {
		var k = $(this).data("quick");
		$.each(S.inv, function (i, e) {
			if (k === "none") { S.tgt[e.uuid] = 0; }
			else if (k === "tablet" && isTablet(e)) { S.tgt[e.uuid] = 1; }
			else if (k === "user" && !isTablet(e)) { S.tgt[e.uuid] = 1; }
		});
		resetResult(); draw();
	});
	$("#ov-bar").on("change", "#ov-rb", function () { S.reboot = this.checked; });
	$("#ov-bar").on("click", "#ov-copy", function () { copy(null); });
	$("#ov-bar").on("click", "#ov-reset", function () { resetResult(); draw(); });
	$("#ov-bar").on("click", "#ov-retry", function () {
		var failed = $.grep(S.inv, function (e) { return S.status[e.uuid] === "err"; });
		copy(failed);
	});
	$("#ov-bar").on("click", "#ov-save", function () {
		var t = targets();
		safe(smPost("saveconfig", { msnr: MSNR, data: JSON.stringify({
			source: S.src,
			targets: $.map(t, function (e) { return { uuid: e.uuid, name: e.name, type: e.type, method: way(e) }; })
		}) })).done(function (r) {
			var $t = $("#ov-toast");
			if (r.ok) { $t.html('<i class="pi pi-check"></i>' + esc(T("OVERVIEW.SAVED_DEFAULT"))); $t.removeClass("err").addClass("on"); setTimeout(function () { $t.removeClass("on"); }, 2200); }
			else { toast($t, r.error); }
		});
	});

	// --- Load
	loadMiniservers().done(function (ms) {
		S.ms = ms;
		renderSwitch($("#ov-switch"), ms);
		if (!ms.cur) { S.ok = false; errorBox($("#ov-error"), "nominiserver"); draw(); return; }
		$.when(safe(smGet("watchstatus", { msnr: MSNR })), safe(smGet("inventory", { msnr: MSNR })), safe(smGet("backups", { msnr: MSNR })))
		.done(function (w, inv, bk) {
			S.watch = w.ok ? w : null;
			S.backups = (bk.ok && bk.backups) || [];
			if (!inv.ok) {
				S.ok = false;
				loadError($("#ov-error"), inv.error);
				draw();
				return;
			}
			S.inv = inv.entries || [];
			if (inv.orphans && inv.orphans.length) { $("#ov-orphans").html('<i class="pi pi-info-circle"></i>' + esc(T("OVERVIEW.ORPHANS", inv.orphans.length))).prop("hidden", false); }
			if (S.watch) {
				if (S.watch.source && byUuid(S.watch.source) && byUuid(S.watch.source).has_sorting) { S.src = S.watch.source; }
				$.each(S.watch.targets || [], function (i, t) { S.tgt[t.uuid] = 1; if (t.method) { S.meth[t.uuid] = t.method; } });
				S.reboot = !!(S.watch.watch && S.watch.watch.auto_reboot);
			}
			draw();
			// Asked for separately so the lists are on screen first
			safe(smGet("tokenstatus", { msnr: MSNR })).done(function (t) {
				S.tok = (t.ok && t.token) || {};
				S.tokLoaded = !!t.ok;
				draw();
			});
			// A copy that is already running (other tab, watch) is shown, not restarted
			jobResume(["copy"], function (j) {
				S.phase = "run"; S.status = {}; S.runSet = {};
				S.src = j.source || S.src;
				fromJob(j);
			}, fromJob, finished);
		});
	});
}

// ======================================================================
// Watch
// ======================================================================

function watchTab() {
	var W = null, names = {};
	var INTERVALS = [5, 15, 30, 60, 1440];

	function nearest(v) {
		var best = INTERVALS[0];
		$.each(INTERVALS, function (i, x) { if (Math.abs(x - v) < Math.abs(best - v)) { best = x; } });
		return best;
	}
	function nameOf(uuid, fallback) { return names[uuid] || fallback || "?"; }
	function activeText(min) {
		if (min === 60) { return T("WATCH.ACTIVE_HOURLY"); }
		if (min === 1440) { return T("WATCH.ACTIVE_DAILY"); }
		return T("WATCH.ACTIVE", min);
	}
	function histText(h) {
		var t;
		if (h.result === "unchanged") { t = T("WATCH.H_UNCHANGED"); }
		else if (h.result === "changed") {
			var n = (h.copied || 0) + (h.failed || 0);
			t = h.failed ? T("WATCH.H_CHANGED", h.copied || 0, n) : (h.copied === 1 ? T("WATCH.H_CHANGED_ONE") : T("WATCH.H_CHANGED_ALL", h.copied || 0));
			if (h.reboot === "pending") { t += " · " + T("WATCH.H_REBOOT_PENDING"); }
			if (h.reboot === "done") { t += " · " + T("WATCH.H_REBOOT_DONE"); }
		}
		else { t = errText(h.error); }
		if (h.manual) { t += " · " + T("WATCH.H_MANUAL"); }
		return t;
	}

	function draw() {
		var w = W.watch || {}, conf = !!(W.source && (W.targets || []).length);
		var on = !!w.enabled && conf;
		$("#w-notconf").prop("hidden", conf);
		$("#w-on").prop("checked", on).prop("disabled", !conf);
		$("#w-now").prop("disabled", !conf);
		$("#w-dot").attr("class", "sm-dot" + (on ? "" : " off"));
		$("#w-state").text(on ? activeText(nearest(Number(w.interval_min) || 15)) : T("WATCH.OFF"));
		$("#w-sub").text(on ? (W.next_run_local ? T("WATCH.NEXT", fmt(W.next_run_local).replace(/^.* /, "")) : "")
			: (conf ? T("WATCH.OFF_SUB", nameOf(W.source)) : ""));
		if (conf) {
			$("#w-what").show().html('<span class="sm-k">' + esc(T("WATCH.WATCHED")) + '</span><span class="sm-chips">' +
				'<span class="sm-chip src"><i class="pi pi-user"></i>' + esc(nameOf(W.source)) + '</span><i class="pi pi-arrow-right sm-muted"></i>' +
				$.map(W.targets, function (t) { return '<span class="sm-chip">' + esc(nameOf(t.uuid, t.name)) + "</span>"; }).join("") +
				'</span><a class="sm-link" href="' + url("overview") + '">' + esc(T("WATCH.CHANGE")) + "</a>");
		} else { $("#w-what").hide(); }
		var h = W.history || [];
		$("#w-hist").html(h.length ? $.map(h, function (x) {
			var cls = x.result === "changed" ? "chg" : x.result === "error" ? "err" : "";
			var icon = x.result === "changed" ? "pi-sync" : x.result === "error" ? "pi-exclamation-triangle" : "pi-minus";
			return '<li class="' + cls + '"><span class="t">' + fmt(x.ts_local) + '</span><i class="pi ' + icon + '"></i><span>' + esc(histText(x)) + "</span></li>";
		}).join("") : '<li><span class="empty">' + esc(T("WATCH.HIST_EMPTY")) + "</span></li>");
		$("input[name=w-int][value=" + nearest(Number(w.interval_min) || 15) + "]").prop("checked", true);
		$("input[name=w-rb][value=" + (w.auto_reboot ? 1 : 0) + "]").prop("checked", true);
		$("#w-set").toggleClass("sm-off", !on);
	}

	var save = autoSave(function () {
		return { watch: {
			enabled: $("#w-on").prop("checked") ? 1 : 0,
			interval_min: Number($("input[name=w-int]:checked").val()) || 15,
			auto_reboot: Number($("input[name=w-rb]:checked").val()) || 0
		} };
	}, $("#w-toast"));

	function reload() {
		return safe(smGet("watchstatus", { msnr: MSNR })).done(function (r) {
			if (!r.ok) { loadError($("#w-error"), r.error); $("#w-card, #w-set").addClass("sm-off"); return; }
			W = r; draw();
		});
	}

	$("#w-on").on("change", function () {
		if (!W) { return; }
		W.watch.enabled = this.checked ? 1 : 0;
		draw(); save();
		// The next check moves with the switch
		setTimeout(reload, 1200);
	});
	$("#w-int").on("change", "input", function () { if (!W) { return; } W.watch.interval_min = Number(this.value); draw(); save(); setTimeout(reload, 1200); });
	$("#w-rb").on("change", "input", function () { if (!W) { return; } W.watch.auto_reboot = Number(this.value); save(); });
	$("#w-now").on("click", function () {
		var $b = $(this), html = $b.html();
		$b.prop("disabled", true).html('<i class="pi pi-spin pi-spinner"></i> ' + esc(T("WATCH.CHECKING")));
		safe(smPost("watchnow", { msnr: MSNR })).done(function (r) {
			$b.prop("disabled", false).html(html);
			if (!r.ok && !r.skipped) { toast($("#w-toast"), r.error); }
			reload();
		});
	});

	loadMiniservers().done(function (ms) {
		if (!ms.cur) { $("#ctx").empty(); errorBox($("#w-error"), "nominiserver"); return; }
		$.when(safe(smGet("backups", { msnr: MSNR })), safe(smGet("inventory", { msnr: MSNR }))).done(function (bk, inv) {
			var lb = bk.ok ? lastBackup(bk.backups) : null;
			renderContext($("#ctx"), ms, pill("", '<i class="pi pi-history"></i>' + esc(lb ? T("COMMON.PILL_BACKUP", lb) : T("COMMON.PILL_BACKUP_NONE"))));
			// Settings come from the configuration even while the Miniserver is down
			if (!ms.cur.serial) { loadError($("#w-error"), ms.cur.error || "unreachable"); }
			$.each((inv.ok && inv.entries) || [], function (i, e) { names[e.uuid] = e.name; });
			reload();
		});
	});
}

// ======================================================================
// Backup
// ======================================================================

function backupTab() {
	var C = null, list = [], free = null, open = null, ask = null, prev = {}, tok = null;
	var R = { file: null, status: {}, errs: {}, pw: {}, job: null, phase: "idle" };
	var KEEPS = [5, 10, 20, 50];

	function sched() { return (C && C.backup && C.backup.schedule) || {}; }

	// Next date the cron would run the backup - mirrors backup_due()
	function nextBackup() {
		var s = sched();
		var days = $("#b-days input:checked").map(function () { return Number(this.value); }).get();
		if (!$("#b-on").prop("checked")) { return { off: true }; }
		if (!days.length) { return { none: true }; }
		var t = ($("#b-time").val() || "03:00").split(":"), now = new Date();
		var last = lox2date(s.last_run), weeks = Number($("#b-rep").val()) || 1;
		for (var i = 0; i < 7 * weeks + 8; i++) {
			var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i, +t[0], +t[1]);
			if (d <= now || days.indexOf(d.getDay()) < 0) { continue; }
			if (last) {
				if (d.toDateString() === last.toDateString()) { continue; }
				if (d - last < (weeks - 1) * 7 * 86400000) { continue; }
			}
			return { at: d };
		}
		return { none: true };
	}
	function rel(d) {
		var h = Math.round((d - new Date()) / 3600000);
		return h < 24 ? T("BACKUP.IN_HOURS", Math.max(h, 1)) : T("BACKUP.IN_DAYS", Math.round(h / 24));
	}

	function cardDraw() {
		var n = nextBackup(), keep = Number($("#b-keep").val()) || 10, total = 0;
		$.each(list, function (i, b) { total += Number(b.bytes || 0); });
		$("#b-next").text(n.off ? T("BACKUP.NEXT_OFF") : n.none ? T("BACKUP.NEXT_NONE") : fmt(n.at));
		$("#b-next-sub").text(n.off ? T("BACKUP.NEXT_OFF_SUB") : n.none ? T("BACKUP.NEXT_NONE_SUB") : rel(n.at) + " · " + $("#b-rep option:selected").text());
		$("#b-keepinfo").text(T("BACKUP.KEEP_V", keep));
		$("#b-keepsub").text(T("BACKUP.KEEP_SUB", list.length));
		$("#b-space").text(size(total));
		$("#b-free").text(free !== null && free !== undefined ? T("BACKUP.SPACE_FREE", size(free)) : "");
		$("#b-nodays").prop("hidden", !n.none);
		$("#b-dep").toggleClass("sm-off", !!n.off);
	}

	function settingsDraw() {
		var s = sched(), keep = Number(C.backup.keep) || 10;
		$("#b-on").prop("checked", !!s.enabled);
		var days = $.map(s.days || [], Number);
		$("#b-days input").each(function () { this.checked = days.indexOf(Number(this.value)) >= 0; });
		$("#b-time").val(pad(Number(s.hour) || 0) + ":" + pad(Number(s.minute) || 0));
		var reps = [1, 2, 3, 4], w = Number(s.every_weeks) || 1;
		if (reps.indexOf(w) < 0) { reps.push(w); }
		$("#b-rep").html($.map(reps, function (r) { return '<option value="' + r + '"' + (r === w ? " selected" : "") + ">" + esc(r === 1 ? T("BACKUP.REP1") : T("BACKUP.REPN", r)) + "</option>"; }).join(""));
		var keeps = KEEPS.slice();
		if (keeps.indexOf(keep) < 0) { keeps.push(keep); keeps.sort(function (a, b) { return a - b; }); }
		$("#b-keep").html($.map(keeps, function (k) { return '<option value="' + k + '"' + (k === keep ? " selected" : "") + ">" + esc(T("BACKUP.KEEP_OPT", k)) + "</option>"; }).join(""));
	}

	var save = autoSave(function () {
		var t = ($("#b-time").val() || "03:00").split(":");
		return { backup: {
			keep: Number($("#b-keep").val()) || 10,
			schedule: {
				enabled: $("#b-on").prop("checked") ? 1 : 0,
				days: $("#b-days input:checked").map(function () { return Number(this.value); }).get(),
				hour: Number(t[0]) || 0,
				minute: Number(t[1]) || 0,
				every_weeks: Number($("#b-rep").val()) || 1
			}
		} };
	}, $("#b-toast"));
	$("#b-on, #b-days input, #b-rep, #b-keep").on("change", function () { cardDraw(); save(); });
	$("#b-time").on("change", function () { cardDraw(); save(); });

	// --- Archive list
	function entryHtml(a, e) {
		var key = a.file, id = "b-e-" + esc(e.uuid), busy = R.phase === "run" && R.file === key;
		var st = R.file === key ? R.status[e.uuid] : null;
		var cmp;
		if (!e.alive) { cmp = pill("err", esc(T("BACKUP.GONE"))); }
		else if (st) {
			var text = { wait: T("BACKUP.R_WAIT"), run: T("BACKUP.R_RUN"), ok: T("BACKUP.R_OK"), okr: T("BACKUP.R_OK_REBOOT"), err: errText(R.errs[e.uuid]) }[st];
			cmp = state(st === "okr" ? "ok" : st, esc(text));
		}
		else {
			var differs = e.current_ts && String(e.current_ts) !== String(e.ts);
			cmp = esc(T("BACKUP.SAVED_AT", fmtDay(e.ts_local))) + " · <span" + (differs ? ' class="differs"' : "") + ">" +
				esc(e.current_ts_local ? T("BACKUP.NOW_AT", fmtDay(e.current_ts_local)) : T("BACKUP.NOW_NONE")) + "</span>";
		}
		var checked = R.file === key && R.sel ? R.sel[e.uuid] : e.alive;
		var needPw = e.alive && (e.type_now || e.type) !== "tablet" && tok && tok[e.uuid] !== "ok" && checked;
		var showPw = !busy && (needPw && !st || (st === "err" && /credentials/.test(R.errs[e.uuid] || "")));
		return '<li' + (e.alive ? "" : ' class="gone"') + '><input type="checkbox" id="' + id + '" value="' + esc(e.uuid) + '" data-entry' +
			(checked ? " checked" : "") + (e.alive && !busy ? "" : " disabled") + ">" +
			'<label for="' + id + '"><b>' + esc(e.name) + '</b><span class="sm-sub">' + esc(typeText(e.type_now || e.type)) + "</span></label>" +
			'<span class="cmp">' + cmp + "</span>" +
			'<div class="slot">' + (showPw ? pwField("b-pw-" + esc(e.uuid), e.name, R.pw["b-pw-" + e.uuid]) : "") + "</div></li>";
	}
	function bodyHtml(a) {
		var p = prev[a.file];
		if (!p) { return '<p class="sm-muted">' + esc(T("COMMON.LOADING")) + "</p>"; }
		if (!p.ok) { return callout("lb-callout-warning", errText(p.error), ""); }
		var entries = p.manifest.entries || [], busy = R.phase === "run" && R.file === a.file;
		var tablets = $.grep(entries, function (e) { return e.alive && (e.type_now || e.type) === "tablet"; }).length;
		var del = ask === a.file
			? '<span class="sm-del"><span class="sm-link danger">' + esc(T("BACKUP.DELETE_ASK")) + '</span><button type="button" class="lb-btn lb-btn-sm" data-no>' + esc(T("COMMON.NO")) +
			  '</button><button type="button" class="lb-btn lb-btn-danger lb-btn-sm" data-yes>' + esc(T("BACKUP.BTN_DELETE")) + "</button></span>"
			: '<a class="sm-link danger sm-del" data-ask role="button" tabindex="0"><i class="pi pi-trash"></i> ' + esc(T("BACKUP.DELETE")) + "</a>";
		var foot = "";
		if (R.file === a.file && R.phase === "done") { foot = R.notes || ""; }
		else if (!busy) {
			foot = '<div class="sm-afoot">' + (tablets ? '<div class="sm-reboot"><label class="lb-toggle"><input type="checkbox" id="b-rb"' + (R.reboot !== false ? " checked" : "") +
				'><span class="lb-toggle-slider"></span></label><label for="b-rb">' + esc(T("OVERVIEW.REBOOT_TOGGLE")) + "</label></div>" : "") +
				'<div class="lb-actions"><button type="button" class="lb-btn lb-btn-primary" data-restore><i class="pi pi-replay"></i> ' + esc(T("BACKUP.BTN_RESTORE")) + "</button></div></div>";
		}
		return '<div class="sm-abhead"><span>' + esc(T("BACKUP.PICK")) + "</span>" + (busy ? "" : del) + "</div>" +
			'<ul class="sm-ent">' + $.map(entries, function (e) { return entryHtml(a, e); }).join("") + "</ul>" + foot;
	}
	function listDraw() {
		$("#b-list input[data-pw]").each(function () { R.pw[this.id] = this.value; });
		if (!list.length) { $("#b-count").text(""); $("#b-list").html('<p class="sm-muted">' + esc(T("BACKUP.NONE_YET")) + "</p>"); return; }
		$("#b-count").text(T("BACKUP.COUNT", list.length, fmtDay(list[list.length - 1].created_local)));
		$("#b-list").html($.map(list, function (a) {
			var p = prev[a.file], gone = 0;
			if (p && p.ok) { gone = $.grep(p.manifest.entries || [], function (e) { return !e.alive; }).length; }
			var isOpen = open === a.file;
			return '<div class="lb-card sm-aitem' + (isOpen ? " open" : "") + '" data-file="' + esc(a.name) + '">' +
				'<button type="button" class="sm-arow" aria-expanded="' + isOpen + '"><i class="pi pi-chevron-right"></i>' +
				'<span><b class="sm-tnum">' + fmt(a.created_local) + '</b><span class="sm-sub">' + esc(a.trigger === "manual" ? T("BACKUP.T_MANUAL") : T("BACKUP.T_SCHEDULE")) + "</span></span>" +
				'<span class="sm-tnum">' + esc(T("BACKUP.ENTRIES", a.entries || 0)) + '</span><span class="sm-tnum hide-sm">' + size(a.bytes) + "</span>" +
				'<span class="sm-tnum hide-sm">' + (a.firmware ? esc(T("COMMON.FW", a.firmware)) : "") + "</span>" +
				(gone ? pill("warn hide-sm", esc(gone === 1 ? T("BACKUP.MISSING1") : T("BACKUP.MISSINGN", gone))) : "<span></span>") + "</button>" +
				'<div class="sm-abody">' + (isOpen ? bodyHtml(a) : "") + "</div></div>";
		}).join(""));
		$("#b-list input[data-pw]").each(function () { if (R.pw[this.id]) { this.value = R.pw[this.id]; } });
	}
	function byName(name) { var a = null; $.each(list, function (i, x) { if (x.name === name) { a = x; } }); return a; }
	function loadPreview(a) {
		if (prev[a.file]) { return; }
		var need = [safe(smGet("checkrestore", { msnr: MSNR, file: a.file }))];
		if (!tok) { need.push(safe(smGet("tokenstatus", { msnr: MSNR }))); }
		$.when.apply($, need).done(function (p, t) {
			prev[a.file] = p;
			if (t) { tok = (t.ok && t.token) || {}; }
			listDraw();
		});
	}
	function reloadList() {
		return safe(smGet("backups", { msnr: MSNR })).done(function (r) {
			if (!r.ok) { loadError($("#b-error"), r.error); return; }
			list = r.backups || []; free = r.free_bytes;
			if (open && !byName(open.replace(/^.*\//, ""))) { open = null; }
			listDraw(); cardDraw();
		});
	}

	$("#b-list").on("click", ".sm-arow", function () {
		var a = byName($(this).closest(".sm-aitem").data("file"));
		if (!a || R.phase === "run") { return; }
		open = open === a.file ? null : a.file;
		ask = null;
		if (R.phase === "done" && R.file !== open) { R = { file: null, status: {}, errs: {}, pw: R.pw, phase: "idle" }; }
		listDraw();
		if (open) { loadPreview(a); }
	});
	$("#b-list").on("change", "input[data-entry]", function () {
		R.file = open; R.sel = R.sel || {};
		$("#b-list input[data-entry]").each(function () { R.sel[this.value] = this.checked; });
		listDraw();
	});
	$("#b-list").on("change", "#b-rb", function () { R.reboot = this.checked; });
	$("#b-list").on("click keydown", "[data-ask]", function (ev) {
		if (ev.type === "keydown" && ev.key !== "Enter" && ev.key !== " ") { return; }
		ask = open; listDraw();
	});
	$("#b-list").on("click", "[data-no]", function () { ask = null; listDraw(); });
	$("#b-list").on("click", "[data-yes]", function () {
		var a = byName(open.replace(/^.*\//, "")) || null;
		safe(smPost("deletebackup", { file: a ? a.file : "" })).done(function (r) {
			if (!r.ok) { errorBox($("#b-error"), r.error); }
			delete prev[open]; open = null; ask = null;
			reloadList();
		});
	});
	$("#b-list").on("click", "[data-restore]", function () {
		$("#b-list input[data-pw]").each(function () { R.pw[this.id] = this.value; });
		var a = byName(open.replace(/^.*\//, "")), p = prev[open];
		var only = $("#b-list input[data-entry]:checked").map(function () { return this.value; }).get();
		if (!only.length) { $("#b-error").html(callout("lb-callout-warning", esc(T("BACKUP.R_NOTHING")), "")); return; }
		$("#b-error").empty();
		var passwords = {};
		$.each(p.manifest.entries || [], function (i, e) {
			var v = R.pw["b-pw-" + e.uuid];
			if (v && only.indexOf(e.uuid) >= 0) { passwords[e.name] = v; }
		});
		var sel = {};
		$.each(only, function (i, u) { sel[u] = true; });
		R = { file: open, sel: sel, status: {}, errs: {}, pw: R.pw, phase: "run", reboot: $("#b-rb").length ? $("#b-rb").prop("checked") : false };
		$.each(only, function (i, u) { R.status[u] = "wait"; });
		listDraw();
		jobStart("restore", { file: a.file, only: JSON.stringify(only), auto_reboot: R.reboot ? 1 : 0, passwords: JSON.stringify(passwords) },
			restoreTick, restoreDone, function (key) { R.phase = "idle"; R.status = {}; listDraw(); errorBox($("#b-error"), key); });
	});
	function restoreTick(j) {
		var p = prev[R.file];
		if (!p || !p.ok) { return; }
		// Resumed from another tab: the entries become known as the job reaches them
		if (R.resumed) {
			if (j.current && !R.status[j.current]) { R.status[j.current] = "wait"; }
			$.each(j.results || [], function (i, x) { if (!R.status[x.uuid]) { R.status[x.uuid] = "wait"; } });
		}
		$.each(p.manifest.entries || [], function (i, e) {
			if (!R.status[e.uuid]) { return; }
			var st = entryState(j, e.uuid, (e.type_now || e.type) === "tablet");
			R.status[e.uuid] = st.s;
			if (st.error) { R.errs[e.uuid] = st.error; }
		});
		listDraw();
	}
	function restoreDone(j) {
		restoreTick(j);
		R.phase = "done";
		var res = j.results || [], ok = $.grep(res, function (x) { return x.ok; }).length;
		var tabs = $.grep(res, function (x) { return x.ok && x.type === "tablet"; }).length;
		var body = tabs ? (j.reboot_pending ? T("COPY.NOTE_PENDING_BODY") : T("COPY.NOTE_REBOOT_BODY")) : "";
		R.notes = callout("", esc(T("BACKUP.R_DONE_TITLE", ok)), esc(body));
		var failed = $.grep(res, function (x) { return !x.ok; });
		if (failed.length) { R.notes += callout("lb-callout-warning", esc(T("COPY.NOTE_FAIL_TITLE", $.map(failed, function (x) { return x.name; }).join(", "))), esc(T("COPY.NOTE_FAIL_BODY"))); }
		// The current state changed: fetch the comparison again on the next open
		var f = R.file;
		safe(smGet("checkrestore", { msnr: MSNR, file: f })).done(function (p) { if (p.ok) { prev[f] = p; } listDraw(); });
	}

	// --- Backup now
	$("#b-now").on("click", function () {
		var $b = $(this), html = $b.html();
		$b.prop("disabled", true).html('<i class="pi pi-spin pi-spinner"></i> ' + esc(T("BACKUP.RUNNING")));
		$("#b-runline").removeClass("err").empty();
		jobStart("backupnow", {}, function () {}, function (j) {
			$b.prop("disabled", false).html(html);
			var r = (j.results || [])[0] || {};
			if (r.ok) {
				$("#b-runline").html('<i class="pi pi-check-circle"></i>' + esc(T("BACKUP.DONE", r.entries || 0, size(r.bytes), fmt(new Date()))));
			} else {
				$("#b-runline").addClass("err").html('<i class="pi pi-times-circle"></i>' + errText(r.error));
			}
			reloadList();
		}, function (key) {
			$b.prop("disabled", false).html(html);
			$("#b-runline").addClass("err").html('<i class="pi pi-times-circle"></i>' + errText(key));
		});
	});

	loadMiniservers().done(function (ms) {
		if (!ms.cur) { errorBox($("#b-error"), "nominiserver"); return; }
		$.when(safe(smGet("config", { msnr: MSNR })), safe(smGet("watchstatus", { msnr: MSNR }))).done(function (c, w) {
			var ww = w.ok && w.watch;
			renderContext($("#ctx"), ms, pill("", '<i class="pi pi-eye"></i>' +
				esc(ww && ww.enabled && w.source ? T("COMMON.PILL_WATCH", T("CARD.WATCH_EVERY", ww.interval_min)) : T("COMMON.PILL_WATCH_OFF"))));
			// Archives are listed from the LoxBerry even while the Miniserver is down
			if (!ms.cur.serial) { loadError($("#b-error"), ms.cur.error || "unreachable"); }
			if (!c.ok) { loadError($("#b-error"), c.error); $("#b-card, #b-sched").addClass("sm-off"); }
			else { C = c.config; settingsDraw(); }
			reloadList().done(function () {
				jobResume(["backup", "restore"], function (j) {
					if (j.kind === "backup") { $("#b-now").prop("disabled", true).html('<i class="pi pi-spin pi-spinner"></i> ' + esc(T("BACKUP.RUNNING"))); return; }
					// A restore started elsewhere: open its archive and follow it entry by entry
					var a = j.file ? byName(j.file.replace(/^.*\//, "")) : null;
					if (!a) { return; }
					open = a.file;
					R = { file: a.file, sel: {}, status: {}, errs: {}, pw: R.pw, phase: "run", resumed: true };
					listDraw();
					loadPreview(a);
				}, function (j) {
					if (j.kind === "restore" && R.resumed) { restoreTick(j); }
				}, function (j) {
					$("#b-now").prop("disabled", false).html('<i class="pi pi-download"></i> ' + esc(T("BACKUP.BTN_NOW")));
					if (j.kind === "restore" && R.resumed) { restoreDone(j); }
					reloadList();
				});
			});
		});
	});
}

$(function () {
	if (FORM === "overview") { overview(); }
	else if (FORM === "watch") { watchTab(); }
	else if (FORM === "backup") { backupTab(); }
});

})(jQuery);
</script>
