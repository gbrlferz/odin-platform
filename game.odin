#+feature dynamic-literals
package game

import fmt "core:fmt"
import "core:mem"
import rl "vendor:raylib"

player_pos := rl.Vector2{0, 0}
player_vel: rl.Vector2
player_grounded: bool
player_flipped := false
player_scale: f32 = 4
player_feet_collider: rl.Rectangle

level := Level {
	platforms = {{-20, 20}, {90, -10}, {90, -50}},
}

platform_texture: rl.Texture2D

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
	rl.DrawTexturePro(a.texture, source, dest, {dest.width / 2, dest.height}, 0, rl.WHITE)
}

PixelWindowHeight :: 180

Level :: struct {
	platforms: [dynamic]rl.Vector2,
}

platform_collider :: proc(pos: rl.Vector2) -> rl.Rectangle {
	return {pos.x, pos.y, 96, 16}
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, entry in track.allocation_map {
			fmt.eprintf("%v leaked ^% bytes\n", entry.location, entry.size)
		}
		for entry in track.bad_free_array {
			fmt.eprintf("%v bad tree\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track)
	}

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

	platform_texture = rl.LoadTexture("platform.png")

	current_anim = player_idle

	editing := false

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
		for platform in level.platforms {
			rl.DrawTextureV(platform_texture, platform, rl.WHITE)
		}
		// rl.DrawRectangleRec(player_feet_collider, {0, 255, 0, 100})

		if rl.IsKeyPressed(.F2) {
			editing = !editing
		}

		if editing {
			mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

			rl.DrawTextureV(platform_texture, mp, rl.WHITE)

			if rl.IsMouseButtonPressed(.LEFT) {
				append(&level.platforms, mp)
			}

			if rl.IsMouseButtonPressed(.RIGHT) {
				for p, idx in level.platforms {
					if rl.CheckCollisionPointRec(mp, platform_collider(p)) {
						unordered_remove(&level.platforms, idx)
					}
				}
			}
		}

		rl.EndMode2D()
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

player_movement :: proc() {
	if rl.IsKeyDown(.LEFT) {
		player_vel.x = -150
		player_flipped = true

		if current_anim.name != .Run {
			current_anim = player_run
		}
	} else if rl.IsKeyDown(.RIGHT) {
		player_vel.x = 150
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
	player_vel.y += 1000 * rl.GetFrameTime()

	// Allow jumping
	if player_grounded && rl.IsKeyPressed(.SPACE) {
		player_vel.y = -220
	}

	// Apply velocity
	player_pos += player_vel * rl.GetFrameTime()

	player_feet_collider = rl.Rectangle{player_pos.x - 4, player_pos.y - 4, 8, 4}

	player_grounded = false

	for platform in level.platforms {
		if rl.CheckCollisionRecs(player_feet_collider, platform_collider(platform)) &&
		   player_vel.y > 0 {
			player_vel.y = 0
			player_pos.y = platform.y
			player_grounded = true
		}
	}
}
