function init_cable()
    anchors={{x=map.start.x,y=map.start.y}}
    crossings={}
    sync_critters()
end

function draw_cable_line(a,b)
    c1=6
    c2=7
    if a != nil and b != nil then
        -- oriented north, east, south, or west
        ax=a.x*8+3
        ay=a.y*8+3
        bx=b.x*8+3
        by=b.y*8+3
        if a.y > b.y then -- north
            line(ax  , ay, bx  , by, c1)
            line(ax+1, ay, bx+1, by, c2)
        elseif a.y < b.y then -- south
            line(ax+1, ay+1, bx+1, by+1, c1)
            line(ax  , ay+1, bx  , by+1, c2)
        elseif a.x < b.x then -- east 
            line(ax+1, ay  , bx+1, by  , c1)
            line(ax+1, ay+1, bx+1, by+1, c2)
        elseif a.x > b.x then -- west 
            line(ax, ay+1, bx, by+1, c1)
            line(ax, ay  , bx, by  , c2)
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
    add(anchors, p)
    local last = anchors[#anchors-1]
    -- validate_intersection_points
    if pos_dist(p, last) > 0 then
        -- new segment long enough for intersections
        local new_crossings = {}
        for i = 2, #anchors do
            local crossing_point = crossing(last, p, anchors[i-1], anchors[i])
            if crossing_point != nil then
                crossing_point.anchor_index = #anchors
                add(new_crossings, crossing_point)
            end
        end
        new_crossings = sort_by(new_crossings, function(q) return -pos_dist(q,p) end)
        local new_crossings_order = {}
        for j = 1, #new_crossings do
            add(crossings, new_crossings[j])
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
    local a = anchors[#anchors-1]
    local b = anchors[#anchors]
    local diff = pos(b.x-a.x,b.y-a.y)
    local dir = pos_dir(diff)
    return dir 
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
    local count = motion and motion.index-1 or #anchors
    for i=2,count do
        draw_cable_line(anchors[i-1],anchors[i])
    end
    if motion then
        draw_cable_line(motion.a,player_display_pos())
    end
    -- crossings now
    local over_crossing = false
    local sprite_offset = 0
    local visible = motion and motion.crossings or crossings
    for i = 1, #visible do
        local c = visible[i]
        if c.is_vertical and over_crossing or not c.is_vertical and not over_crossing then
            sprite_offset = 1
        else
            sprite_offset = 0
        end
        over_crossing = not over_crossing
        if not motion or c.anchor_index < motion.index or
            pos_dist(motion.a,c) <= pos_dist(motion.a,player_display_pos()) then
            local p = pos_scale(c,8)
            spr(16 + sprite_offset,p.x,p.y,1,1,c.flip_x,c.flip_y)
        end
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

