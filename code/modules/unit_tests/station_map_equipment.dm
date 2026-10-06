/// Гравген станции собран из частей, а консоли, доплер и тренажёры стоят рабочими подтипами, не абстрактной базой или пустой заглушкой.
/datum/unit_test/station_machines_not_abstract
	requires_full_map = TRUE

/datum/unit_test/station_machines_not_abstract/Run()
	for(var/obj/machinery/gravity_generator/main/generator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/gravity_generator/main))
		if(!is_station_level(generator.z))
			continue
		TEST_ASSERT(generator.connected_parts(), "Гравген без частей на ([generator.x],[generator.y],[generator.z]): [length(generator.parts)] из 8")

	var/list/abstract_types = typecacheof(list(
		/obj/machinery/computer/upload,
		/obj/machinery/computer/bookmanagement,
		/obj/machinery/doppler_array,
		/obj/structure/weightmachine,
		/obj/structure/billboard,
		/obj/item/reagent_containers/cup/glass/coffee,
		/obj/item/gun/ballistic/shotgun/doublebarrel,
	), only_root_path = TRUE)
	var/list/abstract_found = list()
	for(var/obj/thing in world)
		if(abstract_types[thing.type])
			abstract_found += "[thing.type] ([thing.x],[thing.y],[thing.z])"
	TEST_ASSERT(!length(abstract_found), "Абстрактные типы на карте: [abstract_found.Join(", ")]")

/// На портированных картах есть снаряжение ролей BlueMoon и рабочие машины вместо tg-шных заглушек.
/datum/unit_test/ported_map_bluemoon_equipment
	requires_full_map = TRUE

/datum/unit_test/ported_map_bluemoon_equipment/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/required = list(
		/obj/structure/closet/secure_closet/blueshield = 0,
		/obj/machinery/vending/wardrobe/blueshield_wardrobe = 0,
		/obj/structure/closet/secure_closet/ntr = 0,
		/obj/structure/closet/secure_closet/bridgesec = 0,
		/obj/machinery/vending/wardrobe/bridgeofficer_wardrobe = 0,
		/obj/structure/closet/secure_closet/brigdoc = 0,
		/obj/machinery/vending/brigdoc_vendomat = 0,
		/obj/machinery/vending/wardrobe/cap_wardrobe = 0,
		/obj/structure/closet/secure_closet/hosnew = 0,
		/obj/machinery/computer/upload/ai = 0,
		/obj/machinery/computer/upload/borg = 0,
		/obj/machinery/doppler_array/research/science = 0,
		/obj/machinery/atmospherics/miner/nitrogen = 0,
		/obj/machinery/atmospherics/miner/oxygen = 0,
		/obj/machinery/atmospherics/miner/carbon_dioxide = 0,
		/obj/machinery/atmospherics/miner/toxins = 0,
		/obj/machinery/atmospherics/miner/n2o = 0,
		/obj/machinery/clonepod = 0,
		/obj/machinery/computer/cloning = 0,
		/obj/machinery/dna_scannernew = 0,
		/obj/machinery/sleeper = 0,
		/obj/machinery/plantgenes = 0,
		/obj/machinery/smartfridge/disks = 0,
		/obj/item/ai_module/reset = 0,
		/obj/item/ai_module/reset/purge = 0,
		/obj/item/ai_module/core/full/asimov = 0,
	)
	for(var/obj/thing in world)
		if(!isnull(required[thing.type]) && is_station_level(thing.z))
			required[thing.type]++
	var/list/missing = list()
	for(var/wanted_type in required)
		if(!required[wanted_type])
			missing += "[wanted_type]"
	TEST_ASSERT(!length(missing), "На станции нет: [missing.Join(", ")]")

	var/list/idle_timers = list()
	for(var/obj/machinery/door_timer/timer as anything in GLOB.celltimers_list)
		if(is_station_level(timer.z) && !length(timer.targets))
			idle_timers += "[timer.name] ([timer.x],[timer.y],[timer.z])"
	TEST_ASSERT(!length(idle_timers), "Таймеры камер без дверей: [idle_timers.Join(", ")]")

	for(var/chamber_type in list(/area/engineering/supermatter, /area/science/mixing/chamber, /area/science/mixing/freezer))
		var/has_alarm = FALSE
		for(var/area/chamber as anything in GLOB.all_areas)
			if(chamber.type == chamber_type && length(chamber.airalarms))
				has_alarm = TRUE
				break
		TEST_ASSERT(has_alarm, "У камеры [chamber_type] нет своей алармы")

/// На портированных картах есть то, что несут основные карты: рефиллер медипенов, гражданский синди-гардероб, набор Авангарда у его точек старта, колорматы и кинк-вендоры.
/datum/unit_test/ported_map_bluemoon_kits
	requires_full_map = TRUE

/datum/unit_test/ported_map_bluemoon_kits/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/problems = list()
	var/list/minimum_counts = list(
		/obj/machinery/medipen_refiller = 1,
		/obj/machinery/vending/wardrobe/syndie_wardrobe/civil = 1,
		/obj/machinery/gear_painter = 2,
		/obj/machinery/vending/kink = 3,
	)
	for(var/machine_type in minimum_counts)
		var/found = 0
		for(var/obj/machinery/machine as anything in SSmachines.get_machines_by_type_and_subtypes(machine_type))
			if(is_station_level(machine.z))
				found++
		if(found < minimum_counts[machine_type])
			problems += "[machine_type]: [found] из [minimum_counts[machine_type]]"

	var/list/spawn_areas = GLOB.unit_test_start_landmark_areas[/obj/effect/landmark/start/expeditor]
	if(!length(spawn_areas))
		problems += "нет точек старта Авангарда"
	else
		var/list/kit_found = list(
			/obj/structure/closet/secure_closet/vanguard = FALSE,
			/obj/machinery/ammo_workbench = FALSE,
			/obj/machinery/vanguard/contraband = FALSE,
			/obj/machinery/computer/vanguard_control/contraband = FALSE,
			/obj/machinery/recharger = FALSE,
			/obj/machinery/bountyvend/plus = FALSE,
		)
		var/list/area_types = list()
		for(var/area/spawn_area as anything in spawn_areas)
			area_types += "[spawn_area.type]"
			for(var/obj/thing in spawn_area)
				for(var/kit_type in kit_found)
					if(istype(thing, kit_type))
						kit_found[kit_type] = TRUE
		var/list/kit_missing = list()
		for(var/kit_type in kit_found)
			if(!kit_found[kit_type])
				kit_missing += "[kit_type]"
		if(length(kit_missing))
			problems += "у точек старта Авангарда ([area_types.Join(", ")]) нет [kit_missing.Join(", ")]"
	TEST_ASSERT(!length(problems), "На станции не хватает: [problems.Join("; ")]")

/// Камеры портированных карт висят на стене: у tg dir камеры - сторона стены, у нас - сторона взгляда.
/datum/unit_test/ported_map_cameras_on_walls
	requires_full_map = TRUE

/datum/unit_test/ported_map_cameras_on_walls/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/mount_side = list("[NORTH]" = SOUTH, "[SOUTH]" = NORTH, "[EAST]" = WEST, "[WEST]" = EAST, "[SOUTHEAST]" = NORTH, "[SOUTHWEST]" = SOUTH, "[NORTHEAST]" = WEST, "[NORTHWEST]" = EAST)
	var/list/hanging = list()
	for(var/obj/machinery/camera/camera as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/camera))
		if(!is_station_level(camera.z) || camera.pixel_x || camera.pixel_y)
			continue
		var/turf/mount = get_step(camera, mount_side["[camera.dir]"])
		var/mounted = isclosedturf(mount)
		for(var/obj/support in mount)
			if(support.density || istype(support, /obj/machinery/door))
				mounted = TRUE
				break
		if(!mounted)
			hanging += "[camera.c_tag || camera.name] ([camera.x],[camera.y],[camera.z]) dir [camera.dir]"
	TEST_ASSERT(!length(hanging), "Камеры без стены за спиной: [hanging.Join(", ")]")

/// Внешний шлюз порта, выходящий в космос, безвоздушный туннель или наружу планеты, держит маленький вентилятор, как на родных картах.
/datum/unit_test/ported_map_external_airlocks_have_fans
	requires_full_map = TRUE

/datum/unit_test/ported_map_external_airlocks_have_fans/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/bare = list()
	for(var/obj/machinery/door/airlock/external/door as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/door/airlock/external))
		if(!is_station_level(door.z) || !faces_outside(door))
			continue
		if(!(locate(/obj/structure/fans/tiny) in door.loc))
			bare += "[door.name] ([door.x],[door.y],[door.z])"
	TEST_ASSERT(!length(bare), "Внешние шлюзы без маленького вентилятора: [bare.Join(", ")]")

/datum/unit_test/ported_map_external_airlocks_have_fans/proc/faces_outside(obj/machinery/door/door)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(door, direction)
		if(!neighbor)
			continue
		var/area/neighbor_area = neighbor.loc
		if(isspaceturf(neighbor) || neighbor_area.outdoors || istype(neighbor_area, /area/space))
			return TRUE
		if(isopenturf(neighbor))
			var/turf/open/open_neighbor = neighbor
			if(open_neighbor.initial_gas_mix == AIRLESS_ATMOS)
				return TRUE
	return FALSE

/// Концы скамей и угловых диванов порта стоят как на родных картах: left на западе или юге, при dir 8 на севере.
/datum/unit_test/ported_map_seat_ends_match_natives
	requires_full_map = TRUE

/datum/unit_test/ported_map_seat_ends_match_natives/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/flipped = list()
	for(var/obj/structure/chair/seat in world)
		if(!is_station_level(seat.z))
			continue
		var/side
		if(istype(seat, /obj/structure/chair/pew/left) || istype(seat, /obj/structure/chair/sofa/corp/left))
			side = "left"
		else if(istype(seat, /obj/structure/chair/pew/right) || istype(seat, /obj/structure/chair/sofa/corp/right))
			side = "right"
		else
			continue
		var/family = istype(seat, /obj/structure/chair/pew) ? /obj/structure/chair/pew : /obj/structure/chair/sofa/corp
		var/plus_dir = (seat.dir & (NORTH|SOUTH)) ? EAST : NORTH
		var/at_plus = locate(family) in get_step(seat, plus_dir)
		var/at_minus = locate(family) in get_step(seat, REVERSE_DIR(plus_dir))
		if(!at_plus == !at_minus)
			continue
		var/is_plus_end = !at_plus
		var/wanted = (is_plus_end == (seat.dir == WEST)) ? "left" : "right"
		if(wanted != side)
			flipped += "[seat.type] ([seat.x],[seat.y],[seat.z]) dir [seat.dir]"
	TEST_ASSERT(!length(flipped), "Концы скамей перепутаны: [flipped.Join(", ")]")

/// Фабрикаторы робототехники синхронизируются с R&D: sync() ищет консоль в семи тайлах.
/datum/unit_test/robotics_fabricators_sync_research
	requires_full_map = TRUE

/datum/unit_test/robotics_fabricators_sync_research/Run()
	var/list/unsynced = list()
	for(var/obj/machinery/mecha_part_fabricator/fabricator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/mecha_part_fabricator))
		if(!is_station_level(fabricator.z) || !istype(get_area(fabricator), /area/science/robotics))
			continue
		if(!fabricator.sync(ignore_timer = TRUE, is_silent = TRUE))
			unsynced += "([fabricator.x],[fabricator.y],[fabricator.z])"
	TEST_ASSERT(!length(unsynced), "Фабрикаторы робототехники без R&D-консоли рядом: [unsynced.Join(", ")]")

/// В науке портированных карт с начала раунда есть пластик для Problem Computer.
/datum/unit_test/ported_map_science_plastic
	requires_full_map = TRUE

/datum/unit_test/ported_map_science_plastic/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	for(var/obj/item/stack/sheet/plastic/sheet in world)
		if(is_station_level(sheet.z) && istype(get_area(sheet), /area/science))
			return
	TEST_FAIL("В науке нет стартового пластика")

/// Каждый станционный z получает свой номер в персистенсе мусора, в том числе этажи многоэтажной карты одним файлом.
/datum/unit_test/station_z_index_covers_station_levels
	requires_full_map = TRUE

/datum/unit_test/station_z_index_covers_station_levels/Run()
	var/list/seen_indexes = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/index = SSmapping.z_to_station_z_index["[station_z]"]
		TEST_ASSERT_NOTNULL(index, "Станционный z=[station_z] без номера в персистенсе: мусор этажа сохраняется без ключа и теряется")
		TEST_ASSERT(!seen_indexes["[index]"], "Номер [index] выдан двум станционным z")
		seen_indexes["[index]"] = TRUE

/// Шаттл прибытия встаёт в док карты: без него латеджойну некуда спавнить.
/datum/unit_test/arrivals_shuttle_docked
	requires_full_map = TRUE

/datum/unit_test/arrivals_shuttle_docked/Run()
	var/obj/docking_port/stationary/arrivals_dock
	for(var/obj/docking_port/stationary/dock as anything in SSshuttle.stationary)
		if(dock.shuttle_id == "arrivals_stationary")
			arrivals_dock = dock
			break
	if(!arrivals_dock)
		return
	TEST_ASSERT_NOTNULL(SSshuttle.arrivals, "Шаттл прибытия не встал в док ([arrivals_dock.x],[arrivals_dock.y],[arrivals_dock.z])")

/// Паром ЦК и карго-шаттл помещаются в свои бухты на станции: оба грузятся на ЦК и прилетают позже.
/datum/unit_test/station_bays_fit_shuttles
	requires_full_map = TRUE

/datum/unit_test/station_bays_fit_shuttles/Run()
	for(var/list/pair in list(list("ferry", "ferry_home"), list("supply", "supply_home")))
		var/obj/docking_port/mobile/shuttle = SSshuttle.getShuttle(pair[1])
		var/obj/docking_port/stationary/bay = SSshuttle.getDock(pair[2])
		if(!shuttle || !bay)
			continue
		var/result = shuttle.canDock(bay)
		TEST_ASSERT(result == SHUTTLE_CAN_DOCK || result == SHUTTLE_ALREADY_DOCKED || result == SHUTTLE_SOMEONE_ELSE_DOCKED, "[shuttle] не помещается в бухту [pair[2]] ([bay.x],[bay.y],[bay.z]): [result]")

/// Грунт на станции портированных карт не планетарный: иначе он вечный источник газа и активный турф с роундстарта.
/datum/unit_test/ported_map_station_dirt_not_planetary
	requires_full_map = TRUE

/datum/unit_test/ported_map_station_dirt_not_planetary/Run()
	if(!(SSmapping.config.map_name in PORTED_STATION_MAPS))
		return
	var/list/planetary = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/floor/plating/dirt/dirt in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z)))
			var/area/dirt_area = dirt.loc
			if(dirt.planetary_atmos && !dirt_area.outdoors)
				planetary += "([dirt.x],[dirt.y],[dirt.z])"
	TEST_ASSERT(!length(planetary), "Планетарный грунт на станции: [planetary.Join(", ")]")

/// Генератор пещер заменил все заглушки genturf на станционных уровнях: зона без генератора оставляет их как есть.
/datum/unit_test/station_levels_no_genturf
	requires_full_map = TRUE

/datum/unit_test/station_levels_no_genturf/Run()
	var/list/leftover = list()
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/genturf/placeholder in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z)))
			if(length(leftover) < 10)
				leftover += "([placeholder.x],[placeholder.y],[placeholder.z]) [placeholder.loc.type]"
			else
				break
	TEST_ASSERT(!length(leftover), "Заглушки genturf после генерации: [leftover.Join(", ")]")

/// Скамейки станции собраны из одной семьи: конец церковной скамьи рядом с серединой металлической - поломка конвертера карт.
/datum/unit_test/station_benches_one_family
	requires_full_map = TRUE

/datum/unit_test/station_benches_one_family/Run()
	var/list/mixed = list()
	for(var/obj/structure/chair/sofa/bench/bench in world)
		if(!is_station_level(bench.z))
			continue
		for(var/side in list(turn(bench.dir, 90), turn(bench.dir, -90)))
			var/obj/structure/chair/pew/pew = locate() in get_step(bench, side)
			if(pew?.dir == bench.dir)
				mixed += "([bench.x],[bench.y],[bench.z])"
	TEST_ASSERT(!length(mixed), "Скамейка из двух семей (bench и pew): [mixed.Join(", ")]")

/// Скала Трамстанции, как у tg, без своего питания, и гравитация в ней только от генератора станции.
/datum/unit_test/tramstation_asteroid_unpowered
	requires_full_map = TRUE

/datum/unit_test/tramstation_asteroid_unpowered/Run()
	if(SSmapping.config.map_name != "Tramstation")
		return
	var/area/asteroid/tramstation/rock = GLOB.areas_by_type[/area/asteroid/tramstation]
	TEST_ASSERT_NOTNULL(rock, "На Трамстанции нет зоны скалы")
	TEST_ASSERT(!rock.powered(LIGHT), "Свет в скале Трамстанции горит без APC")
	TEST_ASSERT(!rock.powered(EQUIP), "Оборудование в скале Трамстанции работает без APC")
	TEST_ASSERT(!rock.has_gravity, "Скала Трамстанции держит гравитацию сама, мимо генератора")

/// Канистры у портов криокапсул станции, прикрученные ключом, дают капсуле газ, на котором она работает.
/datum/unit_test/station_cryo_cells_have_gas
	requires_full_map = TRUE

/datum/unit_test/station_cryo_cells_have_gas/Run()
	var/list/dead_cells = list()
	for(var/obj/machinery/atmospherics/components/unary/cryo_cell/cell as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/atmospherics/components/unary/cryo_cell))
		if(!is_station_level(cell.z))
			continue
		var/datum/pipeline/net = cell.parents[1]
		if(net)
			net.ensure_built()
			for(var/obj/machinery/atmospherics/components/unary/portables_connector/port in net.other_atmosmch)
				var/obj/machinery/portable_atmospherics/canister/canister = locate() in port.loc
				canister?.connect(port)
			net.reconcile_air()
		var/was_on = cell.on
		cell.on = TRUE
		cell.process_atmos()
		if(!cell.on)
			dead_cells += "([cell.x],[cell.y],[cell.z])"
		cell.on = was_on
		cell.update_icon()
	TEST_ASSERT(!length(dead_cells), "Криокапсулы гаснут сразу после включения, на их сети нет нужного газа: [dead_cells.Join(", ")]")

/// Станционные зоны карты названы: зона без своего name подписывается в логах и на ПДА как «Space».
/datum/unit_test/station_areas_named
	requires_full_map = TRUE

/datum/unit_test/station_areas_named/Run()
	var/area/base_area = /area
	var/default_name = initial(base_area.name)
	var/list/unnamed = list()
	for(var/area/station_area as anything in GLOB.sortedAreas)
		if(istype(station_area, /area/space) || !is_station_level(station_area.z))
			continue
		if(station_area.name == default_name)
			unnamed += "[station_area.type]"
	TEST_ASSERT(!length(unnamed), "Станционные зоны без имени: [unnamed.Join(", ")]")

#define SUPERMATTER_COLLECTOR_RANGE 2
#define SUPERMATTER_MIN_COLLECTORS 6

/// У кристалла суперматерии станции стоят радколлекторы на сети с вводом СМЕСа: наш кристалл кормит их излучением, в тесла-катушки бьёт только при перегрузке.
/datum/unit_test/station_supermatter_has_rad_collectors
	requires_full_map = TRUE

/datum/unit_test/station_supermatter_has_rad_collectors/Run()
	for(var/obj/machinery/power/supermatter_crystal/engine/crystal as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/supermatter_crystal/engine))
		if(!is_station_level(crystal.z))
			continue
		var/wired = 0
		for(var/obj/machinery/power/rad_collector/collector as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/rad_collector))
			if(collector.z != crystal.z || get_dist(collector, crystal) > SUPERMATTER_COLLECTOR_RANGE)
				continue
			if(collector.anchored && collector.powernet && (locate(/obj/machinery/power/terminal) in collector.powernet.nodes))
				wired++
		TEST_ASSERT(wired >= SUPERMATTER_MIN_COLLECTORS, "У суперматерии ([crystal.x],[crystal.y],[crystal.z]) радколлекторов на сети СМЕСа: [wired] из [SUPERMATTER_MIN_COLLECTORS]")

#undef SUPERMATTER_COLLECTOR_RANGE
#undef SUPERMATTER_MIN_COLLECTORS

/// Трубы сантехники, проложенные картой под плиткой, не видны поверх пола.
/datum/unit_test/station_mapped_ducts_under_tiles_hidden
	requires_full_map = TRUE

/datum/unit_test/station_mapped_ducts_under_tiles_hidden/Run()
	var/visible_count = 0
	var/list/examples = list()
	for(var/obj/machinery/duct/duct as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/duct))
		var/turf/duct_turf = duct.loc
		if(!isturf(duct_turf) || !is_station_level(duct.z) || !(duct_turf.turf_flags & TURF_INTACT))
			continue
		if(duct.invisibility == INVISIBILITY_MAXIMUM)
			continue
		visible_count++
		if(length(examples) < 10)
			examples += "([duct.x],[duct.y],[duct.z])"
	TEST_ASSERT(!visible_count, "Трубы поверх плитки: [visible_count], например [examples.Join(", ")]")
