function init_screen()
    screen={
        timer = 0,
        current = pos(0,0),
        last = nil,
        interp = nil,
        transition_time=30,
    }
end

function update_screen()
    if screen.timer > 0 then
        screen.timer -= 1
    end

    local p = pos_scale(player_display_pos(), 1/16)
    p.x, p.y = flr(p.x), flr(p.y)
    p = pos_scale(p, 16)
    if not pos_equal(p,screen.current) then
        screen.last = screen.interp or p
        screen.timer = screen.interp and screen.transition_time or 0
        screen.current = p
    end
    if screen.last == nil then
        screen.last = screen.current
    end
    screen.interp = pos_interp(screen.current,screen.last,screen.timer/screen.transition_time)
    --debug("current"..pos_str(screen.current), 1)
    --debug("last"..pos_str(screen.last), 2)
    --debug("interp"..pos_str(screen.interp), 3)
end

-- map screen get
function msget(x,y)
    return mget(x+screen.current.x,y+screen.current.y)
end

-- screen position
function scrp(p)
    return pos_add(p,pos_scale(screen.interp, -1))
end

-- screen draw position
function scrdp(p)
    return pos_scale(scrp(p), 8)
end
