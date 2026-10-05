/// backdrop() любой плоскости не падает, пока у клиента зрителя ещё нет prefs.
/datum/unit_test/plane_master_backdrop_without_prefs

/datum/unit_test/plane_master_backdrop_without_prefs/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	viewer.mock_client = new /datum/client_interface()
	for(var/master_type in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/plane_master/master = new master_type(null)
		allocated += master
		master.backdrop(viewer)
	for(var/category in LAZYCOPY(viewer.fullscreens))
		viewer.clear_fullscreen(category, 0)
	viewer.mock_client = null
