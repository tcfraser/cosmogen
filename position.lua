-- Provides position arithmetic, comparisons, distance, and direction helpers.
-- Interpolates positions for movement and camera animation.

function pos(p_x, p_y)
    return { x=p_x, y=p_y }
end

function pos_str(p)
    if p==nil then return "(nil pos)" end
    return "("..p.x..","..p.y..")"
end

function pos_zero(p)
    return p.x == 0 and p.y == 0
end

function pos_add(p1, p2)
    return pos(p1.x + p2.x, p1.y + p2.y)
end

function pos_subtract(p1, p2)
    return pos(p1.x - p2.x, p1.y - p2.y)
end

function pos_scale(p, s)
    return pos(p.x*s, p.y*s)
end

function pos_equal(p1, p2)
    return p1.x == p2.x and p1.y == p2.y
end

function pos_dist(p1, p2)
    return abs(p1.x - p2.x) + abs(p1.y - p2.y)
end

function pos_dir(p)
    local dir = pos(0, 0)
    if p.x != 0 then dir.x = sgn(p.x) end
    if p.y != 0 then dir.y = sgn(p.y) end
    return dir
end

function pos_zero(p)
    return p.x == 0 and p.y == 0
end

function pos_interp(a,b,t)
    return pos(a.x * (1-t) + b.x * t, a.y * (1-t) + b.y * t)
end
