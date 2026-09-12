function _init()
    clock=0
    pal_alt()
    init_utils()
    init_map()
    init_screen()
    init_cable()
    init_movement()

    music(4,1000)
end

function _update60()
    clock += 1 
    if clock == 60 then clock = 0 end

    update_arrows()
    update_critters()

    update_movement()

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
