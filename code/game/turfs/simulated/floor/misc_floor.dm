/* BLUEMOON DELETE переход на декали
/turf/open/floor/goonplaque
	name = "commemorative plaque"
	icon_state = "plaque"
	desc = "\"This is a plaque in honour of our comrades on the G4407 Stations. Hopefully TG4407 model can live up to your fame and fortune.\" Scratched in beneath that is a crude image of a meteor and a spaceman. The spaceman is laughing. The meteor is exploding."
	floor_tile = /obj/item/stack/tile/plasteel
	tiled_dirt = FALSE
*/

/turf/open/floor/vault
	icon_state = "rockvault"
	floor_tile = /obj/item/stack/tile/plasteel

//Circuit flooring, glows a little
/turf/open/floor/circuit
	icon = 'icons/turf/floors.dmi'
	icon_state = "bcircuit"
	var/icon_normal = "bcircuit"
	light_color = LIGHT_COLOR_CYAN
	floor_tile = /obj/item/stack/tile/circuit
	var/on = TRUE

/turf/open/floor/circuit/Initialize(mapload)
	SSmapping.nuke_tiles += src
	update_icon()
	. = ..()

/turf/open/floor/circuit/Destroy()
	SSmapping.nuke_tiles -= src
	return ..()

/turf/open/floor/circuit/update_icon()
	. = ..()
	if(on)
		if(LAZYLEN(SSmapping.nuke_threats))
			icon_state = "rcircuitanim"
			light_color = LIGHT_COLOR_FLARE
		else
			icon_state = icon_normal
			light_color = initial(light_color)
		set_light(1.4, 0.5)
	else
		icon_state = "[icon_normal]off"
		set_light(0)

/turf/open/floor/circuit/off
	icon_state = "bcircuitoff"
	on = FALSE

/turf/open/floor/circuit/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/circuit/telecomms
	initial_gas_mix = TCOMMS_ATMOS

/turf/open/floor/circuit/telecomms/mainframe
	name = "mainframe base"

/turf/open/floor/circuit/telecomms/server
	name = "server base"

/turf/open/floor/circuit/green
	icon_state = "gcircuit"
	icon_normal = "gcircuit"
	light_color = LIGHT_COLOR_GREEN
	floor_tile = /obj/item/stack/tile/circuit/green

/turf/open/floor/circuit/green/off
	icon_state = "gcircuitoff"
	on = FALSE

/turf/open/floor/circuit/green/anim
	icon_state = "gcircuitanim"
	icon_normal = "gcircuitanim"
	floor_tile = /obj/item/stack/tile/circuit/green/anim

/turf/open/floor/circuit/green/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/circuit/green/telecomms
	initial_gas_mix = TCOMMS_ATMOS

/turf/open/floor/circuit/green/telecomms/mainframe
	name = "mainframe base"

/turf/open/floor/circuit/red
	icon_state = "rcircuit"
	icon_normal = "rcircuit"
	light_color = LIGHT_COLOR_FLARE
	floor_tile = /obj/item/stack/tile/circuit/red

/turf/open/floor/circuit/red/off
	icon_state = "rcircuitoff"
	on = FALSE

/turf/open/floor/circuit/red/anim
	icon_state = "rcircuitanim"
	icon_normal = "rcircuitanim"
	floor_tile = /obj/item/stack/tile/circuit/red/anim

/turf/open/floor/circuit/red/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/circuit/red/telecomms
	initial_gas_mix = TCOMMS_ATMOS

/turf/open/floor/pod
	name = "pod floor"
	icon_state = "podfloor"
	floor_tile = /obj/item/stack/tile/pod

/turf/open/floor/pod/light
	icon_state = "podfloor_light"
	floor_tile = /obj/item/stack/tile/pod/light

/turf/open/floor/pod/dark
	icon_state = "podfloor_dark"
	floor_tile = /obj/item/stack/tile/pod/dark


/turf/open/floor/noslip
	name = "high-traction floor"
	icon_state = "noslip"
	floor_tile = /obj/item/stack/tile/noslip
	broken_states = list("noslip-damaged1","noslip-damaged2","noslip-damaged3")
	burnt_states = list("noslip-scorched1","noslip-scorched2")
	slowdown = -0.3

/turf/open/floor/noslip/MakeSlippery(wet_setting, min_wet_time, wet_time_to_add, max_wet_time, permanent)
	return

/turf/open/floor/oldshuttle
	icon = 'icons/turf/shuttleold.dmi'
	icon_state = "floor"
	floor_tile = /obj/item/stack/tile/plasteel

//Clockwork floor: Slowly heals toxin damage on nearby servants.
/turf/open/floor/clockwork
	name = "clockwork floor"
	desc = "Tightly-pressed brass tiles. They emit minute vibration."
	icon_state = "plating"
	baseturfs = /turf/open/floor/clockwork
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	var/dropped_brass
	var/uses_overlay = TRUE
	var/obj/effect/clockwork/overlay/floor/realappearence

/turf/open/floor/clockwork/Bless() //Who needs holy blessings when you have DADDY RATVAR?
	return

/turf/open/floor/clockwork/Initialize(mapload)
	. = ..()
	if(uses_overlay)
		new /obj/effect/temp_visual/ratvar/floor(src)
		new /obj/effect/temp_visual/ratvar/beam(src)
		realappearence = new /obj/effect/clockwork/overlay/floor(src)
		realappearence.linked = src

/turf/open/floor/clockwork/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(uses_overlay && realappearence)
		QDEL_NULL(realappearence)
	return ..()

/turf/open/floor/clockwork/ReplaceWithLattice()
	. = ..()
	for(var/obj/structure/lattice/L in src)
		L.ratvar_act()

/turf/open/floor/clockwork/Entered(atom/movable/AM)
	..()
	START_PROCESSING(SSobj, src)

/turf/open/floor/clockwork/process()
	if(!healservants())
		STOP_PROCESSING(SSobj, src)

/turf/open/floor/clockwork/proc/healservants()
	for(var/mob/living/L in src)
		if(L.stat == DEAD)
			continue
		. = 1
		if(!is_servant_of_ratvar(L) || !L.toxloss)
			continue

		var/image/I = new('icons/effects/effects.dmi', src, "heal", ABOVE_MOB_LAYER) //fake a healing glow for servants
		I.appearance_flags = RESET_COLOR
		I.color = "#5A6068"
		I.pixel_x = rand(-12, 12)
		I.pixel_y = rand(-9, 0)
		var/list/viewing = list()
		for(var/mob/M in viewers(src))
			if(M.client && (is_servant_of_ratvar(M) || isobserver(M) || M.stat == DEAD))
				viewing += M.client
		flick_overlay(I, viewing, 8)
		L.adjustToxLoss(-3, TRUE, TRUE, toxins_type = TOX_OMNI)

/turf/open/floor/clockwork/try_replace_tile(obj/item/stack/tile/T, mob/user, params)
	return

/turf/open/floor/clockwork/crowbar_act(mob/living/user, obj/item/I)
	if(islist(baseturfs))
		if(type in baseturfs)
			return TRUE
	else if(baseturfs == type)
		return TRUE
	user.visible_message("<span class='notice'>[user] begins slowly prying up [src]...</span>", "<span class='notice'>You begin painstakingly prying up [src]...</span>")
	if(I.use_tool(src, user, 70, volume=80))
		user.visible_message("<span class='notice'>[user] pries up [src]!</span>", "<span class='notice'>You pry up [src]!</span>")
		make_plating()
	return TRUE

/turf/open/floor/clockwork/make_plating()
	if(!dropped_brass)
		new /obj/item/stack/tile/brass(src)
		dropped_brass = TRUE
	if(islist(baseturfs))
		if(type in baseturfs)
			return
	else if(baseturfs == type)
		return
	return ..()

/turf/open/floor/clockwork/narsie_act()
	..()
	if(istype(src, /turf/open/floor/clockwork)) //if we haven't changed type
		var/previouscolor = color
		color = "#960000"
		animate(src, color = previouscolor, time = 8)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 8)

/turf/open/floor/clockwork/reebe
	name = "cogplate"
	desc = "Warm brass plating. You can feel it gently vibrating, as if machinery is on the other side."
	icon_state = "reebe"
	baseturfs = /turf/open/floor/clockwork/reebe
	uses_overlay = FALSE
	planetary_atmos = TRUE

/turf/open/floor/bluespace
	slowdown = -1
	icon_state = "bluespace"
	desc = "Through a series of micro-teleports these tiles let people move at incredible speeds."
	floor_tile = /obj/item/stack/tile/bluespace


/turf/open/floor/sepia
	slowdown = 2
	icon_state = "sepia"
	desc = "Time seems to flow very slowly around these tiles."
	floor_tile = /obj/item/stack/tile/sepia


/turf/open/floor/bronze
	name = "bronze floor"
	desc = "Some heavy bronze tiles."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "clockwork_floor"
	floor_tile = /obj/item/stack/sheet/bronze

/turf/open/floor/padded
	name = "padded floor"
	desc = "Keeps crazy people from hurting themselves. It's soft, plush, and very nice to get shoved against."
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor_padded"
	floor_tile = /obj/item/stack/tile/padded

/turf/open/floor/plating/rust
	name = "rusted plating"
	desc = "Corrupted steel."
	icon_state = "plating_rust"
	footstep = FOOTSTEP_RUST
	barefootstep = FOOTSTEP_RUST
	clawfootstep = FOOTSTEP_RUST
	heavyfootstep = FOOTSTEP_RUST

/turf/open/floor/plating/rust/rust_heretic_act()
	return


/turf/open/floor/plating/elevatorshaft
	name = "elevator shaft"
	icon_state = "elevatorshaft"
	base_icon_state = "elevatorshaft"
