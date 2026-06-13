/// Visual starlight/parallax effects when eldritch entities warp the cosmos.

GLOBAL_VAR_INIT(narsie_cosmos_active, FALSE)
GLOBAL_VAR_INIT(infernal_cosmos_active, FALSE)
GLOBAL_VAR_INIT(ratvar_cosmos_active, FALSE)

#define COSMOS_PARALLAX_GREY list(0.25, 0.25, 0.25, 0, 0.25, 0.25, 0.25, 0, 0.25, 0.25, 0.25, 0, 0, 0, 0, 1, 0, 0, 0, 0)
#define COSMOS_PARALLAX_BLACK list(0.05, 0.05, 0.05, 0, 0.05, 0.05, 0.05, 0, 0.05, 0.05, 0.05, 0, 0, 0, 0, 0.6, 0, 0, 0, 0)
#define COSMOS_PARALLAX_NARSIE list(0.6, 0.05, 0.05, 0, 0.1, 0.02, 0.02, 0, 0.05, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
#define COSMOS_PARALLAX_INFERNAL list(0.55, 0.15, 0, 0, 0.15, 0.05, 0, 0, 0.05, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
#define COSMOS_PARALLAX_RATVAR list(0.55, 0.4, 0.05, 0, 0.15, 0.12, 0, 0, 0.05, 0.04, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)
#define COSMOS_PARALLAX_CLASH list(0.58, 0.28, 0.02, 0, 0.14, 0.08, 0, 0, 0.05, 0.03, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0)

/proc/_cosmos_update_from_entities()
	SSnightshift.starlight_override = TRUE
	if(GLOB.narsie_cosmos_active && GLOB.ratvar_cosmos_active)
		clash_cosmos()
	else if(GLOB.narsie_cosmos_active)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_starlight_anim), "#960000", 0.05, 25, 150, 0, 0)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_parallax_anim), COSMOS_PARALLAX_GREY, COSMOS_PARALLAX_BLACK, 20 SECONDS, COSMOS_PARALLAX_NARSIE, 10 SECONDS)
	else if(GLOB.ratvar_cosmos_active)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_starlight_anim), "#BE8700", 0.1, 20, 190, 135, 0)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_parallax_anim), COSMOS_PARALLAX_GREY, COSMOS_PARALLAX_BLACK, 18 SECONDS, COSMOS_PARALLAX_RATVAR, 10 SECONDS)

/proc/narsie_darken_cosmos()
	if(GLOB.narsie_cosmos_active)
		return
	GLOB.narsie_cosmos_active = TRUE
	_cosmos_update_from_entities()

/proc/ratvar_yellowen_cosmos()
	if(GLOB.ratvar_cosmos_active)
		return
	GLOB.ratvar_cosmos_active = TRUE
	_cosmos_update_from_entities()

/proc/clash_cosmos()
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_starlight_anim), "#CC5500", 0.08, 15, 200, 90, 0)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_parallax_direct_anim), COSMOS_PARALLAX_CLASH, 12 SECONDS)

/proc/infernal_darken_cosmos()
	if(GLOB.infernal_cosmos_active)
		return
	GLOB.infernal_cosmos_active = TRUE
	SSnightshift.starlight_override = TRUE
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_starlight_anim), "#501010", 0.08, 12, 80, 16, 16)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_parallax_anim), COSMOS_PARALLAX_GREY, COSMOS_PARALLAX_BLACK, 8 SECONDS, COSMOS_PARALLAX_INFERNAL, 6 SECONDS)

/proc/_cosmos_starlight_anim(final_color, final_power, steps, lerp_r = 150, lerp_g = 0, lerp_b = 0)
	set waitfor = FALSE
	if(!steps)
		steps = 20
	var/base_power = GLOB.current_starlight_power || STARLIGHT_POWER_NIGHT
	for(var/i in 1 to steps)
		var/lerp = i / steps
		var/power = max(final_power, base_power * (1 - lerp))
		set_starlight(rgb(round(lerp * lerp_r), round(lerp * lerp_g), round(lerp * lerp_b)), power)
		sleep(0.5 SECONDS)
	set_starlight(final_color, final_power)
	if(final_color)
		GLOB.current_starlight_color = final_color
	if(final_power)
		GLOB.current_starlight_power = final_power

/proc/_cosmos_parallax_anim(list/grey_matrix, list/black_matrix, black_time, list/final_matrix, final_time)
	set waitfor = FALSE
	for(var/client/C in GLOB.clients)
		if(!C?.mob || isnewplayer(C.mob))
			continue
		var/atom/movable/screen/plane_master/parallax_white/PM = locate() in C.screen
		if(!PM)
			continue
		PM.color = grey_matrix
		animate(PM, color = black_matrix, time = black_time, easing = SINE_EASING)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_cosmos_parallax_finalize_client), C, final_matrix, final_time), black_time)

/proc/_cosmos_parallax_finalize_client(client/C, list/final_matrix, final_time)
	if(!C)
		return
	var/atom/movable/screen/plane_master/parallax_white/PM = locate() in C.screen
	if(!PM)
		return
	animate(PM, color = final_matrix, time = final_time, easing = SINE_EASING)

/proc/_cosmos_parallax_direct_anim(list/final_matrix, final_time)
	set waitfor = FALSE
	for(var/client/C in GLOB.clients)
		if(!C?.mob || isnewplayer(C.mob))
			continue
		var/atom/movable/screen/plane_master/parallax_white/PM = locate() in C.screen
		if(!PM)
			continue
		animate(PM, color = final_matrix, time = final_time, easing = SINE_EASING)

/proc/infernal_ascension_atmosphere(mob/source)
	for(var/mob/M in GLOB.player_list)
		if(!M.client || isnewplayer(M))
			continue
		if(!is_station_level(M.z))
			continue
		M.playsound_local(get_turf(M), 'sound/hallucinations/veryfar_noise.ogg', 50, FALSE, pressure_affected = FALSE)
		M.overlay_fullscreen("infernal_ascension", /atom/movable/screen/fullscreen/flash/infernal)
		M.clear_fullscreen("infernal_ascension", 25)

#undef COSMOS_PARALLAX_GREY
#undef COSMOS_PARALLAX_BLACK
#undef COSMOS_PARALLAX_NARSIE
#undef COSMOS_PARALLAX_INFERNAL
#undef COSMOS_PARALLAX_RATVAR
#undef COSMOS_PARALLAX_CLASH
