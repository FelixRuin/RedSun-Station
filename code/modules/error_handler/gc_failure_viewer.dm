// GC failure viewing datums, responsible for storing individual GC failure info
// and showing them to admins on demand.
//
// Modeled after error_viewer.dm. There are 3 different types used here:
//
// - gc_failure_cache keeps track of all failure sources, as well as all
//   individually logged failures. Only one instance should ever exist:

GLOBAL_DATUM_INIT(gc_failure_cache, /datum/gc_failure_viewer/gc_failure_cache, new)

// - gc_failure_source datums exist for each type path that generates a GC failure,
//   and keep track of all failures for that type.
//
// - gc_failure_entry datums exist for each logged GC failure, and keep track of
//   all relevant info about that failure.

// Common vars and procs are kept at the gc_failure_viewer level
/datum/gc_failure_viewer
	var/name = ""

/datum/gc_failure_viewer/proc/browse_to(client/user, html)
	var/datum/browser/browser = new(user.mob, "gc_failure_viewer", null, 700, 500)
	browser.set_content(html)
	browser.add_head_content({"
	<style>
	.gc_failure
	{
		background-color: #171717;
		border: solid 1px #202020;
		font-family: "Courier New";
		padding-left: 10px;
		color: #CCCCCC;
	}
	.gc_failure_line
	{
		margin-bottom: 10px;
		display: inline-block;
	}
	</style>
	"})
	browser.open()

/datum/gc_failure_viewer/proc/build_header(datum/gc_failure_viewer/back_to, linear)
	. = ""

	if (istype(back_to))
		. += back_to.make_link("<b>&lt;&lt;&lt;</b>", null, linear)

	. += "[make_link("Refresh")]<br><br>"

/datum/gc_failure_viewer/proc/show_to(user, datum/gc_failure_viewer/back_to, linear)
	return

/datum/gc_failure_viewer/proc/make_link(linktext, datum/gc_failure_viewer/back_to, linear)
	var/back_to_param = ""
	if (!linktext)
		linktext = name

	if (istype(back_to))
		back_to_param = ";viewgcfailure_backto=[REF(back_to)]"

	if (linear)
		back_to_param += ";viewgcfailure_linear=1"

	return "<a href='?_src_=holder;[HrefToken()];viewgcfailure=[REF(src)][back_to_param]'>[linktext]</a>"

/datum/gc_failure_viewer/gc_failure_cache
	var/list/failures = list()
	var/list/failure_sources = list()
	var/total_failures = 0

/datum/gc_failure_viewer/gc_failure_cache/show_to(user, datum/gc_failure_viewer/back_to, linear)
	var/html = build_header()
	html += "<b>[total_failures]</b> GC failures<br><br>"
	if (!linear)
		html += "organized | [make_link("linear", null, 1)]<hr>"
		for (var/type_key in failure_sources)
			var/datum/gc_failure_viewer/gc_failure_source/source = failure_sources[type_key]
			html += "[source.make_link(null, src)]<br>"

	else
		html += "[make_link("organized", null)] | linear<hr>"
		for (var/datum/gc_failure_viewer/gc_failure_entry/entry in failures)
			html += "[entry.make_link(null, src, 1)]<br>"

	browse_to(user, html)

/datum/gc_failure_viewer/gc_failure_cache/proc/log_gc_failure(datum/D, type_path, ref_id, queued_time)
	total_failures++
	var/type_key = "[type_path]"
	var/datum/gc_failure_viewer/gc_failure_source/source = failure_sources[type_key]
	if (!source)
		source = new(type_path)
		failure_sources[type_key] = source

	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(D, type_path, ref_id, queued_time)
	entry.failure_source = source
	failures += entry
	source.failures += entry

/datum/gc_failure_viewer/gc_failure_source
	var/list/failures = list()
	var/type_path

/datum/gc_failure_viewer/gc_failure_source/New(path)
	type_path = path
	name = "<b>[path]</b>"

/datum/gc_failure_viewer/gc_failure_source/make_link(linktext, datum/gc_failure_viewer/back_to, linear)
	if (!linktext)
		linktext = "<b>[type_path]</b> ([length(failures)] failure[length(failures) != 1 ? "s" : ""])"
	return ..(linktext, back_to, linear)

/datum/gc_failure_viewer/gc_failure_source/show_to(user, datum/gc_failure_viewer/back_to, linear)
	if (!istype(back_to))
		back_to = GLOB.gc_failure_cache

	var/html = build_header(back_to)
	html += "<b>[type_path]</b> - [length(failures)] failure[length(failures) != 1 ? "s" : ""]<hr>"
	for (var/datum/gc_failure_viewer/gc_failure_entry/entry in failures)
		html += "[entry.make_link(null, src)]<br>"

	browse_to(user, html)

/datum/gc_failure_viewer/gc_failure_entry
	var/datum/gc_failure_viewer/gc_failure_source/failure_source
	var/type_path
	var/ref_id
	var/obj_name
	var/failure_time
	var/queued_time
	var/extra_info
	var/datum_ref

/datum/gc_failure_viewer/gc_failure_entry/New(datum/D, path, refid, queuetime)
	type_path = path
	ref_id = refid
	failure_time = world.time
	queued_time = queuetime
	if (D)
		if (isatom(D))
			var/atom/A = D
			obj_name = A.name
		datum_ref = REF(D)
		extra_info = build_extra_info(D)
	name = "<b>\[[TIME_STAMP("hh:mm:ss", FALSE)]]</b> GC failure: <b>[type_path]</b>[obj_name ? " \"[html_encode(obj_name)]\"" : ""] ([ref_id])"

/datum/gc_failure_viewer/gc_failure_entry/proc/build_extra_info(datum/D)
	var/list/info = list()

	if (istype(D, /atom/movable/screen))
		var/atom/movable/screen/S = D
		if (S.screen_loc)
			info += "screen_loc: [S.screen_loc]"
		if (S.assigned_map)
			info += "map: [S.assigned_map]"

	if (isatom(D))
		var/atom/A = D
		if (A.loc)
			var/loc_text = "[A.loc.type]"
			if (isatom(A.loc))
				var/atom/loc_atom = A.loc
				if (loc_atom.name)
					loc_text += " \"[loc_atom.name]\""
			info += "loc: [loc_text]"
		else
			info += "loc: null"
		if (isturf(A) || isturf(A.loc))
			info += "coords: [A.x],[A.y],[A.z]"

	if (ismob(D))
		var/mob/M = D
		if (M.ckey)
			info += "ckey: [M.ckey]"
		else if (M.key)
			info += "key: [M.key]"

	if (!length(info))
		return null
	return info.Join(" | ")

/datum/gc_failure_viewer/gc_failure_entry/show_to(user, datum/gc_failure_viewer/back_to, linear)
	if (!istype(back_to))
		back_to = failure_source

	var/html = build_header(back_to, linear)
	html += "<div class='gc_failure'>"
	html += "<span class='gc_failure_line'><b>Тип:</b> [type_path]</span><br>"
	html += "<span class='gc_failure_line'><b>Ref:</b> [ref_id]</span><br>"
	if (obj_name)
		html += "<span class='gc_failure_line'><b>Имя:</b> [html_encode(obj_name)]</span><br>"
	if (extra_info)
		html += "<span class='gc_failure_line'><b>Доп. инфо:</b> [html_encode(extra_info)]</span><br>"
	html += "<span class='gc_failure_line'><b>Время фейла:</b> [DisplayTimeText(failure_time)] от начала раунда</span><br>"
	if (queued_time)
		html += "<span class='gc_failure_line'><b>В очереди GC:</b> ~[DisplayTimeText(failure_time - queued_time)]</span><br>"
	html += "</div>"

	if (datum_ref)
		var/datum/D = locate(datum_ref)
		if (D && D.type == text2path(type_path))
			html += "<br><b>Объект</b>: <a href='?_src_=vars;[HrefToken()];Vars=[datum_ref]'>VV</a>"
		else
			html += "<br><b>Объект</b>: больше не существует ([ref_id])"

	browse_to(user, html)
