-- All desk geometry is in the existing 1920x1080 virtual coordinate space.
-- The lectern silhouette suggests inclination; the playable surface stays flat.
local Layout = {}
local page = {x = 610, y = 62, w = 700, h = 568}
local grid = {x = 76, y = 106, cell = 100, gap = 12, rows = 4, cols = 5}

function Layout.get()
    return {
        page = {x = page.x, y = page.y, w = page.w, h = page.h},
        commission = {x = 80, y = 116, w = 420, h = 510},
        glosses = {x = 1420, y = 116, w = 420, h = 510},
        dock = {x = 80, y = 682, w = 420, h = 236},
        actions = {x = 1420, y = 682, w = 420, h = 180},
        tray = {x = 530, y = 666, w = 860, h = 404},
        layers = {
            background = {x = 0, y = 0, w = 1920, h = 1080},
            desk = {x = 0, y = 650, w = 1920, h = 430},
            lectern = {x = 480, y = 48, w = 960, h = 612},
            parchment = {x = page.x, y = page.y, w = page.w, h = page.h},
        },
    }
end

function Layout.to_page(x, y)
    return x - page.x, y - page.y
end

function Layout.cell_rect(row, col)
    return {
        x = page.x + grid.x + (col - 1) * (grid.cell + grid.gap),
        y = page.y + grid.y + (row - 1) * (grid.cell + grid.gap),
        w = grid.cell, h = grid.cell,
    }
end

function Layout.hit_cell(x, y)
    local px, py = Layout.to_page(x, y)
    px, py = px - grid.x, py - grid.y
    if px < 0 or py < 0 then return nil end
    local step = grid.cell + grid.gap
    local col, row = math.floor(px / step) + 1, math.floor(py / step) + 1
    if row > grid.rows or col > grid.cols or px % step >= grid.cell or py % step >= grid.cell then
        return nil
    end
    return row, col
end

function Layout.screen_tray(resolution)
    local tray = Layout.get().tray
    local x, y = resolution.to_screen(tray.x, tray.y)
    local right, bottom = resolution.to_screen(tray.x + tray.w, tray.y + tray.h)
    return {x = x, y = y, w = right - x, h = bottom - y}
end

return Layout
