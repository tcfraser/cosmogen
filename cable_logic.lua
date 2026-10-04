-- Owns position history, the current tank connection, and movement rules.
-- Applies moves and undos, then notifies the cable animation code.

function init_cable()
    anchors={
        pos(map.start.x+1,map.start.y), -- starting tank is to the right
        pos(map.start.x,map.start.y)
    }
    update_tank_connection()
    init_cable_draw()
    sync_critters()
    -- Initialize doors even when no arrows are collected (or assigned).
    sync_doors()
    sync_arrows_add()
end

-- Tank boundaries are derived from positions, including repeated connections.
function update_tank_connection()
    last_tank_connection=1
    for i=#anchors,1,-1 do
        if tank_connection_at(anchors[i]) then
            last_tank_connection=i
            return
        end
    end
end

function append_to_path(p)
    add(anchors, p)
    update_tank_connection()
    sync_critters()
    sync_arrows_add()
    append_cable_draw()
end

function pop_from_path()
    if #anchors > 1 then
        deli(anchors, #anchors)
        update_tank_connection()
        sync_critters()
        sync_arrows_remove()
        pop_cable_draw()
    end
end

function last_anchor()
    return anchors[#anchors]
end

function last_move_delta()
    -- The incoming segment at a tank belongs to the retired cable.
    if #anchors <= last_tank_connection then return nil end
    -- Returning to a tank makes a new connection instead of undoing.
    if tank_connection_at(anchors[#anchors-1]) then return nil end
    return pos_dir(pos_subtract(last_anchor(),anchors[#anchors-1]))
end

function undo_move()
    if #anchors < 2 then
        finish_motion()
        return
    end
    start_undo_motion()
    last_delta_attempt=pos_dir(pos_subtract(anchors[#anchors-1],last_anchor()))
    -- Restore puzzle state now; the animation retains the departing segment.
    pop_from_path()
end


function has_no_anchor(p)
    for i=last_tank_connection,#anchors do
        if pos_equal(p,anchors[i]) then return false end
    end
    return true
end

function is_stable_ground(p)
    return fget(mget(p.x,p.y),1)
end

function is_blocked(p)
    return fget(mget(p.x,p.y),2)
end
