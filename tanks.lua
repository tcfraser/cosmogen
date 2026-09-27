-- Creates and draws tanks placed in the map.
-- Exposes connection-port and blocking-body lookups for movement.

function replace_tank(x,y)
    local sprite = mget(x,y)
    if sprite == 32 then -- tank bottom-left sprite
        init_tank(x,y)
    end
    if sprite == 16 or sprite == 17 or sprite == 32 or sprite == 33 then -- tank piece
        mset(x,y,default.asteroid)
    end
end

function init_tank(x,y)
    if tanks == nil then tanks = {} end
    add(tanks, {x=x, y=y, state="idle"})
end

function tank_connection_at(p)
    for tank in all(tanks) do
        if pos_equal(tank,p) then return tank end
    end
end

function tank_blocking_body_at(p)
    for tank in all(tanks) do
        local dx = p.x - tank.x
        local dy = p.y - tank.y
        if (dx == 0 or dx == 1) and dy == -1 then return true end
    end
    return false
end

function draw_tanks()
    for tank in all(tanks) do
        local p = pos_scale(pos(tank.x, tank.y-1),8)
        transparency(14)
        spr(16,p.x,p.y,2,2)
        transparency(0)
    end
end
