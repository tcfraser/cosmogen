-- Reads the astronaut's spawn marker and draws the player.
-- Uses the animated position and latest movement direction for the sprite.

local num_blink_frames=10
local blink_chance=0.2
local blink_frames=0

function replace_astronaut(x,y)
    if mget(x,y) == 12 then -- astronaut sprite
        map.start = pos(x,y)
        mset(x,y,default.asteroid)
    end
end

function update_astronaut()
    blink_frames=max(0,blink_frames-1)
    if clock==0 and rnd()<blink_chance then
        blink_frames=num_blink_frames
    end
end

function draw_astronaut()
    local p = pos_scale(player_display_pos(), 8)
    local sprite = 12
    local flip_x = false
    local lda = last_delta_attempt
    if is_overlay_active() then
        sprite=13
    elseif lda ~= nil then
        if lda.x ~= 0 then
            sprite = 28
            if lda.x < 0 then
                flip_x = true
            end
        end
        if lda.y < 0 then
            sprite=44
        end
    end
    pal(0,blink_frames>0 and 9 or 0)
    transparency(14)
    spr(sprite, p.x, p.y, 1,1, flip_x,false)
    pal(0,0)
    transparency(0)
end
