////////////////////////////////////////////////////////////////////////////////
/// Food.
////////////////////////////////////////////////////////////////////////////////
/// Note: When adding food items with dummy parents, make sure to add
/// the parent to the exclusion list in code/__HELPERS/unsorted.dm's
/// get_random_food proc.
////////////////////////////////////////////////////////////////////////////////


/obj/item/reagent_containers/food
	possible_transfer_amounts = list()
	volume = 50	//Sets the default container amount for all food items.
	reagent_flags = INJECTABLE
	reagent_value = NO_REAGENTS_VALUE
	resistance_flags = FLAMMABLE
	var/foodtype = NONE
	var/last_check_time
	var/food_quality = 50

/obj/item/reagent_containers/food/Initialize(mapload)
	. = ..()
	if(!mapload)
		pixel_x = rand(-5, 5)
		pixel_y = rand(-5, 5)

/obj/item/reagent_containers/food/proc/adjust_food_quality(new_quality)
	food_quality = clamp(new_quality,0,100)

/obj/item/reagent_containers/food/proc/checkLiked(var/fraction, mob/M)
	if(last_check_time + 50 < world.time)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(!HAS_TRAIT(H, TRAIT_AGEUSIA))
				if(foodtype & H.dna.species.toxic_food)
					to_chat(H,"<span class='warning'>What the hell was that thing?!</span>")
					H.adjust_disgust(25 + 30 * fraction)
					SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "toxic_food", /datum/mood_event/disgusting_food)
				else if((foodtype & H.dna.species.disliked_food) || food_quality <= 30)
					to_chat(H,"<span class='notice'>That didn't taste very good...</span>")
					H.adjust_disgust(11 + 15 * fraction)
					SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "gross_food", /datum/mood_event/gross_food)
				else if(((foodtype & H.dna.species.liked_food) && food_quality >= 50) || food_quality >= 70) //you like food of high quality, and food of regular quality you have a preference for
					to_chat(H,"<span class='notice'>I love this taste!</span>")
					H.adjust_disgust(-5 + (-2.5 * food_quality/50) + -2.5 * fraction)
					SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "fav_food", /datum/mood_event/favorite_food)
			else
				if(foodtype & H.dna.species.toxic_food)
					to_chat(H, "<span class='warning'>You don't feel so good...</span>")
					H.adjust_disgust(25 + 30 * fraction)
			if((foodtype & BREAKFAST) && world.time - SSticker.round_start_time < STOP_SERVING_BREAKFAST)
				SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "breakfast", /datum/mood_event/breakfast)
			last_check_time = world.time

///This proc adds the edible component, overwrite this if you for some reason want to change some specific args like callbacks.
/obj/item/reagent_containers/food/snacks/proc/make_edible()
	AddComponent(/datum/component/edible,\
		initial_reagents = list_reagents,\
		food_flags = null,\
		foodtypes = foodtype,\
		volume = volume,\
		eat_time = 10,\
		tastes = tastes,\
		eatverbs = list("ест","вкушает","поедает","пожирает","наяривает","кушает"),\
		bite_consumption = 2,\
		junkiness = junkiness,\
	)
