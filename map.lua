function init_map()
    default={asteroid=93,space=0}
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
    wall_sprites={}
    for i = 1,#asteroid_sprites do
        wall_sprites[i] = asteroid_sprites[i]-4
    end
    map = {
        width=128, height=64,
        start=pos(0,0),
    }
    apply_at_map(replace_astronaut)
    apply_at_map(replace_critters)
    apply_at_map(replace_arrows)
    apply_at_map(edge_asteroid)
    apply_at_map(edge_wall)
end

function apply_at_map(f)
    for x = 0,map.width-1 do
        for y = 0,map.height-1 do
            f(x,y)
        end
    end
end


function mget_wrapped(x,y)
    x = wrap(x, 0, map.width-1)
    y = wrap(y, 0, map.height-1)
    return mget(x,y)
end

function is_asteroid(x,y)
    return fget(mget_wrapped(x,y),1)
end

function is_wall(x,y)
    return fget(mget_wrapped(x,y),2)
end

function is_asteroid_connector(x,y)
    return is_asteroid(x,y) or is_wall(x,y) 
end

function edge_asteroid(x,y)
    if is_asteroid(x,y) then
        local sprite_index = 1
        if is_asteroid_connector(x,y-1) then sprite_index += (1 << 3) end -- north
        if is_asteroid_connector(x+1,y) then sprite_index += (1 << 2) end -- east
        if is_asteroid_connector(x,y+1) then sprite_index += (1 << 1) end -- south
        if is_asteroid_connector(x-1,y) then sprite_index += (1 << 0) end -- west
        mset(x,y,asteroid_sprites[sprite_index])
    end
end

function edge_wall(x,y)
    if is_wall(x,y) then
        local sprite_index = 1
        if is_wall(x,y-1) then sprite_index += (1 << 3) end -- north
        if is_wall(x+1,y) then sprite_index += (1 << 2) end -- east
        if is_wall(x,y+1) then sprite_index += (1 << 1) end -- south
        if is_wall(x-1,y) then sprite_index += (1 << 0) end -- west
        mset(x,y,wall_sprites[sprite_index])
    end
end

function draw_map()
    -- need to determine which region of map should be drawn
    -- based on screen position
    for tx = -1,16 do
        for ty = -1,16 do
            mx = flr(screen.interp.x) + tx
            my = flr(screen.interp.y) + ty
            spr(mget_wrapped(mx,my), mx*8, my*8)
        end
    end
end

