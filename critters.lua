function replace_critters(x,y)
    if mget(x,y) == 10 then -- critter sprite
        init_critter(x,y)
        mset(x,y,default.asteroid) 
    end
end

function init_critter(x,y)
    if critters == nil then critters = {} end
    add(critters, {x=x,y=y,collected_at=-1,anim_timer=0,state="idle"})
end

function update_critters()
    for c in all(critters) do
        c.anim_timer += 1
        if c.anim_timer >= 60 then
            c.anim_timer = 0
        end
    end
end

-- collection changes only when the logical path changes
function sync_critters()
    for c in all(critters) do
        if c.collected_at > #anchors then
            c.collected_at = -1
        end
        if c.collected_at < 0 and pos_equal(c, last_anchor()) then
            c.collected_at = #anchors
        end
    end
end

function draw_critters()
    for c in all(critters) do
        if c.collected_at < 0 or
            (motion and motion.dir > 0 and c.collected_at == motion.index) then
            local p = pos_scale(c,8)
            local sprite = 10
            if c.anim_timer >= 50 then
                sprite = 26
            end
            transparency(14)
            spr(sprite,p.x,p.y)
            transparency(0)
        end
    end
end
