/obj/vehicle/sealed/mecha/medical/odysseus
	desc = "These exosuits are developed and produced by Vey-Med. (&copy; All rights reserved)."
	name = "\improper Odysseus"
	icon_state = "odysseus"
	allow_diagonal_movement = TRUE
	movedelay = 2
	max_temperature = 15000
	max_integrity = 120
	wreckage = /obj/structure/mecha_wreckage/odysseus
	internal_damage_threshold = 35
	deflect_chance = 15
	normal_step_energy_drain = 6
	internals_req_access = list(ACCESS_ROBOTICS, ACCESS_MEDICAL)

/obj/vehicle/sealed/mecha/medical/odysseus/moved_inside(mob/living/carbon/human/H)
	. = ..()
	if(.)
		var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		hud.add_hud_to(H)

/obj/vehicle/sealed/mecha/medical/odysseus/remove_occupant(mob/M)
	if(isliving(M))
		var/mob/living/L = M
		var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/cyberimp/eyes/hud/CIH = M.getorgan(/obj/item/organ/cyberimp/eyes/hud)
		if(istype(H.glasses, /obj/item/clothing/glasses/hud/health) || istype(CIH, /obj/item/organ/cyberimp/eyes/hud/medical))
			return ..()
		else
			hud.remove_hud_from(L)
	return ..()

/obj/vehicle/sealed/mecha/medical/odysseus/mmi_moved_inside(obj/item/mmi/M, mob/user)
	. = ..()
	if(.)
		var/datum/atom_hud/hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		var/mob/living/brain/B = M.brainmob
		hud.add_hud_to(B)
