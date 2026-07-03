// Чипсы MacNachos
/obj/item/reagent_containers/food/snacks/chips/macnachos
	name = "MacNachos Diablo"
	desc = "Лис на упаковке словно говорит вам “Это, черт возьми, остро!”"
	icon_state = "chips"
	trash = /obj/item/trash/chips
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/capsaicin = 3)
	filling_color = "#ff5100"
	tastes = list("hot" = 1, "crisps" = 1)
	custom_price = PRICE_CHEAP

// Вульпиксы (чебупели)
/obj/item/reagent_containers/food/snacks/donkpocket/vulpix
	name = "\improper MacVulpix Original Taste"
	desc = "Пластиковый контейнер доверху наполненный вкуснейшими и ароматными мясными шариками с кетчупом."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_classic_open"
	list_reagents = list(/datum/reagent/consumable/nutriment = 5)
	cooked_type = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/warm
	filling_color = "#CD853F"
	tastes = list("meat" = 2, "dough" = 2, "laziness" = 1)
	foodtype = GRAIN | JUNKFOOD | MEAT

/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/warm
	icon_state = "vulpix_classic_warm"
	cooked_type = null
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/medicine/omnizine = 3)

//Сырные вульпиксы
/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese
	name = "\improper MacVulpix Triple-Cheese"
	desc = "Пластиковый контейнер доверху наполненный вкуснейшими и ароматными мясными шариками с сырным соусом."
	icon_state = "vulpix_cheese_open"
	cooked_type = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese/warm
	foodtype = GRAIN | JUNKFOOD | MEAT | DAIRY

/obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese/warm
	icon_state = "vulpix_cheese_warm"
	cooked_type = null
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/medicine/omnizine = 3)

//Упаковка с вульпиксами
/obj/item/small_delivery/donk_vulpix
	name = "MacVulpix Original Taste"
	desc = "Классический вкус вульпиксов, проверенный временем, в удобной порционной упаковке."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_classic"
	var/init_packed_item = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix

/obj/item/small_delivery/donk_vulpix/cheese
	name = "MacVulpix Triple-Cheese"
	desc = "Классические вульпиксы - теперь с тройной сырной добавкой!"
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "vulpix_cheese"
	init_packed_item = /obj/item/reagent_containers/food/snacks/donkpocket/vulpix/cheese

/obj/item/small_delivery/donk_vulpix/Initialize(mapload)
	. = ..()
	var/obj/item/I = new init_packed_item(get_turf(loc))
	I.forceMove(src)
