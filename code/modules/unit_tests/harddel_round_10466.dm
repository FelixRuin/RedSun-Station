/// Тиковые кэши угроз и союзников AI-контроллера не держат удалённого моба
/datum/unit_test/ai_tactical_caches_release_deleted_mobs
	parent_type = /datum/unit_test/harddel_10151_base

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/proc/cache_and_delete(datum/ai_controller/controller, victim_type)
	var/mob/living/victim = new victim_type(get_step(run_loc_floor_bottom_left, EAST))
	if(ispath(victim_type, /mob/living/simple_animal/hostile))
		TEST_ASSERT(victim in controller.get_nearby_allies(), "Sanity: [victim_type] не попал в кэш союзников")
	else
		TEST_ASSERT(victim in controller.get_nearby_threats(), "Sanity: [victim_type] не попал в кэш угроз")
	qdel(victim)

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/proc/deleted_in_cache(datum/ai_controller/controller, key)
	. = 0
	for(var/atom/cached as anything in controller.blackboard[key])
		if(QDELETED(cached))
			.++

/datum/unit_test/ai_tactical_caches_release_deleted_mobs/Run()
	var/mob/living/simple_animal/hostile/headcrab/watcher = allocate(/mob/living/simple_animal/hostile/headcrab, run_loc_floor_bottom_left)
	var/datum/ai_controller/controller = watcher.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Sanity: у хедкраба нет AI-контроллера")

	cache_and_delete(controller, /mob/living/simple_animal/hostile/headcrab)
	cache_and_delete(controller, /mob/living/carbon/monkey)
	settle()
	TEST_ASSERT_EQUAL(deleted_in_cache(controller, BB_AI_ALLY_CACHE), 0, "Кэш союзников держит удалённого моба после смены тика")
	TEST_ASSERT_EQUAL(deleted_in_cache(controller, BB_AI_THREAT_CACHE), 0, "Кэш угроз держит удалённого моба после смены тика")
