//open shell
/datum/surgery_step/mechanic_open
	name = "Открутить Винты"
	implements = list(
		TOOL_SCREWDRIVER		= 100,
		TOOL_SCALPEL 		= 75, // med borgs could try to unscrew shell with scalpel
		/obj/item/kitchen/knife	= 50,
		/obj/item				= 10) // 10% success with any sharp item.
	time = 24
	preop_sound = 'sound/items/screwdriver.ogg'
	success_sound = 'sound/items/screwdriver2.ogg'

/datum/surgery_step/mechanic_open/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to unscrew the shell of [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to unscrew the shell of [target]'s [parse_zone(target_zone)].",
			"[user] begins to unscrew the shell of [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/mechanic_open/tool_check(mob/user, obj/item/tool)
	if(implement_type == /obj/item && !tool.get_sharpness())
		return FALSE
	if(tool.usesound)
		preop_sound = tool.usesound

	return TRUE

//close shell
/datum/surgery_step/mechanic_close
	name = "Прикрутить Винты"
	implements = list(
		TOOL_SCREWDRIVER		= 100,
		TOOL_SCALPELl 		= 75,
		/obj/item/kitchen/knife	= 50,
		/obj/item				= 10) // 10% success with any sharp item.
	time = 24
	preop_sound = 'sound/items/screwdriver.ogg'
	success_sound = 'sound/items/screwdriver2.ogg'

/datum/surgery_step/mechanic_close/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to screw the shell of [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to screw the shell of [target]'s [parse_zone(target_zone)].",
			"[user] begins to screw the shell of [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/mechanic_close/tool_check(mob/user, obj/item/tool)
	if(implement_type == /obj/item && !tool.get_sharpness())
		return FALSE
	if(tool.usesound)
		preop_sound = tool.usesound

	return TRUE

//prepare electronics
/datum/surgery_step/prepare_electronics
	name = "Подготовить Электронику (Мультитул)"
	implements = list(
		TOOL_MULTITOOL = 100,
		TOOL_HEMOSTAT = 10) // try to reboot internal controllers via short circuit with some conductor
	time = 24
	preop_sound = 'sound/items/taperecorder/tape_flip.ogg'
	success_sound = 'sound/items/taperecorder/taperecorder_close.ogg'

/datum/surgery_step/prepare_electronics/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to prepare electronics in [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to prepare electronics in [target]'s [parse_zone(target_zone)].",
			"[user] begins to prepare electronics in [target]'s [parse_zone(target_zone)].")

//unwrench
/datum/surgery_step/mechanic_unwrench
	name = "Выкрутить Болты"
	implements = list(
		TOOL_WRENCH = 100,
		TOOL_RETRACTOR = 10)
	time = 24
	preop_sound = 'sound/items/ratchet.ogg'

/datum/surgery_step/mechanic_unwrench/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to unwrench some bolts in [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to unwrench some bolts in [target]'s [parse_zone(target_zone)].",
			"[user] begins to unwrench some bolts in [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/mechanic_unwrench/tool_check(mob/user, obj/item/tool)
	if(tool.usesound)
		preop_sound = tool.usesound

	return TRUE

//wrench
/datum/surgery_step/mechanic_wrench
	name = "Прикрутить Болты"
	implements = list(
		TOOL_WRENCH = 100,
		TOOL_RETRACTOR = 10)
	time = 24
	preop_sound = 'sound/items/ratchet.ogg'

/datum/surgery_step/mechanic_wrench/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to wrench some bolts in [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to wrench some bolts in [target]'s [parse_zone(target_zone)].",
			"[user] begins to wrench some bolts in [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/mechanic_wrench/tool_check(mob/user, obj/item/tool)
	if(tool.usesound)
		preop_sound = tool.usesound

	return TRUE

//open hatch
/datum/surgery_step/open_hatch
	name = "open the hatch (empty hand)"
	accept_hand = 1
	time = 10
	preop_sound = 'sound/items/ratchet.ogg'
	preop_sound = 'sound/machines/doorclick.ogg'

/datum/surgery_step/open_hatch/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to open the hatch holders in [target]'s [parse_zone(target_zone)]...</span>",
		"[user] begins to open the hatch holders in [target]'s [parse_zone(target_zone)].",
		"[user] begins to open the hatch holders in [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/mechanic_unwrench/tool_check(mob/user, obj/item/tool)
	if(tool.usesound)
		preop_sound = tool.usesound

	return TRUE

//cut wires
/datum/surgery_step/cut_wires
	name = "Обрезать Провода"
	implements = list(
		TOOL_WIRECUTTER		= 100,
		TOOL_SCALPEL 		= 75,
		/obj/item/kitchen/knife	= 50,
		/obj/item				= 10) // 10% success with any sharp item.
	time = 24

/datum/surgery_step/cut_wires/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to cut loose wires in [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to cut loose wires in [target]'s [parse_zone(target_zone)].",
			"[user] begins to cut loose wires in [target]'s [parse_zone(target_zone)].")

/datum/surgery_step/cut_wires/tool_check(mob/user, obj/item/tool)
	if(implement_type == /obj/item && !tool.get_sharpness())
		return FALSE
	return TRUE

//pry off plating
/datum/surgery_step/pry_off_plating
	name = "Снять Панель"
	implements = list(
		TOOL_CROWBAR = 100,
		TOOL_HEMOSTAT = 10)
	time = 24

/datum/surgery_step/pry_off_plating/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	do_sparks(rand(5, 9), FALSE, target.loc)
	return TRUE

/datum/surgery_step/pry_off_plating/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to pry off [target]'s [parse_zone(target_zone)] plating...</span>",
			"[user] begins to pry off [target]'s [parse_zone(target_zone)] plating.",
			"[user] begins to pry off [target]'s [parse_zone(target_zone)] plating.")

//weld plating
/datum/surgery_step/weld_plating
	name = "Нанести сварочные швы"
	implements = list(
		TOOL_WELDER = 100)
	time = 24

/datum/surgery_step/weld_plating/tool_check(mob/user, obj/item/tool)
	if(implement_type == TOOL_WELDER && !tool.use_tool(user, user, 0, volume=50, amount=1))
		return FALSE
	return TRUE

/datum/surgery_step/weld_plating/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to weld [target]'s [parse_zone(target_zone)] plating...</span>",
			"[user] begins to weld [target]'s [parse_zone(target_zone)] plating.",
			"[user] begins to weld [target]'s [parse_zone(target_zone)] plating.")

//replace wires
/datum/surgery_step/replace_wires
	name = "Заменить проводку"
	implements = list(/obj/item/stack/cable_coil = 100)
	time = 24
	var/cableamount = 5

/datum/surgery_step/replace_wires/tool_check(mob/user, obj/item/tool)
	var/obj/item/stack/cable_coil/coil = tool
	if(coil.get_amount() < cableamount)
		to_chat(user, "<span class='warning'>Not enough cable!</span>")
		return FALSE
	return TRUE

/datum/surgery_step/replace_wires/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/stack/cable_coil/coil = tool
	if(coil && !(coil.get_amount()<cableamount)) //failproof
		coil.use(cableamount)
	return TRUE

/datum/surgery_step/replace_wires/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to replace [target]'s [parse_zone(target_zone)] wiring...</span>",
			"[user] begins to replace [target]'s [parse_zone(target_zone)] wiring.",
			"[user] begins to replace [target]'s [parse_zone(target_zone)] wiring.")

//add plating
/datum/surgery_step/add_plating
	name = "Добавить дополнительные панели"
	implements = list(/obj/item/stack/sheet/metal = 100)
	time = 24
	var/metalamount = 5

/datum/surgery_step/add_plating/tool_check(mob/user, obj/item/tool)
	var/obj/item/stack/sheet/metal/plat = tool
	if(plat.get_amount() < metalamount)
		to_chat(user, "<span class='warning'>Not enough metal!</span>")
		return FALSE
	return TRUE

/datum/surgery_step/add_plating/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/stack/sheet/metal/plat = tool
	if(plat && !(plat.get_amount()<metalamount)) //failproof
		plat.use(metalamount)
	return TRUE

/datum/surgery_step/add_plating/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to add plating to [target]'s [parse_zone(target_zone)]...</span>",
			"[user] begins to add plating to [target]'s [parse_zone(target_zone)].",
			"[user] begins to add plating to [target]'s [parse_zone(target_zone)].")
