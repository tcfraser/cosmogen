-- Builds arrow entities from paired map markers.
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
        if is_vertical then
            spr(66,a.drawp.x,a.drawp.y+po,1,1,flip_x,flip_y)
        else
            spr(65,a.drawp.x+po,a.drawp.y,1,1,flip_x,flip_y)
        end
    end
    transparency(0)
end

function update_arrows()
    for a in all(arrows) do
        a.anim_timer += 1
        if a.anim_timer >= 240 then
            a.anim_timer = 0
        end
    end
end

-- arrow replacement below
function replace_arrows(x,y)
    local sprite = mget(x,y)
    local is_arrow = fget(sprite,6)
    if not is_arrow then return end -- only process arrows
    local is_source = (sprite % 2 == 0)
    if is_arrow and not is_source then return end -- only process sources
    process_arrow_source(x,y)
end

function process_arrow_source(x,y)
    local is_asteroid = fget(sprite,1)
    local source = pos(x,y)
    local sink = nil
    local dir = -1
    for i=1,4 do
        local neighbor = pos_add(source,DIRS[i])
        local nsprite = mget_wrapped(neighbor.x,neighbor.y)
        if fget(nsprite,6) then -- is arrow
            sink = neighbor
            dir = i-1
            break
        end
    end
    -- assumed here that sink was found
    assert(sink != nil)

    if arrows == nil then arrows={} end
    local drawp = pos_scale(pos_scale(pos_add(source,sink),1/2),8)
    add(arrows, {inp=source,outp=sink,drawp=drawp,dir=dir,anim_timer=rnd(120)})

    replace_arrow_sprite(source.x, source.y)
    replace_arrow_sprite(sink.x, sink.y)
end

function replace_arrow_sprite(x,y)
    if fget(mget(x,y),1) then
        mset(x,y,default.asteroid)
    else
        mset(x,y,default.space)
    end
end
