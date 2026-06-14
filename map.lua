function init_map()
    map = {
        width=128, height=64,
        asteroid_sprites={
            --      NESW
            126, -- 0000
             95, -- 0001
             79, -- 0010
             78, -- 0011
            111, -- 0100
            125, -- 0101
             76, -- 0110
             77, -- 0111
            127, -- 1000
            110, -- 1001
            124, -- 1010
             94, -- 1011
            108, -- 1100
            109, -- 1101
             92, -- 1110
             93, -- 1111
         }
    }

    for x = 0,map.width-1 do
        for y = 0,map.height-1 do
            init_map_at(x,y)
        end
    end
end


function is_asteroid(x,y)
    x = wrap(x, 0, map.width-1)
    y = wrap(y, 0, map.height-1)
    return fget(mget(x,y),1)
end

function init_map_at(x,y)
    if is_asteroid(x,y) then
        local sprite_index = 1
        if is_asteroid(x,y-1) then sprite_index += (1 << 3) end -- north
        if is_asteroid(x+1,y) then sprite_index += (1 << 2) end -- east
        if is_asteroid(x,y+1) then sprite_index += (1 << 1) end -- south
        if is_asteroid(x-1,y) then sprite_index += (1 << 0) end -- west
        mset(x,y,map.asteroid_sprites[sprite_index])
    end
end
