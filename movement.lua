function init_movement()
    motion=nil
    buffered_delta=nil
    -- durations in frames at 60hz
    ground_frames=2
    space_min=4
    space_max=30
end

function start_motion(a,b,index,t,dir,list)
    local distance=pos_dist(a,b)
    local duration=mid(space_min,distance,space_max)
    if distance == 1 then duration=ground_frames end
    -- a/b stay in cable order even on undo; index is b's anchor index.
    -- t is extension (0..1); dir grows (+1) or retracts (-1).
    motion={a=a,b=b,index=index,t=t,dir=dir,crossings=list,
        duration=duration}
end

function player_display_pos()
    if not motion then return last_anchor() end
    -- smoothstep eases both ends without changing logical positions
    local t=motion.t
    return pos_interp(motion.a,motion.b,t*t*(3-2*t))
end

function undo_move()
    -- undo wins over queued movement; finish one retraction at a time
    buffered_delta=nil
    if motion and motion.dir < 0 then return end
    if #anchors < 2 then return end
    -- retain removed crossings only for the retracting visual
    local list={}
    for c in all(crossings) do add(list,c) end
    if motion then
        -- preserve progress to reverse without a position jump
        motion.dir=-1
        motion.crossings=list
    else
        -- a completed move retracts from its full length
        start_motion(anchors[#anchors-1],last_anchor(),#anchors,1,-1,list)
    end
    last_delta_attempt=pos_dir(pos_subtract(motion.a,motion.b))
    -- restore puzzle state now; motion retains the departing segment
    pop_from_path()
end

function update_movement()
    -- finish the visible transition before consuming another command
    if motion then
        motion.t=mid(0,motion.t+motion.dir/motion.duration,1)
        if motion.dir > 0 and motion.t == 1 or
            motion.dir < 0 and motion.t == 0 then motion=nil end
    end

    -- simultaneous axes choose vertical; opposing buttons cancel
    local delta=pos(0,0)
    if btnp(0) then delta.x-=1 end
    if btnp(1) then delta.x+=1 end
    if btnp(2) then delta.y-=1 end
    if btnp(3) then delta.y+=1 end
    if delta.y != 0 then delta.x=0 end

    local reverse=last_move_delta()
    -- opposite movement also undoes, including during forward travel
    if btnp(5) or (not pos_zero(delta) and reverse and
        (not motion or motion.dir > 0) and pos_zero(pos_add(reverse,delta))) then
        undo_move()
        return
    end
    -- store only the latest intent, not a precomputed destination
    if not pos_zero(delta) then buffered_delta=delta end
    if motion or not buffered_delta then return end

    delta=buffered_delta
    buffered_delta=nil
    last_delta_attempt=delta
    -- recheck buffered intent against the current logical path
    if reverse and pos_zero(pos_add(reverse,delta)) then
        undo_move()
    else
        local a=last_anchor()
        -- commit movement/collection first; animate only accepted moves
        if attempt_move(delta) then
            start_motion(a,last_anchor(),#anchors,0,1,crossings)
        end
    end
end
