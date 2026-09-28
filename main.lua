-- Initializes the game and coordinates per-frame updates.
-- Draws the world and UI in their intended layer order.

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

    update_cable_draw()
    update_movement()

    update_screen()
end


function _draw()
    cls()
    -- background layer
    camera(0,0)
    draw_stars()
    -- world layer
    camera(round(screen.interp.x*8),round(screen.interp.y*8))
    draw_map()
    draw_tanks()
    draw_cable()
    draw_astronaut()
    draw_critters()
    draw_arrows()
    -- ui layer
    camera(0,0)
    draw_debug()
end
