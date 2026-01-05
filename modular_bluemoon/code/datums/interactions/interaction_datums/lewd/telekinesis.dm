#define TK_MAXRANGE 7 // Предел радиуса отображения сообщений через visible_message
/datum/interaction/TKhug
	description = "Телекинез. Обнять."
	simple_message = "TARGET сжимается словно в объятьях."
	simple_style = "lewd"
	required_from_user = INTERACTION_REQUIRE_TK
	interaction_flags = NONE
	max_distance = TK_MAXRANGE
	massage_by_user = FALSE
	write_log_user = "TKhug"
	write_log_target = "TKhuged by"
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/TKheadpat
	description = "Телекинез. Погладить по голове."
	simple_message = "Голова TARGET поглаживается словно невидимой рукой."
	simple_style = "lewd"
	required_from_user = INTERACTION_REQUIRE_TK
	interaction_flags = NONE
	max_distance = TK_MAXRANGE
	massage_by_user = FALSE
	write_log_user = "TKheadpat"
	write_log_target = "TKheadpatted by"
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/TKhug/display_interaction(mob/living/user, mob/living/target)
	..()
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)

/datum/interaction/lewd/slap/TKslap
	description = "Телекинез. Шлёпнуть по заднице."
	simple_message = "по заду TARGET что-то приходится шлепком!"
	big_user_target_text = TRUE
	max_distance = TK_MAXRANGE
	massage_by_user = FALSE
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_RANGED_CONSENT
	required_from_user = INTERACTION_REQUIRE_TK
	write_log_user = "TK-ass-slapped"
	write_log_target = "was TK-ass-slapped by"

///////////////////////////////////
// база для эмоутов с телекинезом//
///////////////////////////////////

/datum/interaction/lewd/simplified_interaction/TK_interaction
	required_from_user = INTERACTION_REQUIRE_TK
	max_distance = TK_MAXRANGE
	massage_by_user = FALSE
	p13target_strength = PLUG13_STRENGTH_NORMAL
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_RANGED_CONSENT
	lewd_sounds = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/lewd/simplified_interaction/TK_interaction/tits
	description = "Телекинез. Схватить грудь."
	required_from_target_exposed = INTERACTION_REQUIRE_BREASTS
	required_from_target_unexposed = INTERACTION_REQUIRE_BREASTS
	target_organ = ORGAN_SLOT_BREASTS
	write_log_user = "TK groped"
	write_log_target = "was TK-groped by"
	p13target_emote = PLUG13_EMOTE_BREASTS
	start_text = "Что-то обхватывает грудь TARGET."
	help_text = "Что-то обводит и мягко сжимает грудь TARGET."
	grab_text = "Что-то крепко зажимает грудь TARGET."
	harm_text = "Что-то впивается до боли в грудь TARGET."

/datum/interaction/lewd/simplified_interaction/TK_interaction/ass
	description = "Телекинез. Схватить задницу."
	target_organ = ORGAN_SLOT_BUTT
	write_log_user = "TK-ass-groped"
	write_log_target = "was TK-ass-groped by"
	p13target_emote = PLUG13_EMOTE_ASS
	start_text = "Что-то обхватывает зад TARGET."
	help_text = "Что-то поочерёдно сжимает булки зада TARGET."
	grab_text = "Что-то крепко сжимает зад TARGET."
	harm_text = "Что-то впивается и растягивает булки TARGET."

/datum/interaction/lewd/simplified_interaction/TK_interaction/things
	description = "Телекинез. Схватить бёдра."
	require_target_legs = REQUIRE_ANY
	write_log_user = "TK-things-groped"
	write_log_target = "was TK-things-groped by"
	p13target_emote = PLUG13_EMOTE_BREASTS
	start_text = "Что-то обхватывает бёдра TARGET."
	help_text = "Что-то проходится и обжимает бёдра TARGET."
	grab_text = "Что-то крепко зажимает бёдра TARGET."
	harm_text = "Что-то впивается в бёдра TARGET, то и дело поочерёдно их сжимая."

/datum/interaction/lewd/simplified_interaction/TK_interaction/balls
	description = "Телекинез. Схватить яйца."
	required_from_target_exposed = INTERACTION_REQUIRE_BALLS
	required_from_target_unexposed = INTERACTION_REQUIRE_BALLS
	target_organ = ORGAN_SLOT_TESTICLES
	write_log_user = "TK-balls-groped"
	write_log_target = "was TK-balls-groped by"
	p13target_emote = PLUG13_EMOTE_GROIN
	start_text = "Что-то хватается за яйца TARGET."
	help_text = "Что-то перебирает яйцами TARGET в своей хватке."
	grab_text = "Что-то обхватывает и зажимает яйца TARGET."
	harm_text = "Что-то крайне сильно сжимает яйца TARGET."

/datum/interaction/lewd/simplified_interaction/TK_interaction/penis
	description = "Телекинез. Схватить член."
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	required_from_target_unexposed = INTERACTION_REQUIRE_PENIS
	target_organ = ORGAN_SLOT_PENIS
	write_log_user = "TK-penis-groped"
	write_log_target = "was TK-penis-groped by"
	p13target_emote = PLUG13_EMOTE_PENIS

/datum/interaction/lewd/simplified_interaction/TK_interaction/penisgrope/text_picker(mob/living/user, mob/living/partner)
	var/has_penis = partner.has_penis()
	start_text = "USER обхватывает хвостом собственный [has_penis ? "член" : "дилдо"]."
	start_text = "Что-то обхватывает [has_penis ? "член" : "дилдо"] TARGET."
	help_text = "Что-то проходится по [has_penis ? "член" : "дилдо"] TARGET, [has_penis ? "" : "безуспешно "]стараясь доставить удовольствие."
	grab_text = "Что-то бодро скользит по [has_penis ? "член" : "дилдо"] TARGET."
	harm_text = "Что-то излишне сильно обхватывает [has_penis ? "член" : "дилдо"] TARGET."

/datum/interaction/lewd/simplified_interaction/TK_interaction/vagina
	description = "Телекинез. Вжаться в киску."
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	required_from_target_unexposed = INTERACTION_REQUIRE_VAGINA
	target_organ = ORGAN_SLOT_VAGINA
	write_log_user = "TK-vagina-groped"
	write_log_target = "was TK-vagina-groped by"
	p13target_emote = PLUG13_EMOTE_PENIS
	start_text = "Что-то вжимается в киску TARGET."
	help_text = "Что-то проскальзывает по киску TARGET."
	grab_text = "Что-то проскальзывает и мучает лоно TARGET."
	harm_text = "Что-то вбивается и грубо тянет лоно TARGET."

#undef TK_MAXRANGE
