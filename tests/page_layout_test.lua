local ok, Layout = pcall(require, "src.features.scriptorium.page_layout")
assert(ok, "shared desk page layout is not implemented")
local Resolution = require("src.core.resolution_manager")
local layout = Layout.get()
-- A wrong inverse transform or inclusive far edge must not select another cell.
for _, size in ipairs({{1920,1080}, {1280,720}, {1000,900}, {2560,1080}, {800,600}}) do
    Resolution.refresh(size[1], size[2])
    for row = 1,4 do
        for col = 1,5 do
            local r = Layout.cell_rect(row,col)
            local sx,sy = Resolution.to_screen(r.x+r.w/2,r.y+r.h/2)
            local vx,vy = Resolution.to_virtual(sx,sy)
            local actual_row,actual_col = Layout.hit_cell(vx,vy)
            assert(actual_row == row and actual_col == col, "resize changed cell target")
            assert(Layout.hit_cell(r.x+r.w+1,r.y+4) == nil, "gap is clickable")
        end
    end
    local tray = Layout.screen_tray(Resolution)
    assert(tray.x >= 0 and tray.y >= 0 and tray.x+tray.w <= size[1]+0.01)
    assert(tray.y+tray.h <= size[2]+0.01, "tray outside viewport")
end
assert(Layout.hit_cell(layout.page.x-1,layout.page.y) == nil)
local last = Layout.cell_rect(4,5)
assert(Layout.hit_cell(last.x+last.w,last.y+last.h) == nil)
local function overlaps(a,b)
    return a.x < b.x+b.w and b.x < a.x+a.w and a.y < b.y+b.h and b.y < a.y+a.h
end
assert(not overlaps(layout.dock,layout.tray), "palette/buffer overlap dice")
assert(layout.actions and not overlaps(layout.actions,layout.tray), "actions overlap dice")
assert(layout.page.y+layout.page.h < layout.dock.y, "page overlaps controls")
print("ok - desk hit testing and tray bounds across five window sizes")
