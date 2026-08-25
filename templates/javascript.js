<script>

// Shared JavaScript for all tabs. Appended to every template, so it may use
// TMPL_VAR tags for localized strings. Data comes from ajax.cgi (relative URL).

(function() {
	var css =
		".sm-hint{color:var(--lb-text-muted);font-size:0.9rem;line-height:1.6;}" +
		".sm-table{width:100%;border-collapse:collapse;margin:16px 0;font-size:0.92rem;}" +
		".sm-table th,.sm-table td{padding:7px 9px;text-align:left;border-bottom:1px solid var(--lb-border,#ddd);vertical-align:middle;}" +
		".sm-table th{font-weight:700;white-space:nowrap;}" +
		".sm-table tbody tr:hover{background:rgba(127,127,127,.08);}" +
		".sm-col-narrow{width:1%;white-space:nowrap;text-align:center;}" +
		".sm-table td.sm-col-narrow{text-align:center;}" +
		".sm-nosorting{color:var(--lb-text-muted);font-style:italic;}" +
		".sm-badge{display:inline-block;padding:2px 8px;border-radius:10px;font-size:0.8rem;white-space:nowrap;}" +
		".sm-badge-ok{background:#6dac20;color:#fff;}" +
		".sm-badge-warn{background:#f5a623;color:#fff;}" +
		".sm-badge-none{background:#9e9e9e;color:#fff;}" +
		".sm-badge-err{background:#d0021b;color:#fff;}" +
		".sm-orphans{color:var(--lb-text-muted);font-size:0.87rem;}" +
		".sm-reboot-row{margin:12px 0;}" +
		".sm-msg{padding:9px 12px;border-radius:5px;margin:12px 0;}" +
		".sm-msg-ok{background:rgba(109,172,32,.15);}" +
		".sm-msg-err{background:rgba(208,2,27,.13);}" +
		".sm-warning{padding:11px 14px;border-radius:5px;background:rgba(245,166,35,.15);margin:12px 0;}" +
		".sm-job{margin:16px 0;padding:12px 14px;border-radius:5px;background:rgba(127,127,127,.1);}" +
		".sm-job-title{font-weight:700;margin:0 0 6px;}" +
		".sm-job-list{margin:0;padding-left:18px;}" +
		".sm-number{width:5.5em;display:inline-block;}" +
		".sm-time{display:flex;align-items:center;gap:6px;}" +
		".sm-days{display:flex;flex-wrap:wrap;gap:10px;}" +
		".sm-days label{white-space:nowrap;}" +
		".sm-dialog{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:9000;display:flex;align-items:center;justify-content:center;padding:16px;}" +
		".sm-dialog-box{background:var(--lb-bg,#fff);color:var(--lb-text,#333);border-radius:7px;padding:20px;max-width:560px;width:100%;max-height:85vh;overflow:auto;}" +
		".sm-pw-row{display:flex;align-items:center;gap:8px;margin:8px 0;}" +
		".sm-pw-row label{min-width:11em;}" +
		".sm-entry{display:block;margin:5px 0;}" +
		".sm-gone{text-decoration:line-through;color:var(--lb-text-muted);}";
	var s = document.createElement("style");
	s.appendChild(document.createTextNode(css));
	document.head.appendChild(s);
})();

// Localized strings. Error keys arrive from ajax.cgi in lower case and are
// looked up in upper case, so this table matches the language files.
var SM_L = {
	SAVED:        "<TMPL_VAR COMMON.SAVED>",
	NEVER:        "<TMPL_VAR COMMON.NEVER>",
	LOADING:      "<TMPL_VAR COMMON.LOADING>",
	TYPE_ADMIN:   "<TMPL_VAR OVERVIEW.TYPE_ADMIN>",
	TYPE_USER:    "<TMPL_VAR OVERVIEW.TYPE_USER>",
	TYPE_TABLET:  "<TMPL_VAR OVERVIEW.TYPE_TABLET>",
	METHOD_TOKEN: "<TMPL_VAR OVERVIEW.METHOD_TOKEN>",
	METHOD_REBOOT:"<TMPL_VAR OVERVIEW.METHOD_REBOOT>",
	TOKEN_OK:     "<TMPL_VAR OVERVIEW.TOKEN_OK>",
	TOKEN_EXPIRED:"<TMPL_VAR OVERVIEW.TOKEN_EXPIRED>",
	TOKEN_NONE:   "<TMPL_VAR OVERVIEW.TOKEN_NONE>",
	NOSORTING:    "<TMPL_VAR OVERVIEW.NOSORTING>",
	ORPHANS:      "<TMPL_VAR OVERVIEW.ORPHANS>",
	PW_FOR:       "<TMPL_VAR OVERVIEW.PW_FOR>",
	JOB_RUNNING:  "<TMPL_VAR OVERVIEW.JOB_RUNNING>",
	JOB_DONE:     "<TMPL_VAR OVERVIEW.JOB_DONE>",
	JOB_FAILED:   "<TMPL_VAR OVERVIEW.JOB_FAILED>",
	NO_SOURCE:    "<TMPL_VAR OVERVIEW.NO_SOURCE>",
	NO_TARGET:    "<TMPL_VAR OVERVIEW.NO_TARGET>",
	REBOOT_PENDING:"<TMPL_VAR OVERVIEW.REBOOT_PENDING>",
	RAN_CHANGED:  "<TMPL_VAR WATCH.RAN_CHANGED>",
	RAN_UNCHANGED:"<TMPL_VAR WATCH.RAN_UNCHANGED>",
	RESTORE_MISSING:"<TMPL_VAR BACKUP.RESTORE_MISSING>",
	DELETE_CONFIRM: "<TMPL_VAR BACKUP.DELETE_CONFIRM>",
	BTN_RESTORE:  "<TMPL_VAR BACKUP.BTN_RESTORE>",
	BTN_DELETE:   "<TMPL_VAR BACKUP.BTN_DELETE>",
	NONE_YET:     "<TMPL_VAR BACKUP.NONE_YET>",
	RUNNING:      "<TMPL_VAR BACKUP.RUNNING>",
	YES:          "<TMPL_VAR COMMON.YES>",
	NO:           "<TMPL_VAR COMMON.NO>"
};

var SM_ERR = {
	NOTREACHABLE:    "<TMPL_VAR ERR.NOTREACHABLE>",
	NOCREDENTIALS:   "<TMPL_VAR ERR.NOCREDENTIALS>",
	BADCREDENTIALS:  "<TMPL_VAR ERR.BADCREDENTIALS>",
	VERIFYFAILED:    "<TMPL_VAR ERR.VERIFYFAILED>",
	NOTFOUND:        "<TMPL_VAR ERR.NOTFOUND>",
	BADPATH:         "<TMPL_VAR ERR.BADPATH>",
	JOBRUNNING:      "<TMPL_VAR ERR.JOBRUNNING>",
	NOBACKUPDIR:     "<TMPL_VAR ERR.NOBACKUPDIR>",
	UNKNOWNACTION:   "<TMPL_VAR ERR.UNKNOWNACTION>",
	FTPFAILED:       "<TMPL_VAR ERR.FTPFAILED>",
	NOTCONFIGURED:   "<TMPL_VAR ERR.NOTCONFIGURED>",
	POSTREQUIRED:    "<TMPL_VAR ERR.POSTREQUIRED>",
	BADDATA:         "<TMPL_VAR ERR.BADDATA>",
	SAVEFAILED:      "<TMPL_VAR ERR.SAVEFAILED>",
	NOTARGETS:       "<TMPL_VAR ERR.NOTARGETS>",
	NOSOURCE:        "<TMPL_VAR ERR.NOSOURCE>",
	NOMSNR:          "<TMPL_VAR ERR.NOMSNR>",
	FORKFAILED:      "<TMPL_VAR ERR.FORKFAILED>",
	NOJOBDIR:        "<TMPL_VAR ERR.NOJOBDIR>",
	MISSINGINARCHIVE:"<TMPL_VAR ERR.MISSINGINARCHIVE>",
	UNKNOWN:         "<TMPL_VAR ERR.UNKNOWN>"
};

function smErr(key) {
	if (!key) { return SM_ERR.UNKNOWN; }
	var k = String(key).toUpperCase();
	return SM_ERR[k] || (SM_ERR.UNKNOWN + " (" + key + ")");
}

function smEsc(s) {
	return String(s === null || s === undefined ? "" : s)
		.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;");
}

function smGet(action, params) {
	params = params || {};
	params.action = action;
	return $.ajax({ url: "ajax.cgi", type: "GET", data: params, dataType: "json" });
}

function smPost(action, params) {
	params = params || {};
	params.action = action;
	return $.ajax({ url: "ajax.cgi", type: "POST", data: params, dataType: "json" });
}

function smMsg(id, text, kind) {
	var el = $("#" + id);
	if (!el.length) { return; }
	el.removeClass("sm-msg-ok sm-msg-err")
	  .addClass(kind === "err" ? "sm-msg-err" : "sm-msg-ok")
	  .text(text).show();
}

// ======================================================================
// Miniserver selector - shared by all three tabs
// ======================================================================

var smMsnr = null;

function smInitMiniservers(onReady) {
	smGet("miniservers").done(function(r) {
		if (!r.ok) { smMsg("inv-message", smErr(r.error), "err"); return; }
		var list = r.miniservers || [];
		var sel  = $("#ms-select");
		sel.empty();
		$.each(list, function(i, m) {
			sel.append($("<option>").val(m.msnr).text(m.name || ("#" + m.msnr)));
		});
		if (list.length > 1) { $("#ms-row").show(); }
		smMsnr = list.length ? list[0].msnr : null;
		sel.val(smMsnr);
		sel.off("change").on("change", function() {
			smMsnr = $(this).val();
			onReady();
		});
		onReady();
	});
}

// ======================================================================
// Overview
// ======================================================================

var smInventory = [];
var smSaved     = { source: null, targets: {} };
var smTokens    = {};

function smTypeLabel(t) {
	if (t === "tablet") { return SM_L.TYPE_TABLET; }
	if (t === "admin")  { return SM_L.TYPE_ADMIN; }
	return SM_L.TYPE_USER;
}

function smTokenBadge(state) {
	if (state === "ok")      { return '<span class="sm-badge sm-badge-ok">' + SM_L.TOKEN_OK + '</span>'; }
	if (state === "expired") { return '<span class="sm-badge sm-badge-warn">' + SM_L.TOKEN_EXPIRED + '</span>'; }
	return '<span class="sm-badge sm-badge-none">' + SM_L.TOKEN_NONE + '</span>';
}

function smRenderInventory(inv) {
	var body = $("#inv-body").empty();

	$.each(inv.entries, function(i, e) {
		var isTablet = (e.type === "tablet");
		var tr = $("<tr>").attr("data-uuid", e.uuid);

		// A user without a sorting cannot be a source - saying so in the row
		// itself saves a trip to a help text.
		var src = e.has_sorting
			? '<input type="radio" name="source" class="source-rb" value="' + smEsc(e.uuid) + '">'
			: '';
		tr.append($('<td class="sm-col-narrow">').html(src));

		tr.append($('<td class="sm-col-narrow">').html(
			'<input type="checkbox" class="target-cb" value="' + smEsc(e.uuid) + '">'));

		tr.append($("<td>").text(e.name || "?"));
		tr.append($("<td>").text(smTypeLabel(e.type)));
		tr.append($("<td>").html(e.has_sorting
			? SM_L.YES
			: '<span class="sm-nosorting">' + SM_L.NOSORTING + "</span>"));
		tr.append($("<td>").text(e.ts_local || "–"));
		tr.append($('<td class="sm-token">').html(isTablet ? "–" : smTokenBadge(smTokens[e.uuid])));

		// A managed tablet has no password of its own: FTP plus a reboot is the
		// only way in, so the choice is not offered.
		var method;
		if (isTablet) {
			method = '<span>' + SM_L.METHOD_REBOOT + '</span>';
		} else {
			method = '<select class="lb-input method-sel">' +
				'<option value="token">'  + SM_L.METHOD_TOKEN  + '</option>' +
				'<option value="reboot">' + SM_L.METHOD_REBOOT + '</option></select>';
		}
		tr.append($("<td>").html(method));
		body.append(tr);
	});

	if (inv.orphans && inv.orphans.length) {
		$("#inv-orphans").text(SM_L.ORPHANS.replace("%d", inv.orphans.length)).show();
	} else {
		$("#inv-orphans").hide();
	}

	// Restore the saved selection
	if (smSaved.source) { $('.source-rb[value="' + smSaved.source + '"]').prop("checked", true); }
	$.each(smSaved.targets, function(uuid, t) {
		$('.target-cb[value="' + uuid + '"]').prop("checked", true);
		if (t.method) {
			$('tr[data-uuid="' + uuid + '"] .method-sel').val(t.method);
		}
	});
	smSyncSourceRow();
}

// One row cannot be source and target at once.
function smSyncSourceRow() {
	$("#inv-body tr").each(function() {
		var tr = $(this);
		var isSource = tr.find(".source-rb").prop("checked");
		var cb = tr.find(".target-cb");
		if (isSource) { cb.prop("checked", false); }
		cb.prop("disabled", isSource);
	});
}

function smCollectTargets() {
	var out = [];
	$("#inv-body tr").each(function() {
		var tr = $(this);
		if (!tr.find(".target-cb").prop("checked")) { return; }
		var uuid = tr.attr("data-uuid");
		var e    = null;
		$.each(smInventory, function(i, x) { if (x.uuid === uuid) { e = x; } });
		if (!e) { return; }
		var sel = tr.find(".method-sel");
		out.push({
			uuid:   uuid,
			name:   e.name,
			type:   e.type,
			method: (e.type === "tablet") ? "reboot" : (sel.val() || "token")
		});
	});
	return out;
}

function smLoadOverview() {
	$("#inv-body").html('<tr><td colspan="8">' + SM_L.LOADING + "</td></tr>");
	$("#inv-message").hide();

	smGet("config", { msnr: smMsnr }).done(function(c) {
		smSaved = { source: null, targets: {} };
		if (c.ok && c.config) {
			smSaved.source = c.config.source || null;
			$.each(c.config.targets || [], function(i, t) { smSaved.targets[t.uuid] = t; });
			$("#auto-reboot").prop("checked", !!(c.config.watch && c.config.watch.auto_reboot));
		}

		smGet("inventory", { msnr: smMsnr }).done(function(inv) {
			if (!inv.ok) {
				$("#inv-body").empty();
				smMsg("inv-message", smErr(inv.error), "err");
				return;
			}
			smInventory = inv.entries || [];
			smRenderInventory(inv);

			// Asked for separately so the table is on screen first.
			smGet("tokenstatus", { msnr: smMsnr }).done(function(t) {
				if (!t.ok) { return; }
				smTokens = t.token || {};
				$("#inv-body tr").each(function() {
					var tr = $(this);
					var uuid = tr.attr("data-uuid");
					var e = null;
					$.each(smInventory, function(i, x) { if (x.uuid === uuid) { e = x; } });
					if (e && e.type !== "tablet") {
						tr.find(".sm-token").html(smTokenBadge(smTokens[uuid]));
					}
				});
			});
		});
	});
}

function smSaveSelection(quiet) {
	var source  = $(".source-rb:checked").val() || null;
	var targets = smCollectTargets();
	return smPost("saveconfig", {
		msnr: smMsnr,
		data: JSON.stringify({
			source:  source,
			targets: targets,
			watch:   { auto_reboot: $("#auto-reboot").prop("checked") ? 1 : 0 }
		})
	}).done(function(r) {
		if (!quiet) {
			r.ok ? smMsg("inv-message", SM_L.SAVED, "ok")
			     : smMsg("inv-message", smErr(r.error), "err");
		}
	});
}

// Which targets need a password? Only token targets without a valid one.
function smNeedPasswords(targets) {
	var need = [];
	$.each(targets, function(i, t) {
		if (t.type === "tablet" || t.method !== "token") { return; }
		var st = smTokens[t.uuid];
		if (st !== "ok") { need.push(t); }
	});
	return need;
}

function smStartCopy(source, targets, passwords) {
	smPost("copy", {
		msnr:        smMsnr,
		source:      source,
		targets:     JSON.stringify(targets),
		auto_reboot: $("#auto-reboot").prop("checked") ? 1 : 0,
		passwords:   JSON.stringify(passwords || {})
	}).done(function(r) {
		if (!r.ok) { smMsg("inv-message", smErr(r.error), "err"); return; }
		$("#inv-message").hide();
		smPollJob();
	});
}

function smCopy() {
	var source  = $(".source-rb:checked").val();
	var targets = smCollectTargets();
	if (!source)        { smMsg("inv-message", SM_L.NO_SOURCE, "err"); return; }
	if (!targets.length) { smMsg("inv-message", SM_L.NO_TARGET, "err"); return; }

	// Saving first: the selection is what the watch will use later.
	smSaveSelection(true);

	var need = smNeedPasswords(targets);
	if (!need.length) { smStartCopy(source, targets, {}); return; }

	var box = $("#pw-fields").empty();
	$.each(need, function(i, t) {
		box.append(
			$('<div class="sm-pw-row">')
				.append($("<label>").text(SM_L.PW_FOR + " " + t.name))
				.append($('<input type="password" class="lb-input sm-pw">')
					.attr("data-name", t.name).attr("autocomplete", "new-password"))
		);
	});
	$("#pw-dialog").show();
	$("#btn-pw-ok").off("click").on("click", function() {
		var pw = {};
		$(".sm-pw").each(function() { pw[$(this).attr("data-name")] = $(this).val(); });
		$("#pw-dialog").hide();
		smStartCopy(source, targets, pw);
	});
}

// ======================================================================
// Job progress - the same box serves copy, backup and restore
// ======================================================================

var smJobTimer = null;

function smPollJob() {
	$("#job-box").show();
	$("#job-title").text(SM_L.JOB_RUNNING);
	$("#job-list").empty();

	if (smJobTimer) { clearInterval(smJobTimer); }
	var tick = function() {
		smGet("jobstatus").done(function(r) {
			var j = (r && r.job) || {};
			if (!j.state) { return; }

			var list = $("#job-list").empty();
			$.each(j.results || [], function(i, res) {
				var text = res.name + ": " + (res.ok ? "✓" : "✗ " + smErr(res.error));
				if (res.ok && res.entries !== undefined && res.entries !== null) {
					text = res.name + ": ✓ " + res.entries;
				}
				list.append($("<li>").text(text));
			});
			$.each(j.missing || [], function(i, m) {
				list.append($("<li>").addClass("sm-gone")
					.text(m.name + ": " + SM_L.RESTORE_MISSING));
			});

			if (j.state !== "done") {
				$("#job-title").text(SM_L.JOB_RUNNING + " (" + (j.done || 0) + "/" + (j.total || 0) + ")");
				return;
			}

			clearInterval(smJobTimer);
			smJobTimer = null;
			$("#job-title").text(j.failed ? SM_L.JOB_FAILED : SM_L.JOB_DONE);
			if (j.reboot_pending) {
				list.append($("<li>").text(SM_L.REBOOT_PENDING));
			}
			if ($("#inv-body").length)   { smLoadOverview(); }
			if ($("#backup-list").length) { smLoadBackups(); }
		});
	};
	smJobTimer = setInterval(tick, 2000);
	tick();
}

// ======================================================================
// Watch
// ======================================================================

function smLoadWatch() {
	smGet("config", { msnr: smMsnr }).done(function(r) {
		if (!r.ok) { smMsg("watch-message", smErr(r.error), "err"); return; }
		var c = r.config || {};
		var w = c.watch || {};

		var configured = !!(c.source && c.targets && c.targets.length);
		$("#watch-notconfigured").toggle(!configured);
		$("#watch-enabled, #btn-watch-now, #btn-watch-save").prop("disabled", !configured);

		$("#watch-enabled").prop("checked", !!w.enabled);
		$("#watch-interval").val(w.interval_min || 15);
		$("#watch-reboot").prop("checked", !!w.auto_reboot);
		$("#watch-last").text(w.last_run ? smLoxLocal(w.last_run) : SM_L.NEVER);
		$("#watch-lastts").text(w.last_source_ts ? smLoxLocal(w.last_source_ts) : SM_L.NEVER);
	});
}

// The Miniserver counts seconds from 2009-01-01 UTC.
function smLoxLocal(lox) {
	if (!lox) { return SM_L.NEVER; }
	var d = new Date((Date.UTC(2009, 0, 1) / 1000 + Number(lox)) * 1000);
	var p = function(n) { return (n < 10 ? "0" : "") + n; };
	return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate()) +
	       " " + p(d.getHours()) + ":" + p(d.getMinutes());
}

function smSaveWatch() {
	smPost("saveconfig", {
		msnr: smMsnr,
		data: JSON.stringify({
			watch: {
				enabled:      $("#watch-enabled").prop("checked") ? 1 : 0,
				interval_min: Number($("#watch-interval").val()) || 15,
				auto_reboot:  $("#watch-reboot").prop("checked") ? 1 : 0
			}
		})
	}).done(function(r) {
		r.ok ? smMsg("watch-message", SM_L.SAVED, "ok")
		     : smMsg("watch-message", smErr(r.error), "err");
		if (r.ok) { smLoadWatch(); }
	});
}

function smWatchNow() {
	smMsg("watch-message", SM_L.LOADING, "ok");
	smPost("watchnow", { msnr: smMsnr }).done(function(r) {
		if (!r.ok) {
			smMsg("watch-message", smErr(r.reason || r.error), "err");
			return;
		}
		smMsg("watch-message", r.changed ? SM_L.RAN_CHANGED : SM_L.RAN_UNCHANGED, "ok");
		smLoadWatch();
	});
}

// ======================================================================
// Backup
// ======================================================================

var SM_DAYS = ["<TMPL_VAR COMMON.SUN>", "<TMPL_VAR COMMON.MON>", "<TMPL_VAR COMMON.TUE>",
               "<TMPL_VAR COMMON.WED>", "<TMPL_VAR COMMON.THU>", "<TMPL_VAR COMMON.FRI>",
               "<TMPL_VAR COMMON.SAT>"];

function smRenderDays(selected) {
	var box = $("#sched-days").empty();
	$.each(SM_DAYS, function(i, name) {
		var cb = $('<input type="checkbox" class="sched-day">').val(i);
		if ($.inArray(i, selected || []) >= 0) { cb.prop("checked", true); }
		box.append($("<label>").append(cb).append(" " + name));
	});
}

function smLoadBackupConfig() {
	smGet("config", { msnr: smMsnr }).done(function(r) {
		var b = (r.ok && r.config && r.config.backup) ? r.config.backup : {};
		var s = b.schedule || {};
		$("#backup-keep").val(b.keep || 10);
		$("#sched-enabled").prop("checked", !!s.enabled);
		$("#sched-hour").val(s.hour === undefined ? 3 : s.hour);
		$("#sched-minute").val(s.minute === undefined ? 0 : s.minute);
		$("#sched-weeks").val(s.every_weeks || 1);
		smRenderDays($.map(s.days || [], function(d) { return Number(d); }));
	});
}

function smSaveBackupConfig() {
	var days = [];
	$(".sched-day:checked").each(function() { days.push(Number($(this).val())); });
	smPost("saveconfig", {
		msnr: smMsnr,
		data: JSON.stringify({
			backup: {
				keep: Number($("#backup-keep").val()) || 10,
				schedule: {
					enabled:     $("#sched-enabled").prop("checked") ? 1 : 0,
					days:        days,
					hour:        Number($("#sched-hour").val()) || 0,
					minute:      Number($("#sched-minute").val()) || 0,
					every_weeks: Number($("#sched-weeks").val()) || 1
				}
			}
		})
	}).done(function(r) {
		r.ok ? smMsg("backup-message", SM_L.SAVED, "ok")
		     : smMsg("backup-message", smErr(r.error), "err");
	});
}

function smLoadBackups() {
	smGet("backups", { msnr: smMsnr }).done(function(r) {
		var body = $("#backup-list").empty();
		if (!r.ok) {
			body.append($("<tr>").append($("<td colspan=4>").text(smErr(r.error))));
			return;
		}
		if (!r.backups.length) {
			body.append($("<tr>").append($("<td colspan=4>").text(SM_L.NONE_YET)));
			return;
		}
		$.each(r.backups, function(i, b) {
			var actions = $("<td>");
			actions.append($('<button type="button" class="lb-btn">')
				.text(SM_L.BTN_RESTORE)
				.on("click", function() { smOpenRestore(b.file); }));
			actions.append(" ");
			actions.append($('<button type="button" class="lb-btn">')
				.text(SM_L.BTN_DELETE)
				.on("click", function() { smDeleteBackup(b.file); }));

			body.append($("<tr>")
				.append($("<td>").text(b.created_local || "–"))
				.append($("<td>").text(Math.round(b.bytes / 1024) + " kB"))
				.append($("<td>").text(b.entries === null ? "?" : b.entries))
				.append(actions));
		});
	});
}

function smBackupNow() {
	smPost("backupnow", { msnr: smMsnr }).done(function(r) {
		if (!r.ok) { smMsg("backup-message", smErr(r.error), "err"); return; }
		$("#backup-message").hide();
		smPollJob();
	});
}

function smDeleteBackup(file) {
	if (!window.confirm(SM_L.DELETE_CONFIRM)) { return; }
	smPost("deletebackup", { file: file }).done(function(r) {
		if (!r.ok) { smMsg("backup-message", smErr(r.error), "err"); return; }
		smLoadBackups();
	});
}

var smRestoreFile = null;

function smOpenRestore(file) {
	smRestoreFile = file;
	var box = $("#restore-entries").html(SM_L.LOADING);
	$("#restore-dialog").show();

	smGet("checkrestore", { file: file, msnr: smMsnr }).done(function(r) {
		if (!r.ok) { box.text(smErr(r.error)); return; }
		var m = r.manifest || {};
		$("#restore-info").text((m.created_local || "") + " · " +
			(m.miniserver ? m.miniserver.serial : "") );
		box.empty();
		$.each(m.entries || [], function(i, e) {
			var label = $('<label class="sm-entry">');
			var cb = $('<input type="checkbox" class="restore-cb">').val(e.uuid);
			if (e.alive) {
				cb.prop("checked", true);
			} else {
				cb.prop("disabled", true);
				label.addClass("sm-gone");
			}
			label.append(cb).append(" " + e.name + " (" + e.type + ")" +
				(e.alive ? "" : " – " + SM_L.RESTORE_MISSING));
			box.append(label);
		});
	});
}

function smDoRestore() {
	var only = [];
	$(".restore-cb:checked").each(function() { only.push($(this).val()); });
	$("#restore-dialog").hide();
	smPost("restore", {
		msnr:        smMsnr,
		file:        smRestoreFile,
		only:        JSON.stringify(only),
		auto_reboot: $("#restore-reboot").prop("checked") ? 1 : 0
	}).done(function(r) {
		if (!r.ok) { smMsg("backup-message", smErr(r.error), "err"); return; }
		smPollJob();
	});
}

// ======================================================================
// Wiring - each tab brings only its own elements
// ======================================================================

$(document).ready(function() {

	if ($("#inv-table").length) {
		smInitMiniservers(smLoadOverview);
		$("#inv-body").on("change", ".source-rb", smSyncSourceRow);
		$("#btn-save-selection").on("click", function() { smSaveSelection(false); });
		$("#btn-copy").on("click", smCopy);
		$("#btn-pw-cancel").on("click", function() { $("#pw-dialog").hide(); });
	}

	if ($("#watch-form").length) {
		smInitMiniservers(smLoadWatch);
		$("#btn-watch-save").on("click", smSaveWatch);
		$("#btn-watch-now").on("click", smWatchNow);
	}

	if ($("#backup-table").length) {
		smInitMiniservers(function() { smLoadBackupConfig(); smLoadBackups(); });
		$("#btn-backup-now").on("click", smBackupNow);
		$("#btn-backup-save").on("click", smSaveBackupConfig);
		$("#btn-restore-cancel").on("click", function() { $("#restore-dialog").hide(); });
		$("#btn-restore-confirm").on("click", smDoRestore);
	}

});

</script>
