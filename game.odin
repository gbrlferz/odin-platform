package game

import rl "vendor:raylib"

player_pos := rl.Vector2{640, 320}
player_vel: rl.Vector2
player_grounded: bool
player_flipped := false
player_scale: f32 = 4

current_anim: Animation
player_run: Animation
player_idle: Animation

player_run_width: f32
player_run_height: f32

Animation :: struct {
	texture:       rl.Texture2D,
	num_frames:    i32,
	frame_timer:   f32,
	current_frame: i32,
	frame_length:  f32,
	name:          Animation_Name,
}

Animation_Name :: enum {
	Idle,
	Run,
}

main :: proc() {
	rl.InitWindow(1280, 720, "My First Game")

	player_run = {
		texture      = rl.LoadTexture("cat_run.png"),
		num_frames   = 4,
		frame_length = 0.1,
		name         = .Run,
	}

	player_idle = {
		texture      = rl.LoadTexture("cat_idle.png"),
		num_frames   = 2,
		frame_length = 0.5,
		name         = .Idle,
	}

	current_anim = player_idle


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

		if current_anim.name != .Run {
			current_anim = player_run
		}
	} else if rl.IsKeyDown(.RIGHT) {
		player_vel.x = 400
		player_flipped = false

		if current_anim.name != .Run {
			current_anim = player_run
		}
	} else {
		player_vel.x = 0

		if current_anim.name != .Idle {
			current_anim = player_idle
		}
	}

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
	player_run_width = f32(current_anim.texture.width)
	player_run_height = f32(current_anim.texture.height)

	current_anim.frame_timer += rl.GetFrameTime()

	for current_anim.frame_timer > current_anim.frame_length {
		current_anim.current_frame += 1
		current_anim.frame_timer -= current_anim.frame_length
		if current_anim.current_frame == current_anim.num_frames {
			current_anim.current_frame = 0
		}
	}

	// Define player sprite source
	draw_player_source := rl.Rectangle {
		x      = f32(current_anim.current_frame) * player_run_width / f32(current_anim.num_frames),
		y      = 0,
		width  = player_run_width / f32(current_anim.num_frames),
		height = player_run_height,
	}

	if player_flipped {
		draw_player_source.width = -draw_player_source.width
	}

	// Define player position
	draw_player_dest := rl.Rectangle {
		x      = player_pos.x,
		y      = player_pos.y,
		width  = player_run_width * player_scale / f32(current_anim.num_frames),
		height = player_run_height * player_scale,
	}

	// Draw player
	rl.DrawTexturePro(current_anim.texture, draw_player_source, draw_player_dest, 0, 0, rl.WHITE)
}
