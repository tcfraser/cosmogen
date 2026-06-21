function _init()
    clock=0
    pal_alt()
    init_utils()
    init_map()
    init_screen()
    init_cable()

    music(4,1000)
end

function _update60()
    clock += 1 
    if clock == 60 then clock = 0 end

    update_arrows()
    update_critters()

    delta = pos(0,0)
    if btnp(0) then delta.x -= 1 end
    if btnp(1) then delta.x += 1 end
    if btnp(2) then delta.y -= 1 end
    if btnp(3) then delta.y += 1 end

    resolve_delta(delta)

    if not pos_zero(delta) then
        last_delta_attempt = delta -- stored for drawing astronaut
    end

    if btnp(5) then
        -- undo
        pop_from_path()
    end

    update_screen()
end


function _draw()
    cls()
    -- world layer
    camera(round(screen.interp.x*8),round(screen.interp.y*8))
    draw_map()
    draw_cable()
    draw_astronaut()
    draw_critters()
    draw_arrows()
    -- ui layer
    camera(0,0)
    draw_debug()
end
