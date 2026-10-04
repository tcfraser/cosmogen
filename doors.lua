-- Doors own the arrow indices for their 16x16 room.
function replace_doors(x,y)
    if mget(x,y) != 102 then return end
    if doors == nil then doors = {} end

    local door = {x=x,y=y,open=false,arrows={}}
    for i=1,#(arrows or {}) do
        local p = arrows[i].inp
        if flr(p.x/16) == flr(x/16) and flr(p.y/16) == flr(y/16) then
            add(door.arrows,i)
        end
    end
    add(doors,door)
    mset(x,y,default.asteroid)
end

function sync_doors()
    for door in all(doors) do
        door.open = true
        for i in all(door.arrows) do
            if arrows[i].collected_at < 0 then
                door.open = false
                break
            end
        end
    end
end

function door_blocking_at(p)
    for door in all(doors) do
        if not door.open and pos_equal(door,p) then return true end
    end
    return false
end

function draw_doors()
    transparency(14)
    for door in all(doors) do
        if not door.open then spr(102,door.x*8,door.y*8) end
    end
    transparency(0)
end
