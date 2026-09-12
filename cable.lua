function init_cable()
    anchors={{x=map.start.x,y=map.start.y,end_phase=0}}
    crossings={}
    oxygen_phase=0
    oxygen_band=16 -- oxygen length in pixels
    oxygen_gap=32 -- empty length in pixels
    oxygen_speed=1 -- pixels per frame; keeps flowing during undo
    sync_critters()
end

-- Each destination anchor owns immutable geometry for its incoming segment.
-- Phase is stored modulo wavelength to avoid large cumulative pixel totals.
function cache_segment(a,b)
    local dir=pos_dir(pos_subtract(b,a))
    b.dx,b.dy=dir.x,dir.y
    b.length=pos_dist(a,b)*8
    b.gaps={}
    b.phase=a.end_phase
    b.end_phase=(b.phase+b.length)%(oxygen_band+oxygen_gap)
    b.sx,b.sy=a.x*8+3,a.y*8+3
    -- first strand origin and second strand offset, preserving shading
    b.ox,b.oy=0,0
    if b.dy < 0 then b.ox=1
    elseif b.dy > 0 then
        b.sx+=1 b.sy+=1 b.ox=-1
    elseif b.dx > 0 then
        b.sx+=1 b.oy=1
    else
        b.sy+=1 b.oy=-1
    end
end

function draw_cable_span(p,first,last,c1,c2)
    local ax,ay=p.sx+p.dx*first,p.sy+p.dy*first
    local bx,by=p.sx+p.dx*last,p.sy+p.dy*last
    line(ax,ay,bx,by,c1)
    line(ax+p.ox,ay+p.oy,bx+p.ox,by+p.oy,c2)
end

-- Draw a visible interval without restarting the oxygen phase.
function draw_cable_interval(p,lo,hi)
    if lo > hi then return end
    draw_cable_span(p,lo,hi,6,7)
    local wavelength=oxygen_band+oxygen_gap
    local first=lo+(oxygen_phase-p.phase-lo)%wavelength
    if first-lo > oxygen_gap then first-=wavelength end
    while first <= hi do
        local last=min(flr(hi),ceil(first+oxygen_band)-1)
        local start=max(lo,ceil(first))
        if start <= last then draw_cable_span(p,start,last,1,12) end
        first+=wavelength
    end
end

function draw_cable_segment(p,length,extent,cx,cy)
    if length <= 0 then return end
    -- Test both strands against this frame's camera before processing gaps
    -- or oxygen. Bounds also catch segments with both anchors offscreen.
    local bx,by=p.sx+p.dx*length,p.sy+p.dy*length
    if max(p.sx,bx)+max(0,p.ox) < cx-1 or
        min(p.sx,bx)+min(0,p.ox) > cx+128 or
        max(p.sy,by)+max(0,p.oy) < cy-1 or
        min(p.sy,by)+min(0,p.oy) > cy+128 then return end
    local first=0
    for c in all(p.gaps) do
        -- A crossing only exists visually once the moving tip reaches it.
        if not motion or c.anchor_index != motion.index or c.distance <= extent then
            draw_cable_interval(p,first,min(length,c.gap_start-1))
            first=max(first,c.gap_end+1)
            if first > length then return end
        end
    end
    draw_cable_interval(p,first,length)
end

function cache_crossing(c,p,old)
    -- The first new crossing goes under, then over, matching the sprites.
    c.under=(#crossings%2 == 0) and p or old
    local u=c.under
    local d=(c.x*8+3-u.sx)*u.dx+(c.y*8+3-u.sy)*u.dy
    -- Two pixels of upper cable, plus one pixel of clearance on each side.
    c.gap_start=min(d,d+u.dx+u.dy)-1
    c.gap_end=c.gap_start+3
    add(u.gaps,c)
    u.gaps=sort_by(u.gaps,function(g) return g.gap_start end)
end

-- Retracting gaps are visual state; discard them when undo finishes.
function clear_motion_gaps()
    if motion.dir < 0 then
        for c in all(motion.crossings) do
            if c.anchor_index == motion.index then del(c.under.gaps,c) end
        end
    end
end

function crossing(a1,a2,b1,b2)
    if a1.x == a2.x and b1.y == b2.y then
        if (a1.x - b1.x) * (a1.x - b2.x) < 0 and (b1.y - a1.y) * (b1.y - a2.y) < 0 then
            return {x=a1.x, y=b1.y, flip_x=(a1.y<a2.y), flip_y=(b1.x<b2.x), is_vertical=true}
        end
    end
    if a1.y == a2.y and b1.x == b2.x then
        if (a1.y - b1.y) * (a1.y - b2.y) < 0 and (b1.x - a1.x) * (b1.x - a2.x) < 0 then
            return {x=b1.x, y=a1.y, flip_x=(b1.y<b2.y), flip_y=(a1.x<a2.x), is_vertical=false}
        end
    end
    return nil
end

function append_to_path(p)
    cache_segment(last_anchor(),p)
    add(anchors, p)
    local last = anchors[#anchors-1]
    -- validate_intersection_points
    if pos_dist(p, last) > 0 then
        -- new segment long enough for intersections
        local new_crossings = {}
        for i = 2, #anchors do
            local crossing_point = crossing(last, p, anchors[i-1], anchors[i])
            if crossing_point != nil then
                crossing_point.old = anchors[i]
                crossing_point.anchor_index = #anchors
                crossing_point.distance = pos_dist(last,crossing_point)*8
                add(new_crossings, crossing_point)
            end
        end
        new_crossings = sort_by(new_crossings, function(q) return -pos_dist(q,p) end)
        for j = 1, #new_crossings do
            local c=new_crossings[j]
            cache_crossing(c,p,c.old)
            c.old=nil
            add(crossings,c)
        end
    end
    sync_critters()
end

function pop_from_path()
    if #anchors > 1 then
        deli(anchors, #anchors)
        -- trimming crossing list
        local count_crossings = #crossings
        for i = 1, count_crossings do
            local j = count_crossings-i+1
            if crossings[j].anchor_index > #anchors then
                local c=crossings[j]
                if not motion or motion.dir > 0 then del(c.under.gaps,c) end
                deli(crossings, j)
            end
        end
        sync_critters()
    end
end

function last_anchor()
    return anchors[#anchors]
end

function last_move_delta()
    if #anchors<2 then return nil end
    local p=last_anchor()
    return pos(p.dx,p.dy)
end

function attempt_move(delta)
    if pos_zero(delta) then return false end

    candidate = last_anchor()

    --check forward this much
    range = 32
    for s = 1, range do
        candidate = pos_add(candidate, delta)
        -- if is_anchor_corner(candidate) then
        --     return false
        -- end
        if is_blocked(candidate) then
            return false
        end
        if is_stable_ground(candidate) and not has_no_anchor(candidate) then
            return false
        end
        if has_no_anchor(candidate) and is_stable_ground(candidate) then
            append_to_path(candidate)
            return true
        end
    end
    return false
end

function has_no_anchor(p)
    free = true 
    for p in all(anchors) do
        if pos_equal(p, candidate) then 
            free = false 
            break
        end
    end
    return free 
end

function is_stable_ground(p)
    return fget(mget(p.x,p.y),1)
end

function is_blocked(p)
    return fget(mget(p.x,p.y),2)
end

function draw_cable()
    -- Match _draw's rounded camera; visibility is never cached on anchors.
    local cx,cy=round(screen.interp.x*8),round(screen.interp.y*8)
    local count = motion and motion.index-1 or #anchors
    local extent=0
    if motion then extent=pos_dist(motion.a,player_display_pos())*8 end
    for i=2,count do
        local p=anchors[i]
        draw_cable_segment(p,p.length,extent,cx,cy)
    end
    if motion then
        -- motion.b keeps the removed anchor and its gaps alive during undo
        draw_cable_segment(motion.b,extent,extent,cx,cy)
    end
end
--function is_anchor_corner(p)
--    if #anchors <= 2 then return false end
--    for i=2,#anchors-1 do
--        if pos_equal(p, anchors[i]) then
--            if (p.x != anchors[i-1].x) and (p.y != anchors[i+1].y) then
--                return true
--            end
--            if (p.y != anchors[i-1].y) and (p.x != anchors[i+1].x) then
--                return true
--            end
--        end
--    end
--    return false 
--end
