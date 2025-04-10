package game

import rl "vendor:raylib"

player_pos := rl.Vector2{640, 320}
player_vel: rl.Vector2
player_grounded: bool
player_scale: f32 = 4
player_run_num_frames := 4
player_run_texture: rl.Texture2D
player_run_width: f32
player_run_height: f32

main :: proc() {
	rl.InitWindow(1280, 720, "My First Game")

	player_run_texture = rl.LoadTexture("cat_run.png")
	player_run_width = f32(player_run_texture.width)
	player_run_height = f32(player_run_texture.height)

	for !rl.WindowShouldClose() {
		player_movement()

		rl.BeginDrawing()

		player_animation()

		rl.ClearBackground(rl.BLUE)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

player_movement :: proc() {
	if rl.IsKeyDown(.LEFT) {
		player_vel.x = -400
	} else if rl.IsKeyDown(.RIGHT) {
		player_vel.x = 400
	} else {player_vel.x = 0}

	// Gravity
	player_vel.y += 2000 * rl.GetFrameTime()

	// Allow jumping
	if player_grounded && rl.IsKeyPressed(.SPACE) {
		player_vel.y = -600
		player_grounded = false
	}

	// Apply velocity
	player_pos += player_vel * rl.GetFrameTime()

	// Clamp position
	if player_pos.y >
	   f32(rl.GetScreenHeight()) - f32(player_run_texture.height * i32(player_scale)) {
		player_pos.y =
			f32(rl.GetScreenHeight()) - f32(player_run_texture.height * i32(player_scale))
		player_grounded = true
	}
}

player_animation :: proc() {
	// Define player sprite source
	draw_player_source := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = player_run_width / f32(player_run_num_frames),
		height = player_run_height,
	}

	// Define player position
	draw_player_dest := rl.Rectangle {
		x      = player_pos.x,
		y      = player_pos.y,
		width  = player_run_width * player_scale / f32(player_run_num_frames),
		height = player_run_height * player_scale,
	}

	// Draw player
	rl.DrawTexturePro(player_run_texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)
}
