-- Room-local planning: z toggles, arrows move, x+arrows toggle edges.
local overlay

function init_overlay()
    overlay={active=false,toggle=false,release=false,rooms={}}
end

function is_overlay_active()
    return overlay.active
end

function overlay_room()
    local p=last_anchor()
    local key=flr(p.x/16)..","..flr(p.y/16)
    if not overlay.rooms[key] then
        overlay.rooms[key]={cursor=pos(3,3),edges={}}
    end
    return overlay.rooms[key]
end

-- Return true while planning owns the controls.
function update_overlay()
    local toggle=btn(4)
    if toggle and not overlay.toggle then
        overlay.active=not overlay.active
        overlay.release=true
    end
    overlay.toggle=toggle
    if not overlay.active then
        -- Closing must not turn held drawing inputs into moves or undos.
        if overlay.release then
            overlay.release=btn()!=0
            return true
        end
        return false
    end
    -- Let an already accepted move and camera transition settle first.
    if motion or screen.timer>0 then return true end
    local room=overlay_room()
    local p,d=room.cursor,movement_delta()
    local q=pos(mid(0,p.x+d.x,15),mid(0,p.y+d.y,15))
    if btn(5) and not pos_equal(p,q) then
        -- Two slots per cell: right and down. Reverse travel uses the same key.
        local edge=min(p.x+p.y*16,q.x+q.y*16)*2
        if p.y!=q.y then edge+=1 end
        room.edges[edge]=not room.edges[edge] or nil
    end
    room.cursor=q
    return true
end

function draw_overlay()
    if not overlay.active or motion or screen.timer>0 then return end
    local room=overlay_room()
    for edge in pairs(room.edges) do
        local cell=flr(edge/2)
        local x,y=cell%16*8+4,flr(cell/16)*8+4
        local dx,dy=8,0
        if edge%2==1 then dx,dy=0,8 end
        line(x,y,x+dx,y+dy,10)
    end
    transparency(14)
    spr(1,room.cursor.x*8,room.cursor.y*8)
    transparency(0)
    rect(0,0,127,127,10)
    local hint="\151 hold to draw"
    print(hint,4,4,0)
    print(hint,3,3,7)
    hint="\142 close"
    local x=125-print(hint,0,-8,7)
    print(hint,x+1,4,0)
    print(hint,x,3,7)
end
