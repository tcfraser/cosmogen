-- Provides palette setup and sprite transparency helpers.
-- Selects a single transparent color when drawing entities.

function pal_alt()
    for i = 0,15 do
    end
end

function transparency(i)
    for i = 0,15 do
        palt(i, false)
    end
    palt(i,true)
end
