#define DATA_ICON "icon"
#define DATA_ICON_STATE "icon_state"
#define DATA_ICON_WORN_OVERLAY "mob_overlay_icon"

/obj/item/clothing/glasses/cover
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	var/alist/previous_icon_data = alist(
		DATA_ICON = "",
		DATA_ICON_STATE = "",
		DATA_ICON_WORN_OVERLAY = ""
	)
	var/obj/item/clothing/glasses/wrapped_on
	var/can_switch_eye = TRUE
	var/has_adapt_icon_states = TRUE

/obj/item/clothing/glasses/cover/examine(mob/user)
	. = ..()
	. += span_notice("Под [src] можно установить очки.</span>")

/obj/item/clothing/glasses/cover/afterattack(obj/item/clothing/glasses/target, mob/user)
	. = ..()
	if(!istype(target))
		return

	wrapped_on = target
	if(has_adapt_icon_states)
		icon_state = "[target.glasses_type][icon_state]"
	previous_icon_data[DATA_ICON] = target.icon
	previous_icon_data[DATA_ICON_STATE] = target.icon_state
	previous_icon_data[DATA_ICON_WORN_OVERLAY] = target.mob_overlay_icon
	target.icon = icon
	target.icon_state = icon_state
	target.mob_overlay_icon = mob_overlay_icon
	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER), PROC_REF(remove))
	RegisterSignal(target, COMSIG_ITEM_ATTACK_SELF, PROC_REF(attack_self))
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(wrapped_on_examine))
	forceMove(target)

/obj/item/clothing/glasses/cover/proc/adapt_icon_state(obj/item/clothing/glasses/target)
	icon_state = "[target.glasses_type][icon_state]"

/obj/item/clothing/glasses/cover/proc/wrapped_on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("Под [src] находится [src.loc]. Их можно разьеденить при помощи отвёртки!")

/obj/item/clothing/glasses/cover/proc/remove()
	SIGNAL_HANDLER
	wrapped_on.RemoveElement(/datum/element/update_icon_blocker)
	wrapped_on.icon = previous_icon_data[DATA_ICON]
	wrapped_on.icon_state = previous_icon_data[DATA_ICON_STATE]
	wrapped_on.mob_overlay_icon = previous_icon_data[DATA_ICON_WORN_OVERLAY]
	previous_icon_data[DATA_ICON] = ""
	previous_icon_data[DATA_ICON_STATE] = ""
	previous_icon_data[DATA_ICON_WORN_OVERLAY] = ""
	UnregisterSignal(wrapped_on, list(COMSIG_ATOM_TOOL_ACT(TOOL_SCREWDRIVER), COMSIG_ITEM_ATTACK_SELF, COMSIG_PARENT_EXAMINE))
	forceMove(get_turf(wrapped_on))
	wrapped_on = null

/obj/item/clothing/glasses/cover/attack_self(mob/user)
	. = ..()
	if(!can_switch_eye)
		return
	icon_state = (icon_state == base_icon_state) ? "[base_icon_state]_flipped" : base_icon_state
	if(wrapped_on)
		wrapped_on.icon_state = icon_state
	user.update_inv_glasses()

/obj/item/clothing/glasses/cover/Destroy()
	if(QDELETED(wrapped_on))
		wrapped_on = null
	else
		remove()
	. = ..()

/obj/item/clothing/glasses/cover/eyepatch
	name = "eyepatch"
	desc = "Yarr."
	icon_state = "eyepatch"
	base_icon_state = "eyepatch"

/obj/item/clothing/glasses/cover/fakeblindfold
	name = "thin blindfold"
	desc = "Covers the eyes, but not thick enough to obscure vision. Mostly for aesthetic."
	icon_state = "blindfoldwhite"
	base_icon_state = "blindfoldwhite"
	can_switch_eye = FALSE
	has_adapt_icon_states = FALSE

/obj/item/clothing/glasses/cover/obsolete
	name = "obsolete fake blindfold"
	desc = "An ornate fake blindfold, devoid of any electronics. It's belived to be originally worn by members of bygone military force that sought to protect humanity."
	icon_state = "fold"
	base_icon_state = "fold"
