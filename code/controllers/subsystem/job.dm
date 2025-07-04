SUBSYSTEM_DEF(job)
	name = "Jobs"
	init_order = INIT_ORDER_JOBS
	flags = SS_NO_FIRE

	var/list/occupations = list()		//List of all jobs
	var/list/datum/job/name_occupations = list()	//Dict of all jobs, keys are titles
	var/list/type_occupations = list()	//Dict of all jobs, keys are types
	var/list/unassigned = list()		//Players who need jobs
	var/initial_players_to_assign = 0 	//used for checking against population caps

	var/list/prioritized_jobs = list()
	var/list/latejoin_trackers = list()	//Don't read this list, use GetLateJoinTurfs() instead

	var/overflow_role = "Assistant"

	var/list/level_order = list(JP_HIGH,JP_MEDIUM,JP_LOW)

/datum/controller/subsystem/job/Initialize(timeofday)
	SSmapping.HACK_LoadMapConfig()
	if(!occupations.len)
		SetupOccupations()
	if(CONFIG_GET(flag/load_jobs_from_txt))
		LoadJobs()
	generate_selectable_species()
	set_overflow_role(CONFIG_GET(string/overflow_job))
	return ..()

/// Returns a list of jobs that we are allowed to fuck with during random events
/datum/controller/subsystem/job/proc/get_valid_overflow_jobs()
	var/static/list/overflow_jobs
	if (!isnull(overflow_jobs))
		return overflow_jobs

	overflow_jobs = list()
	for (var/datum/job/check_job in occupations) // TODO: Port joinable_occupations from upstream TG PR #60578.
		if (!check_job.allow_bureaucratic_error)
			continue
		overflow_jobs += check_job
	return overflow_jobs

/datum/controller/subsystem/job/proc/set_overflow_role(new_overflow_role)
	var/datum/job/new_overflow = GetJob(new_overflow_role)
	var/cap = CONFIG_GET(number/overflow_cap)

	if(!new_overflow)
		return

	new_overflow.allow_bureaucratic_error = FALSE
	new_overflow.spawn_positions = cap
	new_overflow.total_positions = cap

	if(new_overflow_role != overflow_role)
		var/datum/job/old_overflow = GetJob(overflow_role)
		old_overflow.allow_bureaucratic_error = initial(old_overflow.allow_bureaucratic_error)
		old_overflow.spawn_positions = initial(old_overflow.spawn_positions)
		old_overflow.total_positions = initial(old_overflow.total_positions)
		overflow_role = new_overflow_role
		JobDebug("Overflow role set to: [new_overflow_role]")

/datum/controller/subsystem/job/proc/SetupOccupations(faction = "Station")
	occupations = list()
	var/list/all_jobs = subtypesof(/datum/job)
	if(!all_jobs.len)
		to_chat(world, "<span class='boldannounce'>Error setting up jobs, no job datums found</span>")
		return FALSE

	for(var/J in all_jobs)
		var/datum/job/job = new J()
		if(!job)
			continue
		if(job.faction != faction)
			continue
		if(!job.config_check())
			continue
		if(!job.map_check(SSmapping.config))	//Even though we initialize before mapping, this is fine because the config is loaded at new
			testing("Removed [job.type] due to map config");
			continue
		job.process_map_overrides(SSmapping.config)
		occupations += job
		name_occupations[job.title] = job
		type_occupations[J] = job

	return TRUE


/datum/controller/subsystem/job/proc/GetJob(rank)
	RETURN_TYPE(/datum/job)
	if(!occupations.len)
		SetupOccupations()
	return name_occupations[rank]

/datum/controller/subsystem/job/proc/GetJobType(jobtype)
	if(!occupations.len)
		SetupOccupations()
	return type_occupations[jobtype]

/datum/controller/subsystem/job/proc/AssignRole(mob/dead/new_player/player, rank, latejoin = FALSE)
	JobDebug("Running AR, Player: [player], Rank: [rank], LJ: [latejoin]")
	if(player && player.mind && rank)
		var/datum/job/job = GetJob(rank)
		if(!job)
			return FALSE
		if(jobban_isbanned(player, rank) || QDELETED(player))
			return FALSE
		if(!job.player_old_enough(player.client))
			return FALSE
		if(job.required_playtime_remaining(player.client))
			return FALSE
		if(job.is_species_blacklisted(player.client)) //BLUEMOON ADDITION - XENO SUPREMACY
			return FALSE //BLUEMOON ADDITION - XENO SUPREMACY
		var/position_limit = job.total_positions
		if(!latejoin)
			position_limit = job.spawn_positions
		JobDebug("Player: [player] is now Rank: [rank], JCP:[job.current_positions], JPL:[position_limit]")
		player.mind.assigned_role = rank
		unassigned -= player
		job.current_positions++
		return TRUE
	JobDebug("AR has failed, Player: [player], Rank: [rank]")
	return FALSE


/datum/controller/subsystem/job/proc/FindOccupationCandidates(datum/job/job, level, flag)
	JobDebug("Running FOC, Job: [job], Level: [level], Flag: [flag]")
	var/list/candidates = list()
	for(var/mob/dead/new_player/player in unassigned)
		if(jobban_isbanned(player, job.title) || QDELETED(player))
			JobDebug("FOC isbanned failed, Player: [player]")
			continue
		if(!job.player_old_enough(player.client))
			JobDebug("FOC player not old enough, Player: [player]")
			continue
		if(job.required_playtime_remaining(player.client))
			JobDebug("FOC player not enough xp, Player: [player]")
			continue
		if(job.is_species_blacklisted(player.client)) //BLUEMOON ADDITION - XENO SUPREMACY
			JobDebug("FOC player not enough xp, Player: [player]") //BLUEMOON ADDITION - XENO SUPREMACY
			continue //BLUEMOON ADDITION - XENO SUPREMACY
		if(!player.client.prefs.pref_species.qualifies_for_rank(job.title, player.client.prefs.features))
			JobDebug("FOC non-human failed, Player: [player]")
			continue
		if(flag && (!(flag in player.client.prefs.be_special)))
			JobDebug("FOC flag failed, Player: [player], Flag: [flag], ")
			continue
		if(player.mind && (job.title in player.mind.restricted_roles))
			JobDebug("FOC incompatible with antagonist role, Player: [player]")
			continue
		if(player.client.prefs.job_preferences[job.title] == level)
			JobDebug("FOC pass, Player: [player], Level:[level]")
			candidates += player
	return candidates

/datum/controller/subsystem/job/proc/GiveRandomJob(mob/dead/new_player/player)
	JobDebug("GRJ Giving random job, Player: [player]")
	. = FALSE
	for(var/datum/job/job in shuffle(occupations))
		if(!job)
			continue

		if(istype(job, GetJob(SSjob.overflow_role))) // We don't want to give him assistant, that's boring!
			continue

		if(job.title in GLOB.command_positions) //If you want a command position, select it!
			continue

		if(jobban_isbanned(player, job.title) || QDELETED(player))
			if(QDELETED(player))
				JobDebug("GRJ isbanned failed, Player deleted")
				break
			JobDebug("GRJ isbanned failed, Player: [player], Job: [job.title]")
			continue

		if(!job.player_old_enough(player.client))
			JobDebug("GRJ player not old enough, Player: [player]")
			continue

		if(!player.client.prefs.pref_species.qualifies_for_rank(job.title, player.client.prefs.features))
			JobDebug("GRJ non-human failed, Player: [player]")
			continue

		if(job.required_playtime_remaining(player.client))
			JobDebug("GRJ player not enough xp, Player: [player]")
			continue
		//BLUEMOON ADDITION - XENO SUPREMACY - START
		if(job.is_species_blacklisted(player.client))
			JobDebug("GRJ player not enough xp, Player: [player]")
			continue
		//BLUEMOON ADDITION - XENO SUPREMACY - END
		if(player.mind && (job.title in player.mind.restricted_roles))
			JobDebug("GRJ incompatible with antagonist role, Player: [player], Job: [job.title]")
			continue

		if((job.current_positions < job.spawn_positions) || job.spawn_positions == -1)
			JobDebug("GRJ Random job given, Player: [player], Job: [job]")
			if(AssignRole(player, job.title))
				return TRUE

/datum/controller/subsystem/job/proc/ResetOccupations()
	JobDebug("Occupations reset.")
	for(var/mob/dead/new_player/player in GLOB.player_list)
		if((player) && (player.mind))
			player.mind.assigned_role = null
			player.mind.special_role = null
			SSpersistence.antag_rep_change[player.ckey] = 0
	SetupOccupations()
	unassigned = list()
	return


//This proc is called before the level loop of DivideOccupations() and will try to select a head, ignoring ALL non-head preferences for every level until
//it locates a head or runs out of levels to check
//This is basically to ensure that there's atleast a few heads in the round
/datum/controller/subsystem/job/proc/FillHeadPosition()
	for(var/level in level_order)
		for(var/command_position in GLOB.command_positions)
			var/datum/job/job = GetJob(command_position)
			if(!job)
				continue
			if((job.current_positions >= job.total_positions) && job.total_positions != -1)
				continue
			var/list/candidates = FindOccupationCandidates(job, level)
			if(!candidates?.len)
				continue
			var/mob/dead/new_player/candidate = pick(candidates)
			if(AssignRole(candidate, command_position))
				return TRUE
	return FALSE


//This proc is called at the start of the level loop of DivideOccupations() and will cause head jobs to be checked before any other jobs of the same level
//This is also to ensure we get as many heads as possible
/datum/controller/subsystem/job/proc/CheckHeadPositions(level)
	for(var/command_position in GLOB.command_positions)
		var/datum/job/job = GetJob(command_position)
		if(!job)
			continue
		if((job.current_positions >= job.total_positions) && job.total_positions != -1)
			continue
		var/list/candidates = FindOccupationCandidates(job, level)
		if(!candidates?.len)
			continue
		var/mob/dead/new_player/candidate = pick(candidates)
		AssignRole(candidate, command_position)

/datum/controller/subsystem/job/proc/FillAIPosition()
	var/ai_selected = 0
	var/datum/job/job = GetJob("AI")
	if(!job)
		return FALSE
	for(var/i = job.total_positions, i > 0, i--)
		for(var/level in level_order)
			var/list/candidates = list()
			candidates = FindOccupationCandidates(job, level)
			if(candidates.len)
				var/mob/dead/new_player/candidate = pick(candidates)
				if(AssignRole(candidate, "AI"))
					ai_selected++
					break
	if(ai_selected)
		return TRUE
	return FALSE


/** Proc DivideOccupations
 *  fills var "assigned_role" for all ready players.
 *  This proc must not have any side effect besides of modifying "assigned_role".
 **/
/datum/controller/subsystem/job/proc/DivideOccupations(list/required_jobs)
	//Setup new player list and get the jobs list
	JobDebug("Running DO")

	//Holder for Triumvirate is stored in the SSticker, this just processes it
	if(SSticker.triai)
		for(var/datum/job/ai/A in occupations)
			A.spawn_positions = 3
		for(var/obj/effect/landmark/start/ai/secondary/S in GLOB.start_landmarks_list)
			S.latejoin_active = TRUE

	//Get the players who are ready
	for(var/mob/dead/new_player/player in GLOB.player_list)
		if(player.ready == PLAYER_READY_TO_PLAY && player.check_preferences() && player.mind && !player.mind.assigned_role)
			unassigned += player

	initial_players_to_assign = unassigned.len

	JobDebug("DO, Len: [unassigned?.len]")
	if(unassigned.len == 0)
		return validate_required_jobs(required_jobs)

	//Scale number of open security officer slots to population
	setup_officer_positions()

	//Jobs will have fewer access permissions if the number of players exceeds the threshold defined in game_options.txt
	var/mat = CONFIG_GET(number/minimal_access_threshold)
	if(mat)
		if(mat > GLOB.player_list.len)  // BLUEMOON CHANGES (изменяем, чтобы подсчитывало не количество рэди, а всех игроков в онлайне для skeleton crew) - WAS unassigned.len
			CONFIG_SET(flag/jobs_have_minimal_access, FALSE)
		else
			CONFIG_SET(flag/jobs_have_minimal_access, TRUE)

	//Shuffle players and jobs
	unassigned = shuffle(unassigned)

	HandleFeedbackGathering()

	//People who wants to be the overflow role, sure, go on.
	JobDebug("DO, Running Overflow Check 1")
	var/datum/job/overflow = GetJob(SSjob.overflow_role)
	var/list/overflow_candidates = FindOccupationCandidates(overflow, JP_LOW)
	JobDebug("AC1, Candidates: [overflow_candidates?.len]")
	for(var/mob/dead/new_player/player in overflow_candidates)
		JobDebug("AC1 pass, Player: [player]")
		AssignRole(player, SSjob.overflow_role)
		overflow_candidates -= player
	JobDebug("DO, AC1 end")

	//Select one head
	JobDebug("DO, Running Head Check")
	FillHeadPosition()
	JobDebug("DO, Head Check end")

	//Check for an AI
	JobDebug("DO, Running AI Check")
	FillAIPosition()
	JobDebug("DO, AI Check end")

	//Other jobs are now checked
	JobDebug("DO, Running Standard Check")


	// New job giving system by Donkie
	// This will cause lots of more loops, but since it's only done once it shouldn't really matter much at all.
	// Hopefully this will add more randomness and fairness to job giving.

	// Loop through all levels from high to low
	var/list/shuffledoccupations = shuffle(occupations)
	for(var/level in level_order)
		//Check the head jobs first each level
		CheckHeadPositions(level)

		// Loop through all unassigned players
		for(var/mob/dead/new_player/player in unassigned)
			if(PopcapReached())
				RejectPlayer(player)

			// Loop through all jobs
			for(var/datum/job/job in shuffledoccupations) // SHUFFLE ME BABY
				if(!job)
					continue

				if(jobban_isbanned(player, job.title))
					JobDebug("DO isbanned failed, Player: [player], Job:[job.title]")
					continue

				if(QDELETED(player))
					JobDebug("DO player deleted during job ban check")
					break

				if(!job.player_old_enough(player.client))
					JobDebug("DO player not old enough, Player: [player], Job:[job.title]")
					continue

				if(job.required_playtime_remaining(player.client))
					JobDebug("DO player not enough xp, Player: [player], Job:[job.title]")
					continue
				//BLUEMOON ADDITION - XENO SUPREMACY - START
				if(job.is_species_blacklisted(player.client))
					JobDebug("DO player not enough xp, Player: [player], Job:[job.title]")
					continue
				//BLUEMOON ADDITION - XENO SUPREMACY - END
				if(!player.client.prefs.pref_species.qualifies_for_rank(job.title, player.client.prefs.features))
					JobDebug("DO non-human failed, Player: [player], Job:[job.title]")
					continue

				if(player.mind && (job.title in player.mind.restricted_roles))
					JobDebug("DO incompatible with antagonist role, Player: [player], Job:[job.title]")
					continue

				// If the player wants that job on this level, then try give it to him.
				if(player.client.prefs.job_preferences[job.title] == level)
					// If the job isn't filled
					if((job.current_positions < job.spawn_positions) || job.spawn_positions == -1)
						JobDebug("DO pass, Player: [player], Level:[level], Job:[job.title]")
						AssignRole(player, job.title)
						unassigned -= player
						break


	JobDebug("DO, Handling unassigned.")
	// Hand out random jobs to the people who didn't get any in the last check
	// Also makes sure that they got their preference correct
	for(var/mob/dead/new_player/player in unassigned)
		HandleUnassigned(player)

	JobDebug("DO, Handling unrejectable unassigned")
	//Mop up people who can't leave.
	for(var/mob/dead/new_player/player in unassigned) //Players that wanted to back out but couldn't because they're antags (can you feel the edge case?)
/* BLUEMOON REMOVAL START - убираем вариант получения рандомной роли при получении антажки, оставляя только ассистента
		if(player.client.prefs.joblessrole == BERANDOMJOB) //Gives the player a random role if their preferences are set to it
			if(!GiveRandomJob(player))
				if(!AssignRole(player, SSjob.overflow_role)) //If everything is already filled, make them the overflow role
					return FALSE //Living on the edge, the forced antagonist couldn't be assigned to overflow role (bans, client age) - just reroll

		else //If the player prefers to return to lobby or be an assistant, give them assistant
/ BLUEMOON REMOVAL END */
		if(!AssignRole(player, SSjob.overflow_role))
			if(!GiveRandomJob(player)) //The forced antagonist couldn't be assigned to overflow role (bans, client age) - give a random role
				return FALSE //Somehow the forced antagonist couldn't be assigned to the overflow role or the a random role - reroll

	return validate_required_jobs(required_jobs)

/datum/controller/subsystem/job/proc/validate_required_jobs(list/required_jobs)
	if(!required_jobs.len)
		return TRUE
	for(var/required_group in required_jobs)
		var/group_ok = TRUE
		for(var/rank in required_group)
			var/datum/job/J = GetJob(rank)
			if(!J)
				SSticker.mode.setup_error = "Invalid job [rank] in gamemode required jobs."
				return FALSE
			if(J.current_positions < required_group[rank])
				group_ok = FALSE
				break
		if(group_ok)
			return TRUE
	SSticker.mode.setup_error = "Required jobs not present."
	return FALSE

//We couldn't find a job from prefs for this guy.
/datum/controller/subsystem/job/proc/HandleUnassigned(mob/dead/new_player/player)
	if(PopcapReached())
		RejectPlayer(player)
	else if(player.client.prefs.joblessrole == BEOVERFLOW)
		var/allowed_to_be_a_loser = !jobban_isbanned(player, SSjob.overflow_role)
		if(QDELETED(player) || !allowed_to_be_a_loser)
			RejectPlayer(player)
		else
			if(!AssignRole(player, SSjob.overflow_role))
				RejectPlayer(player)
	else if(player.client.prefs.joblessrole == BERANDOMJOB)
		if(!GiveRandomJob(player))
			RejectPlayer(player)
	else if(player.client.prefs.joblessrole == RETURNTOLOBBY)
		RejectPlayer(player)
	else //Something gone wrong if we got here.
		var/message = "DO: [player] fell through handling unassigned"
		JobDebug(message)
		log_game(message)
		message_admins(message)
		RejectPlayer(player)
//Gives the player the stuff he should have with his rank
/datum/controller/subsystem/job/proc/EquipRank(mob/M, rank, joined_late = FALSE)
	var/mob/dead/new_player/N
	var/mob/living/H
	if(!joined_late)
		N = M
		H = N.new_character
	else
		H = M

	var/datum/job/job = GetJob(rank)

	H.job = rank

	//If we joined at roundstart we should be positioned at our workstation
	if(!joined_late)
		var/atom/S = job.get_roundstart_spawn_point(H)
		if(S)
			S.JoinPlayerHere(H, FALSE)
		if(!S) //if there isn't a spawnpoint send them to latejoin, if there's no latejoin go yell at your mapper
			log_world("Couldn't find a round start spawn point for [rank]")
			SendToLateJoin(H)

	var/ambition_text
	if(H.mind)
		H.mind.assigned_role = rank
		ambition_text = H.mind.assign_random_ambition()

	if(H.mind)
		H.mind.assigned_role = rank

	if(job)
		if(!job.dresscodecompliant)// CIT CHANGE - dress code compliance
			equip_loadout(N, H) // CIT CHANGE - allows players to spawn with loadout items
		var/new_mob = job.equip(H, null, null, joined_late , null, M.client)
		if(ismob(new_mob))
			H = new_mob
			if(!joined_late)
				N.new_character = H
			else
				M = H

		SSpersistence.antag_rep_change[M.client.ckey] += job.GetAntagRep()

		if(M.client.holder)
			if(CONFIG_GET(flag/auto_deadmin_players) || (M.client.prefs?.deadmin & DEADMIN_ALWAYS))
				M.client.holder.auto_deadmin()
			else
				handle_auto_deadmin_roles(M.client, rank)

	var/display_rank = rank
	if(M.client && M.client.prefs && M.client?.prefs?.alt_titles_preferences[rank])
		display_rank = M.client?.prefs?.alt_titles_preferences[rank]
	// BLUEMOON EDIT - текст при входе в раунд
	var/flavor_display_text = ""
	flavor_display_text += "<p class='medium'>Вы - <b>[display_rank].</b></p>\n"
	if(job)
		flavor_display_text += "<p>Будучи <b>[display_rank]</b>, вы обязаны подчиняться приказам <b>[job.supervisors]</b>. В некоторых случаях, это может измениться.\n</p>"
		flavor_display_text += "<p>Начните своё сообщение с :р или .р, чтобы воспользоваться радиоканалом вашего отдела. Другие префиксы указаны на вашей гарнитуре.\n</p>"
		flavor_display_text += "<b class='notice_l'>Обратите внимание:\n</b>"
		if(job.req_admin_notify)
			flavor_display_text += "\n<li><span class='notice'>вы играете роль, важную для прогрессии раунда. Если вам необходимо отключиться, пожалуйста, уведомите администрацию и верните всю экипировку в шкафчик.</span></li>"
		if(CONFIG_GET(number/minimal_access_threshold) && !CONFIG_GET(flag/jobs_have_minimal_access))
			flavor_display_text += "\n<li>ввиду критической нехватки персонала, ваша ID-карта имеет дополнительный доступ.</li>"
		if(job.custom_spawn_text)
			flavor_display_text += "\n<li>[job.custom_spawn_text]</li>"
	if(ishuman(H))
		var/mob/living/carbon/human/wageslave = H
		flavor_display_text += "\n<li>номер вашего банковского аккаунта - [wageslave.account_id].</li>"
		H.add_memory("Номер вашего банковского аккаунта - [wageslave.account_id].")
	to_chat(M, examine_block(flavor_display_text))
	// BLUEMOON EDIT END
	if(job && H)
		if(job.dresscodecompliant)// CIT CHANGE - dress code compliance
			equip_loadout(N, H) // CIT CHANGE - allows players to spawn with loadout items
		job.after_spawn(H, M.client, joined_late) // note: this happens before the mob has a key! M will always have a client, H might not.
		post_equip_loadout(N, H)//CIT CHANGE - makes players spawn with in-backpack loadout items properly. A little hacky but it works

		handle_roundstart_items(H, M.ckey, H.mind.assigned_role, H.mind.special_role)

	var/list/tcg_cards
	if(ishuman(H))
		if(length(H.client?.prefs?.tcg_cards))
			tcg_cards = H.client.prefs.tcg_cards
		else if(length(N?.client?.prefs?.tcg_cards))
			tcg_cards = N.client.prefs.tcg_cards
	if(tcg_cards)
		var/obj/item/tcgcard_binder/binder = new(get_turf(H))
		H.equip_to_slot_if_possible(binder, ITEM_SLOT_BACKPACK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		for(var/card_type in N.client.prefs.tcg_cards)
			if(card_type)
				if(islist(H.client.prefs.tcg_cards[card_type]))
					for(var/duplicate in N.client.prefs.tcg_cards[card_type])
						var/obj/item/tcg_card/card = new(get_turf(H), card_type, duplicate)
						card.forceMove(binder)
						binder.cards.Add(card)
				else
					var/obj/item/tcg_card/card = new(get_turf(H), card_type, N.client.prefs.tcg_cards[card_type])
					card.forceMove(binder)
					binder.cards.Add(card)
		binder.check_for_exodia()
		if(length(N.client.prefs.tcg_decks))
			binder.decks = N.client.prefs.tcg_decks

	if(ambition_text)
		to_chat(M, span_notice(ambition_text))

	return H

/datum/controller/subsystem/job/proc/handle_auto_deadmin_roles(client/C, rank)
	if(!C?.holder)
		return TRUE
	var/datum/job/job = GetJob(rank)
	if(!job)
		return
	if((job.auto_deadmin_role_flags & DEADMIN_POSITION_HEAD) && (CONFIG_GET(flag/auto_deadmin_heads) || (C.prefs?.deadmin & DEADMIN_POSITION_HEAD)))
		return C.holder.auto_deadmin()
	else if((job.auto_deadmin_role_flags & DEADMIN_POSITION_SECURITY) && (CONFIG_GET(flag/auto_deadmin_security) || (C.prefs?.deadmin & DEADMIN_POSITION_SECURITY)))
		return C.holder.auto_deadmin()
	else if((job.auto_deadmin_role_flags & DEADMIN_POSITION_SILICON) && (CONFIG_GET(flag/auto_deadmin_silicons) || (C.prefs?.deadmin & DEADMIN_POSITION_SILICON))) //in the event there's ever psuedo-silicon roles added, ie synths.
		return C.holder.auto_deadmin()

/datum/controller/subsystem/job/proc/setup_officer_positions()
	var/datum/job/J = SSjob.GetJob("Security Officer")
	if(!J)
		CRASH("setup_officer_positions(): Security officer job is missing")

	var/ssc = CONFIG_GET(number/security_scaling_coeff)
	if(ssc > 0)
		if(J.spawn_positions > 0)
			var/officer_positions = min(12, max(J.spawn_positions, round(unassigned.len / ssc))) //Scale between configured minimum and 12 officers
			JobDebug("Setting open security officer positions to [officer_positions]")
			J.total_positions = officer_positions
			J.spawn_positions = officer_positions

	//Spawn some extra eqipment lockers if we have more than 5 officers
	var/equip_needed = J.total_positions
	if(equip_needed < 0) // -1: infinite available slots
		equip_needed = 12
	for(var/i=equip_needed-5, i>0, i--)
		if(GLOB.secequipment.len)
			var/spawnloc = GLOB.secequipment[1]
			new /obj/structure/closet/secure_closet/security/sec(spawnloc)
			GLOB.secequipment -= spawnloc
		else //We ran out of spare locker spawns!
			break


/datum/controller/subsystem/job/proc/LoadJobs()
	var/jobstext = file2text("[global.config.directory]/jobs.txt")
	for(var/datum/job/J in occupations)
		var/regex/jobs = new("[J.title]=(-1|\\d+),(-1|\\d+)")
		if(!jobs.Find(jobstext))
			continue
		J.total_positions = text2num(jobs.group[1])
		J.spawn_positions = text2num(jobs.group[2])

/datum/controller/subsystem/job/proc/HandleFeedbackGathering()
	for(var/datum/job/job in occupations)
		var/high = 0 //high
		var/medium = 0 //medium
		var/low = 0 //low
		var/never = 0 //never
		var/banned = 0 //banned
		var/young = 0 //account too young
		for(var/mob/dead/new_player/player in GLOB.player_list)
			if(!(player.ready == PLAYER_READY_TO_PLAY && player.mind && !player.mind.assigned_role))
				continue //This player is not ready
			if(jobban_isbanned(player, job.title) || QDELETED(player))
				banned++
				continue
			if(!job.player_old_enough(player.client))
				young++
				continue
			if(job.required_playtime_remaining(player.client))
				young++
				continue
			switch(player.client.prefs.job_preferences[job.title])
				if(JP_HIGH)
					high++
				if(JP_MEDIUM)
					medium++
				if(JP_LOW)
					low++
				else
					never++
		SSblackbox.record_feedback("nested tally", "job_preferences", high, list("[job.title]", "high"))
		SSblackbox.record_feedback("nested tally", "job_preferences", medium, list("[job.title]", "medium"))
		SSblackbox.record_feedback("nested tally", "job_preferences", low, list("[job.title]", "low"))
		SSblackbox.record_feedback("nested tally", "job_preferences", never, list("[job.title]", "never"))
		SSblackbox.record_feedback("nested tally", "job_preferences", banned, list("[job.title]", "banned"))
		SSblackbox.record_feedback("nested tally", "job_preferences", young, list("[job.title]", "young"))

/datum/controller/subsystem/job/proc/PopcapReached()
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc || epc)
		var/relevent_cap = max(hpc, epc)
		if((initial_players_to_assign - unassigned.len) >= relevent_cap)
			return TRUE
	return FALSE

/datum/controller/subsystem/job/proc/RejectPlayer(mob/dead/new_player/player)
	if(player.mind && player.mind.special_role)
		return
	if(PopcapReached())
		JobDebug("Popcap overflow Check observer located, Player: [player]")
	JobDebug("Player rejected :[player]")
	to_chat(player, "<b>You have failed to qualify for any job you desired.</b>")
	unassigned -= player
	player.ready = PLAYER_NOT_READY


/datum/controller/subsystem/job/Recover()
	set waitfor = FALSE
	var/oldjobs = SSjob.occupations
	sleep(20)
	for (var/datum/job/J in oldjobs)
		INVOKE_ASYNC(src, PROC_REF(RecoverJob), J)

/datum/controller/subsystem/job/proc/RecoverJob(datum/job/J)
	var/datum/job/newjob = GetJob(J.title)
	if (!istype(newjob))
		return
	newjob.total_positions = J.total_positions
	newjob.spawn_positions = J.spawn_positions
	newjob.current_positions = J.current_positions

/atom/proc/JoinPlayerHere(mob/M, buckle)
	// By default, just place the mob on the same turf as the marker or whatever.
	M.forceMove(get_turf(src))

/obj/structure/chair/JoinPlayerHere(mob/M, buckle)
	// Placing a mob in a chair will attempt to buckle it, or else fall back to default.
	if (buckle && isliving(M) && buckle_mob(M, FALSE, FALSE))
		return
	..()

/datum/controller/subsystem/job/proc/SendToLateJoin(mob/M, buckle = TRUE)
	var/atom/destination
	if(M.mind && M.mind.assigned_role && length(GLOB.jobspawn_overrides[M.mind.assigned_role])) //We're doing something special today.
		destination = pick(GLOB.jobspawn_overrides[M.mind.assigned_role])
		destination.JoinPlayerHere(M, FALSE)
		return

	if(latejoin_trackers.len)
		destination = pick(latejoin_trackers)
		destination.JoinPlayerHere(M, buckle)
		return

	//bad mojo
	var/area/shuttle/arrival/A = GLOB.areas_by_type[/area/shuttle/arrival]
	if(A)
		//first check if we can find a chair
		var/obj/structure/chair/C = locate() in A
		if(C)
			C.JoinPlayerHere(M, buckle)
			return

		//last hurrah
		var/list/avail = list()
		for(var/turf/T in A)
			if(!is_blocked_turf(T, TRUE))
				avail += T
		if(avail.len)
			destination = pick(avail)
			destination.JoinPlayerHere(M, FALSE)
			return

	//pick an open spot on arrivals and dump em
	var/list/arrivals_turfs = shuffle(get_area_turfs(/area/shuttle/arrival))
	if(arrivals_turfs.len)
		for(var/turf/T in arrivals_turfs)
			if(!is_blocked_turf(T, TRUE))
				T.JoinPlayerHere(M, FALSE)
				return
		//last chance, pick ANY spot on arrivals and dump em
		destination = arrivals_turfs[1]
		destination.JoinPlayerHere(M, FALSE)
	else
		var/msg = "Unable to send mob [M] to late join!"
		message_admins(msg)
		CRASH(msg)

/datum/controller/subsystem/job/proc/equip_loadout(mob/dead/new_player/N, mob/living/M, bypass_prereqs = FALSE, can_drop = TRUE, is_dummy = FALSE)
	var/mob/the_mob = N
	if(!the_mob)
		the_mob = M // cause this doesn't get assigned if player is a latejoiner
	var/list/chosen_gear
	if(the_mob.client.prefs.loadout_data)
		chosen_gear = the_mob.client.prefs.loadout_data["SAVE_[the_mob.client.prefs.loadout_slot]"]
	var/heirloomer = FALSE
	if(!is_dummy)
		var/list/my_quirks = the_mob.client.prefs.all_quirks.Copy()
		if("Семейная реликвия" in my_quirks)
			heirloomer = TRUE
	if(the_mob.client && the_mob.client.prefs && (chosen_gear && chosen_gear.len))
		if(!ishuman(M))//no silicons allowed
			return
		for(var/i in chosen_gear)
			var/datum/gear/G = istext(i[LOADOUT_ITEM]) ? text2path(i[LOADOUT_ITEM]) : i[LOADOUT_ITEM]
			if(!ispath(G))
				continue
			G = GLOB.loadout_items[initial(G.category)][initial(G.subcategory)][initial(G.name)]
			if(!G)
				continue
			var/permitted = TRUE
			if(!bypass_prereqs && G.restricted_roles && G.restricted_roles.len && !(M.mind.assigned_role in G.restricted_roles))
				permitted = FALSE
			if(G.donoritem && !G.donator_ckey_check(the_mob.client.ckey))
				permitted = FALSE
			if(G.handle_post_equip)
				permitted = FALSE
			if(!permitted)
				// BLUEMOON ADD START - выбор вещей из лодаута как family heirloom
				if(i[LOADOUT_IS_HEIRLOOM] && heirloomer && !G.handle_post_equip)
					to_chat(M, "<span class='warning'>Вы не смогли взять с собой свой любимый предмет, [G.name], из-за ограничений вашей профессии или других проблем, но у вас была и другая семейная ценность, поэтому вы прихватили её!</span>")
				// BLUEMOON END
				continue
			var/obj/item/I = new G.path
			if(I)
				if(length(i[LOADOUT_COLOR])) //handle loadout colors
				 	//handle polychromic items
					if((G.loadout_flags & LOADOUT_CAN_COLOR_POLYCHROMIC) && length(G.loadout_initial_colors))
						var/datum/element/polychromic/polychromic = LAZYACCESS(I.comp_lookup, "item_worn_overlays") //stupid way to do it but GetElement does not work for this
						if(polychromic && istype(polychromic))
							var/list/polychromic_entry = polychromic.colors_by_atom[I]
							if(polychromic_entry)
								if(polychromic.suits_with_helmet_typecache[I.type]) //is this one of those toggleable hood/helmet things?
									polychromic.connect_helmet(I,i[LOADOUT_COLOR])
								polychromic.colors_by_atom[I] = i[LOADOUT_COLOR]
								I.update_icon()
					else
						//handle non-polychromic items (they only have one color)
						I.add_atom_colour(i[LOADOUT_COLOR][1], FIXED_COLOUR_PRIORITY)
						I.update_icon()
				//when inputting the data it's already sanitized
				if(i[LOADOUT_CUSTOM_NAME])
					var/custom_name = i[LOADOUT_CUSTOM_NAME]
					I.name = custom_name
				if(i[LOADOUT_CUSTOM_DESCRIPTION])
					var/custom_description = i[LOADOUT_CUSTOM_DESCRIPTION]
					I.desc = custom_description
				if(i["loadout_custom_tagname"]) //for collars with tagnames
					var/custom_tagname = i["loadout_custom_tagname"]
					var/obj/item/clothing/neck/petcollar/collar = I
					collar.tagname = custom_tagname
					collar.name = "[initial(collar.name)] - [collar.tagname]"
			if(!M.equip_to_slot_if_possible(I, G.slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE)) // If the job's dresscode compliant, try to put it in its slot, first
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					var/obj/item/storage/backpack/B = C.back
					if(!B || !SEND_SIGNAL(B, COMSIG_TRY_STORAGE_INSERT, I, null, TRUE, TRUE)) // Otherwise, try to put it in the backpack, for carbons.
						if(can_drop)
							I.forceMove(get_turf(C))
						else
							qdel(I)
				else if(!M.equip_to_slot_if_possible(I, ITEM_SLOT_BACKPACK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)) // Otherwise, try to put it in the backpack
					if(can_drop)
						I.forceMove(get_turf(M)) // If everything fails, just put it on the floor under the mob.
					else
						qdel(I)
			// BLUEMOON ADD START - выбор вещей из лодаута как family heirloom
			if(i[LOADOUT_IS_HEIRLOOM] && !QDELETED(I) && heirloomer)
				I.item_flags |= FAMILY_HEIRLOOM
				M.mind.assigned_heirloom = I
				if(!i[LOADOUT_CUSTOM_NAME])
					var/list/family_name = splittext(M.real_name, " ")
					I.name = "\improper [family_name[family_name.len]] family [I.name]"
			// Эффект при спавне
			G.on_spawn(M, I)
			// BLUEMOON ADD END


/datum/controller/subsystem/job/proc/post_equip_loadout(mob/dead/new_player/N, mob/living/M, bypass_prereqs = FALSE, can_drop = TRUE, is_dummy = FALSE)
	var/mob/the_mob = N
	if(!the_mob)
		the_mob = M // cause this doesn't get assigned if player is a latejoiner
	var/list/chosen_gear
	if(the_mob.client.prefs.loadout_data)
		chosen_gear = the_mob.client.prefs.loadout_data["SAVE_[the_mob.client.prefs.loadout_slot]"]
	var/heirloomer = FALSE
	if(!is_dummy)
		var/list/my_quirks = the_mob.client.prefs.all_quirks.Copy()
		if("Семейная реликвия" in my_quirks)
			heirloomer = TRUE
	if(the_mob.client && the_mob.client.prefs && (chosen_gear && chosen_gear.len))
		if(!ishuman(M))//no silicons allowed
			return
		for(var/i in chosen_gear)
			var/datum/gear/G = istext(i[LOADOUT_ITEM]) ? text2path(i[LOADOUT_ITEM]) : i[LOADOUT_ITEM]
			if(!ispath(G))
				continue
			G = GLOB.loadout_items[initial(G.category)][initial(G.subcategory)][initial(G.name)]
			if(!G)
				continue
			var/permitted = TRUE
			if(!bypass_prereqs && G.restricted_roles && G.restricted_roles.len && !(M.mind.assigned_role in G.restricted_roles))
				permitted = FALSE
			if(G.donoritem && !G.donator_ckey_check(the_mob.client.ckey))
				permitted = FALSE
			if(!G.handle_post_equip)
				permitted = FALSE
			if(!permitted)
				// BLUEMOON ADD START - выбор вещей из лодаута как family heirloom
				if(i[LOADOUT_IS_HEIRLOOM] && heirloomer && G.handle_post_equip)
					to_chat(M, "<span class='warning'>Вы не смогли взять с собой свой любимый предмет, [G.name], из-за ограничений вашей профессии или других проблем, но у вас была и другая семейная ценность, поэтому вы прихватили её!</span>")
				// BLUEMOON ADD END
				continue
			var/obj/item/I = new G.path
			if(I)
				if(length(i[LOADOUT_COLOR])) //handle loadout colors
				 	//handle polychromic items
					if((G.loadout_flags & LOADOUT_CAN_COLOR_POLYCHROMIC) && length(G.loadout_initial_colors))
						var/datum/element/polychromic/polychromic = LAZYACCESS(I.comp_lookup, "item_worn_overlays") //stupid way to do it but GetElement does not work for this
						if(polychromic && istype(polychromic))
							var/list/polychromic_entry = polychromic.colors_by_atom[I]
							if(polychromic_entry)
								if(polychromic.suits_with_helmet_typecache[I.type]) //is this one of those toggleable hood/helmet things?
									polychromic.connect_helmet(I,i[LOADOUT_COLOR])
								polychromic.colors_by_atom[I] = i[LOADOUT_COLOR]
								I.update_icon()
					else
						//handle non-polychromic items (they only have one color)
						I.add_atom_colour(i[LOADOUT_COLOR][1], FIXED_COLOUR_PRIORITY)
						I.update_icon()
				//when inputting the data it's already sanitized
				if(i[LOADOUT_CUSTOM_NAME])
					var/custom_name = i[LOADOUT_CUSTOM_NAME]
					I.name = custom_name
				if(i[LOADOUT_CUSTOM_DESCRIPTION])
					var/custom_description = i[LOADOUT_CUSTOM_DESCRIPTION]
					I.desc = custom_description
				if(i["loadout_custom_tagname"]) //for collars with tagnames
					var/custom_tagname = i["loadout_custom_tagname"]
					var/obj/item/clothing/neck/petcollar/collar = I
					collar.tagname = custom_tagname
					collar.name = "[initial(collar.name)] - [collar.tagname]"
			if(!M.equip_to_slot_if_possible(I, G.slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE)) // If the job's dresscode compliant, try to put it in its slot, first
				if(iscarbon(M))
					var/mob/living/carbon/C = M
					var/obj/item/storage/backpack/B = C.back
					if(!B || !SEND_SIGNAL(B, COMSIG_TRY_STORAGE_INSERT, I, null, TRUE, TRUE)) // Otherwise, try to put it in the backpack, for carbons.
						if(can_drop)
							I.forceMove(get_turf(C))
						else
							qdel(I)
				else if(!M.equip_to_slot_if_possible(I, ITEM_SLOT_BACKPACK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)) // Otherwise, try to put it in the backpack
					if(can_drop)
						I.forceMove(get_turf(M)) // If everything fails, just put it on the floor under the mob.
					else
						qdel(I)
			// BLUEMOON ADD START - выбор вещей из лодаута как family heirloom
			if(i[LOADOUT_IS_HEIRLOOM] && !QDELETED(I) && heirloomer)
				I.item_flags |= FAMILY_HEIRLOOM
				M.mind.assigned_heirloom = I
				if(!i[LOADOUT_CUSTOM_NAME])
					var/list/family_name = splittext(M.real_name, " ")
					I.name = "\improper [family_name[family_name.len]] family [I.name]"
			// Эффект при спавне
			G.on_spawn(M, I)
			// BLUEMOON ADD END

/datum/controller/subsystem/job/proc/FreeRole(rank)
	if(!rank)
		return
	var/datum/job/job = GetJob(rank)
	if(!job)
		return FALSE
	job.current_positions = max(0, job.current_positions - 1)

/datum/controller/subsystem/job/proc/get_last_resort_spawn_points()
	//bad mojo
	var/area/shuttle/arrival/arrivals_area = GLOB.areas_by_type[/area/shuttle/arrival]
	if(arrivals_area)
		//first check if we can find a chair
		var/obj/structure/chair/shuttle_chair = locate() in arrivals_area
		if(shuttle_chair)
			return shuttle_chair

		//last hurrah
		var/list/turf/available_turfs = list()
		for(var/turf/arrivals_turf in arrivals_area)
			if(!is_blocked_turf(arrivals_turf, TRUE))
				available_turfs += arrivals_turf
		if(length(available_turfs))
			return pick(available_turfs)

	//pick an open spot on arrivals and dump em
	var/list/arrivals_turfs = shuffle(get_area_turfs(/area/shuttle/arrival))
	if(length(arrivals_turfs))
		for(var/turf/arrivals_turf in arrivals_turfs)
			if(!is_blocked_turf(arrivals_turf, TRUE))
				return arrivals_turf
		//last chance, pick ANY spot on arrivals and dump em
		return pick(arrivals_turfs)

	stack_trace("Unable to find last resort spawn point.")
	return GET_ERROR_ROOM

///////////////////////////////////
//Keeps track of all living heads//
///////////////////////////////////
/datum/controller/subsystem/job/proc/get_living_heads()
	. = list()
	for(var/mob/living/carbon/human/player in GLOB.alive_mob_list)
		if(player.stat != DEAD && player.mind && (player.mind.assigned_role in GLOB.command_positions))
			. |= player.mind


////////////////////////////
//Keeps track of all heads//
////////////////////////////
/datum/controller/subsystem/job/proc/get_all_heads()
	. = list()
	for(var/i in GLOB.mob_list)
		var/mob/player = i
		if(player.mind && (player.mind.assigned_role in GLOB.command_positions))
			. |= player.mind

//////////////////////////////////////////////
//Keeps track of all living security members//
//////////////////////////////////////////////
/datum/controller/subsystem/job/proc/get_living_sec()
	. = list()
	for(var/mob/living/carbon/human/player in GLOB.carbon_list)
		if(player.stat != DEAD && player.mind && (player.mind.assigned_role in GLOB.security_positions))
			. |= player.mind

////////////////////////////////////////
//Keeps track of all  security members//
////////////////////////////////////////
/datum/controller/subsystem/job/proc/get_all_sec()
	. = list()
	for(var/mob/living/carbon/human/player in GLOB.carbon_list)
		if(player.mind && (player.mind.assigned_role in GLOB.security_positions))
			. |= player.mind

/datum/controller/subsystem/job/proc/JobDebug(message)
	log_job_debug(message)

/datum/controller/subsystem/job/proc/notify_dept_head(jobtitle, antext)
	// Used to notify the department head of jobtitle X that their employee was brigged, demoted or terminated
	if(!jobtitle || !antext)
		return
	var/datum/job/tgt_job = GetJob(jobtitle)
	if(!tgt_job)
		return
	if(!tgt_job.department_head[1])
		return
	var/boss_title = tgt_job.department_head[1]
	var/obj/item/pda/target_pda
	for(var/obj/item/pda/check_pda in GLOB.PDAs)
		if(check_pda.ownjob == boss_title)
			target_pda = check_pda
			break
	if(!target_pda)
		return
	if(target_pda && target_pda.toff)
		target_pda.send_message("<b>Автоматическое Оповещение: </b>\"[antext]\" (Невозможно Ответить)", 0) // the 0 means don't make the PDA flash

///obj/item/paper/paperslip/corporate/fluff/spare_id_safe_code
//	name = "Nanotrasen-Approved Spare ID Safe Code"
//	desc = "Proof that you have been approved for Captaincy, with all its glory and all its horror."
//
///obj/item/paper/paperslip/corporate/fluff/spare_id_safe_code/Initialize(mapload)
//	var/safe_code = SSid_access.spare_id_safe_code
//	default_raw_text = "Captain's Spare ID safe code combination: [safe_code ? safe_code : "\[REDACTED\]"]<br><br>The spare ID can be found in its dedicated safe on the bridge.<br><br>If your job would not ordinarily have Head of Staff access, your ID card has been specially modified to possess it."
//	return ..()
//
///obj/item/paper/paperslip/corporate/fluff/emergency_spare_id_safe_code
//	name = "Emergency Spare ID Safe Code Requisition"
//	desc = "Proof that nobody has been approved for Captaincy. A skeleton key for a skeleton shift."
//
///obj/item/paper/paperslip/corporate/fluff/emergency_spare_id_safe_code/Initialize(mapload)
//	var/safe_code = SSid_access.spare_id_safe_code
//	default_raw_text = "Captain's Spare ID safe code combination: [safe_code ? safe_code : "\[REDACTED\]"]<br><br>The spare ID can be found in its dedicated safe on the bridge."
//	return ..()
