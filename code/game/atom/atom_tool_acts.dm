/**
 * ## Item interaction
 *
 * Handles non-combat interactions of a tool on this atom,
 * such as using a tool on a wall to deconstruct it,
 * or scanning someone with a health analyzer
 */
/atom/proc/base_item_interaction(mob/living/user, obj/item/tool, params)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	if(tool.tool_behaviour && !SEND_SIGNAL(usr, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		var/tool_return = tool_act(user, tool, tool.tool_behaviour)
		if(tool_return)
			return tool_return

	/*
	 * This is intentionally using `||` instead of `|` to short-circuit the signal calls
	 * This is because we want to return early if ANY of these signals return a value
	 *
	 * This puts priority on the atom's signals, then the tool's signals, then the user's signals,
	 * so we can avoid doing two interactions at once
	 */
	var/early_sig_return = SEND_SIGNAL(src, COMSIG_ATOM_ITEM_INTERACTION, user, tool, params) \
		|| SEND_SIGNAL(tool, COMSIG_ITEM_INTERACTING_WITH_ATOM, user, src, params) \
		|| SEND_SIGNAL(user, COMSIG_USER_ITEM_INTERACTION, src, tool, params)
	if(early_sig_return)
		return early_sig_return

	return NONE
