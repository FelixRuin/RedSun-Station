/datum/wires/airlock
	holder_type = /obj/machinery/door/airlock
	proper_name = "Generic Airlock"
	req_skill = JOB_SKILL_UNTRAINED //Training wheel, as per request.
	visibility_trait = TRAIT_KNOW_ENGI_WIRES // BLUEMOON ADD
	var/wiretype

/datum/wires/airlock/secure
	randomize = TRUE

/datum/wires/airlock/command
	proper_name = "Command Airlock"
	wiretype = "commandairlock"

/datum/wires/airlock/security
	proper_name = "Security Airlock"
	wiretype = "securityairlock"

/datum/wires/airlock/engineering
	proper_name = "Engineering Airlock"
	wiretype = "engineeringairlock"

/datum/wires/airlock/science
	proper_name = "Science Airlock"
	wiretype = "scienceairlock"

/datum/wires/airlock/medical
	proper_name = "Medical Airlock"
	wiretype = "medicalairlock"

/datum/wires/airlock/cargo
	proper_name = "Cargo Airlock"
	wiretype = "cargoairlock"

/datum/wires/airlock/New(atom/holder)
	wires = list(
		WIRE_POWER1, WIRE_POWER2,
		WIRE_BACKUP1, WIRE_BACKUP2,
		WIRE_OPEN, WIRE_BOLTS, WIRE_IDSCAN, WIRE_AI,
		WIRE_SHOCK, WIRE_SAFETY, WIRE_TIMING, WIRE_LIGHT,
		WIRE_ZAP1, WIRE_ZAP2
	)
	add_duds(2)
	. = ..()
	if(randomize || !wiretype)
		return
	if(!GLOB.wire_color_directory[wiretype])
		colors = list()
		randomize()
		GLOB.wire_color_directory[wiretype] = colors
		GLOB.wire_name_directory[wiretype] = proper_name
	else
		colors = GLOB.wire_color_directory[wiretype]

/datum/wires/airlock/interactable(mob/user)
	var/obj/machinery/door/airlock/A = holder
	if(A.panel_open)
		return TRUE

/datum/wires/airlock/get_status()
	var/obj/machinery/door/airlock/A = holder
	var/list/status = list()
	status += "The door bolts [A.locked ? "have fallen!" : "look up."]"
	status += "The test light is [A.hasPower() ? "on" : "off"]."
	status += "The AI connection light is [A.aiControlDisabled || (A.obj_flags & EMAGGED) ? "off" : "on"]."
	status += "The check wiring light is [A.safe ? "off" : "on"]."
	status += "The timer is powered [A.autoclose ? "on" : "off"]."
	status += "The speed light is [A.normalspeed ? "on" : "off"]."
	status += "The emergency light is [A.emergency ? "on" : "off"]."
	return status

/datum/wires/airlock/on_pulse(wire)
	set waitfor = FALSE
	var/obj/machinery/door/airlock/A = holder
	if(usr && !A.hasSiliconAccessInArea(usr) && A.isElectrified() && A.shock(usr, 100))
		return FALSE
	switch(wire)
		if(WIRE_POWER1, WIRE_POWER2) // Pulse to loose power.
			A.loseMainPower()
		if(WIRE_BACKUP1, WIRE_BACKUP2) // Pulse to loose backup power.
			A.loseBackupPower()
		if(WIRE_OPEN) // Pulse to open door (only works not emagged and ID wire is cut or no access is required).
			if(A.obj_flags & EMAGGED)
				return
			if(!A.requiresID() || A.check_access(null))
				if(A.density)
					INVOKE_ASYNC(A, TYPE_PROC_REF(/obj/machinery/door/airlock, open))
				else
					INVOKE_ASYNC(A, TYPE_PROC_REF(/obj/machinery/door/airlock, close))
			else
				holder.visible_message("<span class='notice'>You hear a a grinding noise coming from the airlock.</span>")
		if(WIRE_BOLTS) // Pulse to toggle bolts (but only raise if power is on).
			if(!A.locked)
				A.bolt()
			else
				if(A.hasPower())
					A.unbolt()
			A.update_icon()
		if(WIRE_IDSCAN) // Pulse to disable emergency access and flash red lights.
			if(A.hasPower() && A.density)
				A.do_animate("deny")
				if(A.emergency)
					A.emergency = FALSE
					A.update_icon()
		if(WIRE_AI) // Pulse to disable WIRE_AI control for 10 ticks (follows same rules as cutting).
			if(A.aiControlDisabled == 0)
				A.aiControlDisabled = 1
			else if(A.aiControlDisabled == -1)
				A.aiControlDisabled = 2
			addtimer(CALLBACK(A, TYPE_PROC_REF(/obj/machinery/door/airlock, reset_ai_wire)), 1 SECONDS)
		if(WIRE_SHOCK) // Pulse to shock the door for 10 ticks.
			if(!A.secondsElectrified)
				A.set_electrified(30, usr)
		if(WIRE_SAFETY)
			A.safe = !A.safe
			if(!A.density)
				A.close()
		if(WIRE_TIMING)
			A.normalspeed = !A.normalspeed
		if(WIRE_LIGHT)
			A.lights = !A.lights
			A.update_icon()

/obj/machinery/door/airlock/proc/reset_ai_wire()
	if(aiControlDisabled == 1)
		aiControlDisabled = 0
	else if(aiControlDisabled == 2)
		aiControlDisabled = -1

/datum/wires/airlock/on_cut(wire, mend)
	var/obj/machinery/door/airlock/A = holder
	if(usr && !A.hasSiliconAccessInArea(usr) && A.isElectrified() && A.shock(usr, 100))
		return FALSE
	switch(wire)
		if(WIRE_POWER1, WIRE_POWER2) // Cut to loose power, repair all to gain power.
			if(mend && !is_cut(WIRE_POWER1) && !is_cut(WIRE_POWER2))
				A.regainMainPower()
			else
				A.loseMainPower()
			if(isliving(usr))
				A.shock(usr, 50)
		if(WIRE_BACKUP1, WIRE_BACKUP2) // Cut to loose backup power, repair all to gain backup power.
			if(mend && !is_cut(WIRE_BACKUP1) && !is_cut(WIRE_BACKUP2))
				A.regainBackupPower()
			else
				A.loseBackupPower()
			if(isliving(usr))
				A.shock(usr, 50)
		if(WIRE_BOLTS) // Cut to drop bolts, mend does nothing.
			if(!mend)
				A.bolt()
		if(WIRE_AI) // Cut to disable WIRE_AI control, mend to re-enable.
			if(mend)
				if(A.aiControlDisabled == 1) // 0 = normal, 1 = locked out, 2 = overridden by WIRE_AI, -1 = previously overridden by WIRE_AI
					A.aiControlDisabled = 0
				else if(A.aiControlDisabled == 2)
					A.aiControlDisabled = -1
			else
				if(A.aiControlDisabled == 0)
					A.aiControlDisabled = 1
				else if(A.aiControlDisabled == -1)
					A.aiControlDisabled = 2
		if(WIRE_SHOCK) // Cut to shock the door, mend to unshock.
			if(mend)
				if(A.secondsElectrified)
					A.set_electrified(0)
			else
				if(A.secondsElectrified != -1)
					A.set_electrified(-1, usr)
		if(WIRE_SAFETY) // Cut to disable safeties, mend to re-enable.
			A.safe = mend
		if(WIRE_TIMING) // Cut to disable auto-close, mend to re-enable.
			A.autoclose = mend
			if(A.autoclose && !A.density)
				A.close()
		if(WIRE_LIGHT) // Cut to disable lights, mend to re-enable.
			A.lights = mend
			A.update_icon()
		if(WIRE_ZAP1, WIRE_ZAP2) // Ouch.
			if(isliving(usr))
				A.shock(usr, 50)
