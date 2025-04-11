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

update_animation :: proc(a: ^Animation) {
	a.frame_timer += rl.GetFrameTime()

	for a.frame_timer > a.frame_length {
		a.current_frame += 1
		a.frame_timer -= a.frame_length
		if a.current_frame == a.num_frames {
			a.current_frame = 0
		}
	}
}

draw_animation :: proc(a: Animation, pos: rl.Vector2, flip: bool) {
	width := f32(a.texture.width)
	height := f32(a.texture.height)

	// Define player sprite source
	source := rl.Rectangle {
		x      = f32(a.current_frame) * width / f32(a.num_frames),
		y      = 0,
		width  = width / f32(a.num_frames),
		height = height,
	}

	if flip {
		source.width = -source.width
	}

	// Define player position
	dest := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = width / f32(a.num_frames),
		height = height,
	}

	// Draw player
	rl.DrawTexturePro(a.texture, source, dest, {dest.width / 2, dest.height / 2}, 0, rl.WHITE)
}

PixelWindowHeight :: 180

main :: proc() {
	rl.InitWindow(1280, 720, "My First Game")
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)

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

		rl.ClearBackground(rl.SKYBLUE)
		update_animation(&current_anim)

		screen_height := f32(rl.GetScreenHeight())

		camera := rl.Camera2D {
			zoom   = screen_height / PixelWindowHeight,
			offset = {f32(rl.GetScreenWidth() / 2), screen_height / 2},
			target = player_pos,
		}

		rl.BeginMode2D(camera)
		draw_animation(current_anim, player_pos, player_flipped)
		rl.EndMode2D()
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
}
