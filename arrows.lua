-- Builds arrow entities from single directional map markers.
-- Updates their animation timers and draws the arrow indicators.

function draw_arrows()
    local p_offsets = {-1,0,1,0}
    transparency(14)
    for a in all(arrows) do
        local anim_idx = flr(a.anim_timer / 60) + 1
        local po = p_offsets[anim_idx]
        local flip_x = a.dir == 0
        local flip_y = a.dir == 3
        local is_vertical = a.dir >= 2
        local collected_shift = 0
        if a.collected_at >= 0 then
            collected_shift = 81-65
            po=0
        end
        if is_vertical then
            spr(66+collected_shift,a.drawp.x,a.drawp.y+po,1,1,flip_x,flip_y)
        else
            spr(65+collected_shift,a.drawp.x+po,a.drawp.y,1,1,flip_x,flip_y)
        end
    end
    transparency(0)
end

-- Check only the newly appended segment; keep earlier collection indices.
function sync_arrows_add()
    local i = #anchors
    if i < 2 then return end
    local p,q = anchors[i-1],anchors[i]
    local changed = false
    for a in all(arrows) do
        if a.collected_at < 0 then
            local axis,cross = "x","y"
            if a.dir >= 2 then axis,cross = "y","x" end
            local d = DIRS[a.dir+1][axis]
            if p[cross] == a.inp[cross] and q[cross] == a.inp[cross]
                and (a.inp[axis]-p[axis])*d >= 0
                and (q[axis]-a.outp[axis])*d >= 0 then
                a.collected_at = i
                changed = true
            end
        end
    end
    if changed then sync_doors() end
end

-- Called after removing the last anchor.
function sync_arrows_remove()
    local changed = false
    for a in all(arrows) do
        if a.collected_at == #anchors+1 then
            a.collected_at = -1
            changed = true
        end
    end
    if changed then sync_doors() end
end

function update_arrows()
    for a in all(arrows) do
        a.anim_timer += 1
        if a.anim_timer >= 240 then
            a.anim_timer = 0
        end
    end
end


-- ===== Arrow Map Conversion =====
function replace_arrows(x,y)
    local sprite = mget(x,y)
    local ground = sprite >= 84 and sprite <= 87
    if not ground and not (sprite >= 68 and sprite <= 71) then return end
    -- Markers: left,up,down,right; DIRS: left,right,up,down.
    local dir = ({0,2,3,1})[sprite%16-3]
    local source = pos(x,y)
    local sink = pos_add(source,DIRS[dir+1])

    if arrows == nil then arrows={} end -- creating the arrows table for the first time

    local drawp = pos_scale(pos_scale(pos_add(source,sink),1/2),8)
    add(arrows, {inp=source,outp=sink,drawp=drawp,dir=dir,collected_at=-1,anim_timer=rnd(120)})

    if ground then
        mset(x,y,default.asteroid)
    else
        mset(x,y,default.space)
    end
end
