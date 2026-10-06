/// Телепорт вендиго находит точку у цели и в тёмной пещере, где view() от турфа не видит пол.
/datum/unit_test/wendigo_teleport_in_darkness
	var/area/darkened_area
	var/darkened_area_luminosity
	var/list/darkened_turfs = list()

/datum/unit_test/wendigo_teleport_in_darkness/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/start = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/megafauna/wendigo/wendigo = allocate(/mob/living/simple_animal/hostile/megafauna/wendigo, start)
	wendigo.target = victim
	darkened_area = get_area(run_loc_floor_bottom_left)
	darkened_area_luminosity = darkened_area.luminosity
	darkened_area.luminosity = 0
	for(var/turf/dark_turf as anything in RANGE_TURFS(5, run_loc_floor_bottom_left))
		darkened_turfs[dark_turf] = dark_turf.luminosity
		dark_turf.luminosity = 0

	wendigo.teleport()

	TEST_ASSERT_EQUAL(get_dist(wendigo, victim), 4, "Вендиго должен прыгнуть на кольцо в 4 тайла от цели")

/datum/unit_test/wendigo_teleport_in_darkness/Destroy()
	if(darkened_area)
		darkened_area.luminosity = darkened_area_luminosity
	for(var/turf/dark_turf as anything in darkened_turfs)
		dark_turf.luminosity = darkened_turfs[dark_turf]
	darkened_turfs = null
	darkened_area = null
	return ..()
