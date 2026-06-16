function _init()
    clock=0
    pal_alt()
    init_map()
    -- init player
    anchors={{x=map.start.x,y=map.start.y}}
    crossings={}
end

function _update60()
    clock += 1 
    if clock == 60 then clock = 0 end

    delta = pos(0,0)
    if btnp(0) then delta.x -= 1 end
    if btnp(1) then delta.x += 1 end
    if btnp(2) then delta.y -= 1 end
    if btnp(3) then delta.y += 1 end

    try_apply_delta(pos(0,delta.y)) -- resolve vertical first
    try_apply_delta(pos(delta.x,0)) -- resolve horizontal second

    if btnp(5) then
        -- undo
        pop_from_path()
    end
end

function try_apply_delta(delta)
    if pos_zero(delta) then return false end

    last_delta = delta -- stored for drawing astronaut

    candidate = anchors[#anchors]

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
    end
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

function update_screen_context()
    screen = pos_scale(anchors[#anchors], 1/16)
    screen.x = flr(screen.x)
    screen.y = flr(screen.y)
    screen = pos_scale(screen, 16)
    neercs = pos_scale(screen, -1)
end

function _draw()
    cls()
    update_screen_context()
    for x = 0,15 do
        for y = 0,15 do
            spr(mget(x+screen.x,y + screen.y), x*8, y*8)
        end
    end
    if #anchors>0 then
        for i=1,#anchors do
            --for i=1,#anchors do
            --    spr(2,anchors[i].x*8, anchors[i].y*8)
            --end
            -- if is_anchor_corner(anchors[i]) then
            --     spr(5,anchors[i].x*8, anchors[i].y*8)
            -- end
            if i>1 then
                draw_oriented_line(pos_add(anchors[i-1],neercs),pos_add(anchors[i],neercs))
            end
        end
    end
    local over_crossing = false
    local sprite_offset = 0
    for i = 1, #crossings do
        if crossings[i].is_vertical and over_crossing or not crossings[i].is_vertical and not over_crossing then
            sprite_offset = 1
        else
            sprite_offset = 0
        end
        over_crossing = not over_crossing
        local crossing_screen_pos = pos_scale(pos_add(crossings[i],neercs), 8)
        spr(16 + sprite_offset, crossing_screen_pos.x, crossing_screen_pos.y, 1, 1, crossings[i].flip_x, crossings[i].flip_y)
    end
    draw_astronaut()
    draw_debug()
end

function draw_astronaut()
    local p = pos_scale(pos_add(anchors[#anchors],neercs),8)
    local sprite = 12
    local flip_x = false
    if last_delta != nil then
        if last_delta.x != 0 then
            sprite = 28
            if last_delta.x < 0 then
                flip_x = true
            end
        end
        if last_delta.y < 0 then
            sprite=44
        end
    end
    spr(sprite, p.x, p.y, 1,1, flip_x,false)

    -- black eyes
    palt(0,false)
    local sp = sprite_index_to_pos(sprite)
    local ox,oy = 1,3
    local dw,dh = 6,3
    sspr(sp.x+ox,sp.y+oy,dw,dh,p.x+ox,p.y+oy,dw,dh,flip_x,false)
    palt(0,true)
end

function sprite_index_to_pos(index)
    return pos((index % 16) * 8, (index \ 16) * 8)
end

function draw_oriented_line(a,b)
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


