/obj/item/projectile/energy/tesla
	name = "tesla bolt"
	icon_state = "tesla_projectile"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	var/zap_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE
	var/zap_range = 3
	var/power = 10000

/obj/item/projectile/energy/tesla/fire(setAngle, atom/direct_target)
	var/atom/source = fired_from || firer
	if(source)
		chain = source.Beam(src, icon_state = "lightning[rand(1, 12)]", time = INFINITY, maxdistance = INFINITY)
	return ..()

/obj/item/projectile/energy/tesla/on_hit(atom/target)
	. = ..()
	tesla_zap(target, zap_range, power, zap_flags)
	qdel(src)

/obj/item/projectile/energy/tesla/Destroy()
	qdel(chain)
	return ..()

/obj/item/projectile/energy/tesla/revolver
	name = "energy orb"

/obj/item/projectile/energy/tesla/cannon
	name = "tesla orb"
	power = 20000

/obj/item/projectile/energy/tesla/sphere
	name = "tesla sphere"
	power = 100000
