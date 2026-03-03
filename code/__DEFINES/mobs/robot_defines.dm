// Hats
#define HAT_STAND_OFFSET "hat_offset_stand"
#define HAT_REST_OFFSET "hat_offset_rest"
#define HAT_BELLYUP_OFFSET "hat_offset_bellyup"
#define HAT_SIT_OFFSET "hat_offset_sit"

#define HAT_NO_RENDER "hat_no_render"

#define NORMAL_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, -3), "south" = list(0, -3), "east" = list(4, -3), "west" = list(-4, -3)))

#define TALL_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, 15), "south" = list(0, 15), "east" = list(2, 15), "west" = list(-2, 15)), \
	HAT_REST_OFFSET = alist("north" = list(0, 1), "south" = list(0, 1), "east" = list(2, 1), "west" = list(-2, 1)), \
	HAT_SIT_OFFSET = alist("north" = list(3, 1), "south" = list(3, 1), "east" = list(3, 1), "west" = list(3, 1)), \
	HAT_BELLYUP_OFFSET = alist("north" = list(0, 1), "south" = list(0, 1), "east" = list(2, 1), "west" = list(-2, 1)))

#define VALE_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, 3), "south" = list(16, 3), "east" = list(28, 3), "west" = list(4, 3)), \
	HAT_REST_OFFSET = alist("north" = list(16, -3), "south" = list(16, -3), "east" = list(28, -7), "west" = list(4, -7)), \
	HAT_SIT_OFFSET = alist("north" = list(16, 3), "south" = list(16, 3), "east" = list(28, 3), "west" = list(4, 3)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)
