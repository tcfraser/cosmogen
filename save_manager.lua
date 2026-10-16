-- Save cartridge offsets: header 0x0000, edges 0x0400, anchors 0x0c00.
-- The 1kb header is reserved. Anchors start with a two-byte count,
-- followed by x,y byte pairs (up to 7039 positions).
-- Staging uses only high RAM, 0x8000..0xc2ff, leaving game assets intact.
local save_file="cosmogen_save.p8"
local save_buffer,save_size=0x8000,0x4300
local save_edges,save_anchors=0x8400,0x8c00
local save_anchor_limit=7039

local function encode_save_anchors(path)
    poke2(save_anchors,#path)
    local addr=save_anchors+2
    for p in all(path) do
        poke(addr,p.x,p.y)
        addr+=2
    end
end

function init_save_manager()
    menuitem(0x301,"save progress",function() save_data() end)
    menuitem(0x302,"dev : reset",function()
        reset_save_data()
        load_data()
    end)
    memset(save_buffer,0,save_size)
    -- Probe storage directly: ls() is unavailable to BBS cartridges.
    if reload(save_buffer,0,save_size,save_file)==0 then
        reset_save_data()
    end
end

-- Reset the file only; load_data() applies it to the running game.
function reset_save_data()
    memset(save_buffer,0,save_size)
    encode_save_anchors(default_anchors())
    cstore(0,save_buffer,save_size,save_file)
end

function save_data()
    -- Never truncate history or overwrite a save with a partial path.
    if #anchors<1 or #anchors>save_anchor_limit then
        printh("cosmogen: anchor history exceeds save capacity")
        return false
    end
    encode_overlay_save_data(save_edges)
    memset(save_anchors,0,0x3700)
    encode_save_anchors(anchors)
    cstore(0,save_buffer,save_size,save_file)
    return true
end

function load_data()
    if reload(save_buffer,0,save_size,save_file)==0 then return false end
    local count=peek2(save_anchors)
    if count<1 or count>save_anchor_limit then return false end
    local path={}
    for i=1,count do
        local x,y=peek(save_anchors+i*2,2)
        if x>=map.width or y>=map.height then return false end
        add(path,pos(x,y))
    end
    init_cable(path)
    decode_overlay_save_data(save_edges)
    init_screen()
    update_screen()
    return true
end
