// Another smoke effect
/obj/effect/temp_visual/mook_dust/robot
	icon = 'modular_bluemoon/icons/effects/tallrobot_effects.dmi'
	icon_state = "impact_cloud"
	color = "#a9a9a93c"

/obj/effect/temp_visual/mook_dust/robot/table
	color = "#ffffffc2"
	pixel_y = -8
	layer = ABOVE_MOB_LAYER

/mob/living/silicon/robot/set_resting(new_resting, silent = FALSE, updating = TRUE)
	. = ..()
	if(. != new_resting && module && module.hasrest && !silent)
		var/turf/sit_pos = get_turf(src)
		var/obj/structure/table/tabled = locate(/obj/structure/table) in sit_pos.contents
		if(!tabled)
			new /obj/effect/temp_visual/mook_dust/robot(get_turf(src))
			playsound(src, 'modular_bluemoon/sound/effects/robot_sit.ogg', 25, TRUE)
		else
			new /obj/effect/temp_visual/mook_dust/robot/table(get_turf(src))
			playsound(src, 'modular_bluemoon/sound/effects/robot_bump.ogg', 50, TRUE)
