package game

import rl "vendor:raylib"

player_pos := rl.Vector2{640, 320}
player_vel: rl.Vector2
player_grounded: bool
player_flipped := false
player_scale: f32 = 4
player_run: Animation

player_run_width: f32
player_run_height: f32

Animation :: struct {
	texture:       rl.Texture2D,
	num_frames:    i32,
	frame_timer:   f32,
	current_frame: i32,
	frame_length:  f32,
}

main :: proc() {
	rl.InitWindow(1280, 720, "My First Game")

	player_run = {
		texture      = rl.LoadTexture("cat_run.png"),
		num_frames   = 4,
		frame_length = 0.1,
	}

	player_run_width = f32(player_run.texture.width)
	player_run_height = f32(player_run.texture.height)

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
		player_flipped = true
	} else if rl.IsKeyDown(.RIGHT) {
		player_vel.x = 400
		player_flipped = false
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
	   f32(rl.GetScreenHeight()) - f32(player_run.texture.height * i32(player_scale)) {
		player_pos.y =
			f32(rl.GetScreenHeight()) - f32(player_run.texture.height * i32(player_scale))
		player_grounded = true
	}
}

player_animation :: proc() {
	player_run.frame_timer += rl.GetFrameTime()

	for player_run.frame_timer > player_run.frame_length {
		player_run.current_frame += 1
		player_run.frame_timer -= player_run.frame_length
		if player_run.current_frame == player_run.num_frames {
			player_run.current_frame = 0
		}
	}

	// Define player sprite source
	draw_player_source := rl.Rectangle {
		x      = f32(player_run.current_frame) * player_run_width / f32(player_run.num_frames),
		y      = 0,
		width  = player_run_width / f32(player_run.num_frames),
		height = player_run_height,
	}

	if player_flipped {
		draw_player_source.width = -draw_player_source.width
	}

	// Define player position
	draw_player_dest := rl.Rectangle {
		x      = player_pos.x,
		y      = player_pos.y,
		width  = player_run_width * player_scale / f32(player_run.num_frames),
		height = player_run_height * player_scale,
	}

	// Draw player
	rl.DrawTexturePro(player_run.texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)
}
