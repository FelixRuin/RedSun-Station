SUBSYSTEM_DEF(hilbertshotel)
	name = "Hilbert's Hotel"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_HILBERTSHOTEL
	var/storageTurf
/datum/controller/subsystem/hilbertshotel/proc/setup_storage_turf()
	if(storageTurf) // setting up a storage for the room objects
		return
	var/datum/map_template/hilbertshotelstorage/storageTemp = new()
	var/datum/turf_reservation/storageReservation = SSmapping.RequestBlockReservation(3, 3)
	var/turf/bottom_left = get_turf(storageReservation.bottom_left_coords[1])
	storageTemp.load(bottom_left)
	storageTurf = locate(bottom_left.x + 1, bottom_left.y + 1, bottom_left.z)
