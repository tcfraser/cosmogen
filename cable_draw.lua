-- Draws the cable and animates travel, oxygen flow, and tank retraction.
-- Caches crossings only for active or animating cables; anchors stay positions.

local cable_cache,cable_retraction
local cable_segment={} -- reusable geometry, never stored in history

-- Drawing hierarchy: cable -> path -> segment -> interval -> span.

-- Draw the retired cable during retraction, then the current cable and tip.
function draw_cable()
    if cable_retraction then
        draw_cable_path(cable_retraction.cache,cable_retraction)
    end
    if motion and motion.cache != cable_cache then
        draw_cable_path(motion.cache)
    end
    draw_cable_path(cable_cache)
end

-- Walk one tank's path, deriving oxygen phase even for offscreen segments.
-- Retraction clips from the source; motion clips the final segment at the tip.
function draw_cable_path(cache,r)
    local cx,cy=round(screen.interp.x*8),round(screen.interp.y*8)
    local first=cache.first
    local phase,lo=0,0
    local wavelength=oxygen_band+oxygen_gap
    local extent=0
    if motion and motion.cache == cache then
        extent=pos_dist(motion.a,player_display_pos())*8
    end
    if r then
        local remaining=r.distance
        while first < cache.last do
            local length=pos_dist(anchors[first],anchors[first+1])
            if remaining < length then break end
            remaining-=length
            phase=(phase+length*8)%wavelength
            first+=1
        end
        lo=remaining*8
        r.index,r.offset=first+1,lo
    end
    for i=first+1,cache.last do
        local tip=motion and motion.cache == cache and motion.index == i
        local b=tip and motion.b or anchors[i]
        local p=cable_geometry(anchors[i-1],b)
        p.phase=phase
        phase=(phase+p.length)%wavelength
        if tip then p.length=extent end
        draw_cable_segment(p,cache,i,extent,cx,cy,lo,r)
        lo=0
    end
end

-- A segment is the straight cable between two positions.
-- Cull it offscreen and draw visible intervals between crossing gaps.
function draw_cable_segment(p,cache,index,extent,cx,cy,lo,r)
    local first,length=lo,p.length
    if length <= 0 or first > length then return end
    -- Test both strands against this frame's camera before processing gaps
    -- or oxygen. Bounds also catch segments with both anchors offscreen.
    local ax,ay=p.sx+p.dx*first,p.sy+p.dy*first
    local bx,by=p.sx+p.dx*length,p.sy+p.dy*length
    if max(ax,bx)+max(0,p.ox) < cx-1 or
        min(ax,bx)+min(0,p.ox) > cx+128 or
        max(ay,by)+max(0,p.oy) < cy-1 or
        min(ay,by)+min(0,p.oy) > cy+128 then return end
    local gaps=cache.gaps[index]
    if gaps then
        for c in all(gaps) do
            -- A crossing only exists visually once the moving tip reaches it.
            if crossing_visible(c,cache,extent,r) then
                local gap=crossing_gap(c)
                draw_cable_interval(p,first,min(length,gap-1))
                first=max(first,gap+4)
                if first > length then return end
            end
        end
    end
    draw_cable_interval(p,first,length)
end

-- An interval is a continuous visible part of a segment, measured in pixels.
-- Paint its base cable and overlay oxygen bands using the derived phase.
function draw_cable_interval(p,lo,hi)
    if lo > hi then return end
    draw_cable_span(p,lo,hi,6,7)
    local wavelength=oxygen_band+oxygen_gap
    local first=lo+(oxygen_phase-p.phase-lo)%wavelength
    if first-lo > oxygen_gap then first-=wavelength end
    while first <= hi do
        local last=min(flr(hi),ceil(first+oxygen_band)-1)
        local start=max(lo,ceil(first))
        if start <= last then draw_cable_span(p,start,last,8,9) end
        first+=wavelength
    end
end

-- Paint a pixel range as two parallel lines using the supplied color pair.
-- This span is the lowest drawing level, used for both cable and oxygen bands.
function draw_cable_span(p,first,last,c1,c2)
    local ax,ay=p.sx+p.dx*first,p.sy+p.dy*first
    local bx,by=p.sx+p.dx*last,p.sy+p.dy*last
    line(ax,ay,bx,by,c1)
    line(ax+p.ox,ay+p.oy,bx+p.ox,by+p.oy,c2)
end

-- A crossing cuts a gap only while both participating strands are visible.
function crossing_visible(c,cache,extent,r)
    if motion and motion.cache == cache and
        c.index == motion.index and c.distance > extent then
        return false
    end
    return not r or
        (c.index > r.index or c.index == r.index and c.distance >= r.offset) and
        (c.old_index > r.index or c.old_index == r.index and c.old_distance >= r.offset)
end

-- Derive pixel geometry in one reusable record, avoiding per-frame allocations.
function cable_geometry(a,b)
    local p=cable_segment
    p.dx,p.dy=0,0
    if b.x != a.x then p.dx=sgn(b.x-a.x) end
    if b.y != a.y then p.dy=sgn(b.y-a.y) end
    p.length=pos_dist(a,b)*8
    p.sx,p.sy=a.x*8+3,a.y*8+3
    p.ox,p.oy=0,0
    if p.dy < 0 then p.ox=1
    elseif p.dy > 0 then
        p.sx+=1 p.sy+=1 p.ox=-1
    elseif p.dx > 0 then
        p.sx+=1 p.oy=1
    else
        p.sy+=1 p.oy=-1
    end
    return p
end

-- Return the eased player position without changing the logical anchor path.
function player_display_pos()
    if not motion then return last_anchor() end
    -- smoothstep eases both ends without changing logical positions
    local t=motion.t
    return pos_interp(motion.a,motion.b,t*t*(3-2*t))
end

-- Animation setup and control.

-- Reset visual state and build crossings for the initial active path.
function init_cable_draw()
    motion=nil
    -- durations in frames at 60hz
    ground_frames=2
    space_min=4
    space_max=30
    cable_retraction=nil
    oxygen_phase=0
    oxygen_band=16 -- oxygen length in pixels
    oxygen_gap=32 -- empty length in pixels
    oxygen_speed=1 -- pixels per frame; keeps flowing during undo
    cable_cache=new_cable_cache(last_tank_connection,#anchors)
end

-- Advance oxygen flow, cable retraction, and player travel once per frame.
function update_cable_draw()
    oxygen_phase=(oxygen_phase+oxygen_speed)%(oxygen_band+oxygen_gap)
    update_cable_retraction()
    -- Animation advances independently; commands never wait for it to finish.
    if motion then
        motion.t=mid(0,motion.t+motion.dir/motion.duration,1)
        if motion.dir > 0 and motion.t == 1 or
            motion.dir < 0 and motion.t == 0 then
            finish_motion()
        end
    end
end

-- Reverse an unfinished move smoothly, or animate undo from a completed anchor.
function start_undo_motion()
    if motion and motion.dir < 0 then finish_motion() end
    if motion then
        -- Preserve progress to reverse without a position jump.
        motion.dir=-1
    else
        -- A completed move retracts from its full length.
        start_motion(anchors[#anchors-1],last_anchor(),#anchors,1,-1,cable_cache)
    end
end

-- Start or replace a movement animation without delaying an accepted move.
function start_motion(a,b,index,t,dir,cache)
    local distance=pos_dist(a,b)
    local duration=mid(space_min,distance,space_max)
    if distance == 1 then duration=ground_frames end
    -- a/b stay in cable order even on undo; index is b's anchor index.
    -- t is extension (0..1); dir grows (+1) or retracts (-1).
    motion={a=a,b=b,index=index,t=t,dir=dir,
        duration=duration,cache=cache}
end

-- Finish the current move's cable visuals and release its animation state.
function finish_motion()
    if not motion then return end
    if motion.dir < 0 then
        trim_cable_cache(motion.cache,motion.index-1)
    elseif tank_connection_at(motion.b) then
        start_cable_retraction(motion.cache)
    end
    motion=nil
end

-- Keep the retired crossing cache only for the duration of its retraction.
function start_cable_retraction(cache)
    -- Measure in tiles to leave room in PICO-8's fixed-point numbers.
    local length=0
    for i=cache.first+1,cache.last do
        length+=pos_dist(anchors[i-1],anchors[i])
    end
    cable_retraction={cache=cache,length=length,distance=0}
end

-- Advance the retraction distance and discard completed animation state.
function update_cable_retraction()
    if not cable_retraction then return end
    local r=cable_retraction
    r.distance=min(r.length,r.distance+max(0.125,r.length/18))
    if r.distance == r.length then cable_retraction=nil end
end

-- Path-change hooks and crossing caches.

-- Complete interrupted visuals, extend their cache, and animate the accepted move.
function append_cable_draw()
    finish_motion()
    local index=#anchors
    local cache=cable_cache
    cache_cable_segment(cache,index,last_anchor())
    if last_tank_connection == index then
        cable_cache=new_cable_cache(index,index)
    end
    start_motion(anchors[index-1],last_anchor(),index,0,1,cache)
end

-- Restore a previous tank's cache on undo, without a tank retraction animation.
-- The departing segment remains in the cache until its movement animation ends.
function pop_cable_draw()
    if cable_cache.first == last_tank_connection then return end
    local cache=motion.cache
    if cache.first != last_tank_connection then
        cache=cable_retraction and cable_retraction.cache
    end
    if not cache or cache.first != last_tank_connection then
        cache=new_cable_cache(last_tank_connection,#anchors)
        cache_cable_segment(cache,motion.index,motion.b)
    end
    cable_cache=cache
    motion.cache=cache
    cable_retraction=nil
end

-- Rebuild one cable in traversal order so its alternating crossings match history.
function new_cable_cache(first,last)
    local cache={first=first,last=first,crossings={},gaps={}}
    for i=first+1,last do cache_cable_segment(cache,i,anchors[i]) end
    return cache
end

-- Compare only the new segment with this cable; retain crossing indices/distances.
-- Sparse gap lists index the under-strand and share the crossing records.
function cache_cable_segment(cache,index,b)
    local a=anchors[index-1]
    local found={}
    for i=cache.first+1,index-1 do
        local old=anchors[i-1]
        local x,y=cable_crossing(a,b,old,anchors[i])
        if x then
            add(found,{index=index,old_index=i,
                distance=(abs(x-a.x)+abs(y-a.y))*8,
                old_distance=(abs(x-old.x)+abs(y-old.y))*8})
        end
    end
    sort_by(found,function(c) return c.distance end)
    for c in all(found) do
        c.under=(#cache.crossings%2 == 0) and index or c.old_index
        local gaps=cache.gaps[c.under]
        if not gaps then
            gaps={}
            cache.gaps[c.under]=gaps
        end
        add(gaps,c)
        sort_by(gaps,crossing_gap)
        add(cache.crossings,c)
    end
    cache.last=index
end

-- Drop undone crossings from the tail and release gap lists that become empty.
function trim_cable_cache(cache,last)
    local crossings=cache.crossings
    while #crossings > 0 and crossings[#crossings].index > last do
        local c=deli(crossings)
        local gaps=cache.gaps[c.under]
        del(gaps,c)
        if #gaps == 0 then cache.gaps[c.under]=nil end
    end
    cache.last=last
end

-- The four-pixel gap starts two pixels before the crossing in every direction.
function crossing_gap(c)
    return (c.under == c.index and c.distance or c.old_distance)-2
end

-- Find strict perpendicular intersections; shared endpoints are not crossings.
function cable_crossing(a1,a2,b1,b2)
    if a1.x == a2.x and b1.y == b2.y then
        if (a1.x-b1.x)*(a1.x-b2.x) < 0 and (b1.y-a1.y)*(b1.y-a2.y) < 0 then
            return a1.x,b1.y
        end
    end
    if a1.y == a2.y and b1.x == b2.x then
        if (a1.y-b1.y)*(a1.y-b2.y) < 0 and (b1.x-a1.x)*(b1.x-a2.x) < 0 then
            return b1.x,a1.y
        end
    end
end
