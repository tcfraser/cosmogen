-- Reads controller input and turns it into movement or undo requests.
-- Directional backtracking uses the active cable path.

function update_movement()
    -- simultaneous axes choose vertical; opposing buttons cancel
    local delta=pos(0,0)
    if btnp(0) then delta.x-=1 end
    if btnp(1) then delta.x+=1 end
    if btnp(2) then delta.y-=1 end
    if btnp(3) then delta.y+=1 end
    if delta.y != 0 then delta.x=0 end

    local reverse=last_move_delta()
    -- opposite movement undoes only along the active cable
    if btnp(5) or (not pos_zero(delta) and reverse and
        pos_zero(pos_add(reverse,delta))) then
        undo_move()
        return
    end
    if pos_zero(delta) then return end
    last_delta_attempt=delta
    attempt_move(delta)
end

function attempt_move(delta)
    if pos_zero(delta) then return false end

    local candidate = last_anchor()

    --check forward this much
    for s = 1, 32 do
        -- accumulate one tile each for loop to search outward
        candidate = pos_add(candidate, delta)
        if is_blocked(candidate) or tank_blocking_body_at(candidate) or door_blocking_at(candidate) then
            return false
        end
        if is_stable_ground(candidate) then
            if not (tank_connection_at(candidate) or has_no_anchor(candidate)) then
                return false
            end
            -- Commit movement/collection first; animate only accepted moves.
            append_to_path(candidate)
            return true
        end
    end
    return false
end
