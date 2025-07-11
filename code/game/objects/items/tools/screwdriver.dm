/obj/item/screwdriver
	name = "screwdriver"
	desc = "You can be totally screwy with this."
	icon = 'icons/obj/tools.dmi'
	icon_state = "screwdriver_map"
	item_state = "screwdriver"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	item_flags = SURGICAL_TOOL
	force = 5
	w_class = WEIGHT_CLASS_TINY
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/iron=75)
	attack_verb = list("stabbed")
	hitsound = 'sound/weapons/bladeslice.ogg'
	usesound = list('sound/items/screwdriver.ogg', 'sound/items/screwdriver2.ogg')
	tool_behaviour = TOOL_SCREWDRIVER
	toolspeed = 1
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 30)
	var/random_color = TRUE //if the screwdriver uses random coloring
	var/static/list/screwdriver_colors = list(
		"blue" = rgb(24, 97, 213),
		"red" = rgb(255, 0, 0),
		"pink" = rgb(213, 24, 141),
		"brown" = rgb(160, 82, 18),
		"green" = rgb(14, 127, 27),
		"cyan" = rgb(24, 162, 213),
		"yellow" = rgb(255, 165, 0)
	)
	drop_sound = 'sound/items/handling/screwdriver_drop.ogg'
	pickup_sound = 'sound/items/handling/screwdriver_pickup.ogg'

	wound_bonus = 5
	bare_wound_bonus = 9

/obj/item/screwdriver/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is stabbing [src] into [user.ru_ego()] [pick("temple", "heart")]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return(BRUTELOSS)

/obj/item/screwdriver/Initialize(mapload)
	. = ..()
	if(random_color) //random colors!
		var/our_color = pick(screwdriver_colors)
		add_atom_colour(screwdriver_colors[our_color], FIXED_COLOUR_PRIORITY)
		update_icon()
	if(prob(75))
		pixel_y = rand(0, 16)

/obj/item/screwdriver/update_overlays()
	. = ..()
	if(!random_color) //icon override
		return
	var/mutable_appearance/base_overlay = mutable_appearance(icon, "screwdriver_screwybits")
	base_overlay.appearance_flags = RESET_COLOR
	. += base_overlay

/obj/item/screwdriver/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(isinhands && random_color)
		var/mutable_appearance/M = mutable_appearance(icon_file, "screwdriver_head")
		M.appearance_flags = RESET_COLOR
		. += M

/obj/item/screwdriver/get_belt_overlay()
	if(random_color)
		var/mutable_appearance/body = mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "screwdriver")
		var/mutable_appearance/head = mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "screwdriver_head")
		body.color = color
		head.add_overlay(body)
		return head
	else
		return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', icon_state)

/obj/item/screwdriver/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!istype(M))
		return ..()
	if(user.zone_selected != BODY_ZONE_PRECISE_EYES && user.zone_selected != BODY_ZONE_HEAD)
		return ..()
	return eyestab(M,user)

/obj/item/screwdriver/brass
	name = "brass screwdriver"
	desc = "A screwdriver made of brass. The handle feels freezing cold."
	resistance_flags = FIRE_PROOF | ACID_PROOF
	icon_state = "screwdriver_clock"
	item_state = "screwdriver_brass"
	toolspeed = 0.5
	random_color = FALSE

/obj/item/screwdriver/brass/family
	toolspeed = 1

/obj/item/screwdriver/ashwalker
	name = "bone screwdriver"
	desc = "A rudimentary screwdriver made of carved bones."
	icon = 'icons/obj/mining.dmi'
	icon_state = "screwdriver_bone"
	toolspeed = 0.75
	random_color = FALSE

/obj/item/screwdriver/bronze
	name = "bronze screwdriver"
	desc = "A screwdriver plated with bronze."
	icon_state = "screwdriver_brass"
	item_state = "screwdriver_brass"
	toolspeed = 0.95
	random_color = FALSE

/obj/item/screwdriver/abductor
	name = "alien screwdriver"
	desc = "An ultrasonic screwdriver."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "screwdriver_a"
	item_state = "screwdriver_nuke"
	usesound = 'sound/items/pshoom.ogg'
	toolspeed = 0.1
	random_color = FALSE

/obj/item/screwdriver/abductor/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "screwdriver_nuke")

/obj/item/screwdriver/power
	name = "hand drill"
	desc = "A simple powered hand drill. It's fitted with a screw bit."
	icon_state = "drill_screw"
	item_state = "drill"
	lefthand_file = 'modular_sand/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_sand/icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=150,/datum/material/silver=50,/datum/material/titanium=25) //done for balance reasons, making them high value for research, but harder to get
	force = 8 //might or might not be too high, subject to change
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 8
	throw_speed = 2
	throw_range = 3//it's heavier than a screw driver/wrench, so it does more damage, but can't be thrown as far
	attack_verb = list("drilled", "screwed", "jabbed","whacked")
	hitsound = 'sound/items/drill_hit.ogg'
	usesound = 'sound/items/drill_use.ogg'
	toolspeed = 0.25
	random_color = FALSE

/obj/item/screwdriver/power/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is putting [src] to [user.ru_ego()] temple. It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return(BRUTELOSS)

/obj/item/screwdriver/power/attack_self(mob/user)
	playsound(get_turf(user),'sound/items/change_drill.ogg',50,1)
	var/obj/item/wrench/power/b_drill = new /obj/item/wrench/power(drop_location())
	to_chat(user, "<span class='notice'>You attach the bolt driver bit to [src].</span>")
	qdel(src)
	user.put_in_active_hand(b_drill)

/obj/item/screwdriver/cyborg
	name = "automated screwdriver"
	desc = "An electrical screwdriver, designed to be both precise and quick."
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "screwdriver_cyborg"
	hitsound = 'sound/items/drill_hit.ogg'
	usesound = 'sound/items/drill_use.ogg'
	toolspeed = 0.5
	random_color = FALSE

/obj/item/screwdriver/advanced
	name = "advanced screwdriver"
	desc = "A classy silver screwdriver with an alien alloy tip, it works almost as well as the real thing."
	icon = 'icons/obj/advancedtools.dmi'
	icon_state = "screwdriver_a"
	item_state = "screwdriver_nuke"
	usesound = 'sound/items/pshoom.ogg'
	toolspeed = 0.2
	random_color = FALSE
// BLUEMOON ADD START black skin
	unique_reskin = list(
		"Carbonized" = list(
			RESKIN_ICON_STATE_FILE = 'modular_bluemoon/icons/obj/advancedtools_black.dmi',
			RESKIN_ICON_STATE = "screwdriver_a_black",
		),
		"Titanium" = list(
			RESKIN_ICON_STATE = "screwdriver_a",
		)
	)

/obj/item/screwdriver/advanced/reskin_obj(mob/user)
	if(current_skin == "Carbonized")
		desc = "A classy carbon screwdriver with an alien alloy tip, it works almost as well as the real thing."
// BLUEMOON ADD END
