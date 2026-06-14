function sort_by(t,f)
  for i=1,#t-1 do
    local best=i

    for j=i+1,#t do
      if f(t[j]) < f(t[best]) then
        best=j
      end
    end

    local tmp=t[i]
    t[i]=t[best]
    t[best]=tmp
  end

  return t
end

function wrap(val, low, high)
    local diff = high - low
    if val < low then return val + diff end
    if val > high then return val - diff end
    return val
end
