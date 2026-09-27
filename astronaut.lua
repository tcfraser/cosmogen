-- Reads the astronaut's spawn marker and draws the player.
-- Uses the animated position and latest movement direction for the sprite.

function replace_astronaut(x,y)
    if mget(x,y) == 12 then -- astronaut sprite
        map.start = pos(x,y)
        mset(x,y,default.asteroid)
    end
end


function draw_astronaut()
    local p = pos_scale(player_display_pos(), 8)
    local sprite = 12
    local flip_x = false
    local lda = last_delta_attempt
    if lda ~= nil then
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
    transparency(14)
    spr(sprite, p.x, p.y, 1,1, flip_x,false)
    transparency(0)
end
