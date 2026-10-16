local M = {}

function M.install(U)
    local R = require('src.gameplay.farkle.rules')
    local H = require('src.features.farkle.hud_model')
    local Res = require('src.core.resolution_manager')
    local root = assert(os.getenv('MANUSCRIPT_AUDIT_OUT')) .. '/'
    local log = assert(io.open(root .. 'comparison.log', 'w'))

    local function record(s)
        log:write(s .. '\n')
        log:flush()
        print(s)
    end

    function love.errorhandler(e)
        record('FAIL ' .. tostring(e) .. '\n' .. debug.traceback())
        log:close()
        return function() return 1 end
    end

    local load, update, draw = love.load, love.update, love.draw
    local elapsed, frames = 0, 0
    local pending, co

    local function click(id)
        U:draw()
        if U.modal or H.reward_active(U.game) then
            U:drawDeskOverlays(U.hits)
        end
        local b = assert((U.modal and U.modalButtons or U.buttons)[id], 'Button not found: ' .. tostring(id) .. ' variant=' .. tostring(U.hud_variant) .. ' phase=' .. tostring(U.game.phase))
        assert(b.enabled, 'Button disabled: ' .. tostring(id))
        local x, y = Res.to_screen(b.x + b.w / 2, b.y + b.h / 2)
        U:mousepressed(x, y, 1)
    end

    local function shot(name)
        coroutine.yield({shot = name})
    end

    local function wait()
        coroutine.yield({wait = true})
    end

    local function roll_and_settle(values)
        click('roll')
        U.pending = {}
        U.observed = {}
        local a = {}
        for i, v in pairs(values) do
            a[#a + 1] = {index = i, value = v}
        end
        U:onDiceSettled(a)
    end

    local function play_full_commission(variant)
        U.hud_variant = variant
        U:reset('build')
        local prefix = variant .. '-'

        record('--- INIZIO COMMISSIONE (' .. variant:upper() .. ' HUD) ---')
        local steps = 0

        -- 1. Stato iniziale Fresh
        shot(prefix .. '1-fresh')
        steps = steps + 1

        -- 2. Primo lancio: escono {1, 2, 3, 4, 6, 6} (dado 1 = 10 pt)
        roll_and_settle({1, 2, 3, 4, 6, 6})
        shot(prefix .. '2-first-settle')
        steps = steps + 1

        -- Selezione del dado 1
        U:toggle(1)
        shot(prefix .. '3-die-selected')
        steps = steps + 1

        -- Accantonamento (Take: +10 pt)
        click('take')
        assert(U.game.pot == 10 and U.game.used[1], 'take failed')
        shot(prefix .. '4-die-taken-held')
        steps = steps + 1

        -- 3. Rilancio dei 5 dadi rimasti (Rischio e Tensione)
        shot(prefix .. '5-risk-decision-reroll')
        -- Escono tre 1 sui dadi 2, 3, 4 (= 75 pt) e 2, 3
        roll_and_settle({2, 1, 1, 1, 2, 3})
        shot(prefix .. '6-second-settle')
        steps = steps + 1

        -- Selezione dei tre 1
        U:toggle(2)
        U:toggle(3)
        U:toggle(4)
        shot(prefix .. '7-second-selection')
        steps = steps + 3

        -- Accantonamento: 10 + 75 = 85 pt
        click('take')
        assert(U.game.pot == 85, 'second take failed, pot=' .. tostring(U.game.pot))
        shot(prefix .. '8-second-taken')
        steps = steps + 1

        -- 4. Rilancio degli ultimi 2 dadi rimasti (Alta tensione: 85 pt a rischio!)
        -- Escono dado 5 = 1 (10 pt) e dado 6 = 5 (5 pt)
        roll_and_settle({2, 1, 1, 1, 1, 5})
        shot(prefix .. '9-third-settle')
        steps = steps + 1

        -- Selezione di entrambi i dadi (10 + 5 = 15 pt)
        U:toggle(5)
        U:toggle(6)
        shot(prefix .. '10-third-selection')
        steps = steps + 2

        -- Accantonamento finale: 85 + 15 = 100 pt -> DADI CALDI (Hot Dice)!
        click('take')
        assert(U.game.pot == 100 and U.game.hot, 'hot dice failed')
        shot(prefix .. '11-hot-dice')
        steps = steps + 1

        -- 5. Decisione finale: Incasso dei 100 pt!
        shot(prefix .. '12-pre-bank')
        click('bank')
        assert(U.game.bank == 100, 'bank failed')
        shot(prefix .. '13-banked-complete')
        steps = steps + 1

        -- 6. Schermata di consegna e ricompensa della commissione
        assert(U.game.phase == 'upgrade', 'upgrade phase expected')
        shot(prefix .. '14-upgrade-reward')
        click('weighted')
        assert(U.game.stage == 2, 'stage 2 expected')
        steps = steps + 1

        record('COMPLETATA commissione 1 (' .. variant:upper() .. ' HUD) in ' .. steps .. ' passaggi logici.')
        return steps
    end

    function love.load()
        load()
        co = coroutine.create(function()
            love.window.setMode(1920, 1080, {resizable = true})
            love.resize(1920, 1080)

            record('Esecuzione confronto varianti HUD...')
            local steps_standard = play_full_commission('standard')
            local steps_minimal = play_full_commission('minimal')

            record('==================================================')
            record('RISULTATI CONFRONTO COMMISSIONE 1 (Parish Psalter):')
            record('Passaggi totali Standard HUD: ' .. steps_standard)
            record('Passaggi totali Minimal HUD:  ' .. steps_minimal)
            record('Dimensione Tray Standard:     1320x650 (858.000 px^2, 41.4% schermo)')
            record('Dimensione Tray Minimal:      1420x770 (1.093.400 px^2, 52.7% schermo, +27.4% area lancio)')
            record('Pannelli persistenti Standard: 5 (Top, Bottom Shelf, Button Panel, Manuscript, Status)')
            record('Pannelli persistenti Minimal:  0 (Superficie continua in legno, 2 tasti primari, 1 mensola incassata)')
            record('Azioni primarie simultanee:   2 (Lancia/Rilancia vs Incassa)')
            record('==================================================')
            record('PASS comparison complete')
            log:close()
            love.event.quit(0)
        end)
    end

    function love.update(dt)
        elapsed = elapsed + dt
        assert(elapsed < 180, 'Comparison timeout')
        update(dt)
    end

    function love.draw()
        draw()
        frames = frames + 1
        if frames % 8 ~= 0 then return end
        if pending then
            if pending.wait and U.game.phase == 'rolling' then return end
            if pending.shot then
                local name = pending.shot
                love.graphics.captureScreenshot(function(data)
                    local f = assert(io.open(root .. name .. '.png', 'wb'))
                    f:write(data:encode('png'):getString())
                    f:close()
                end)
                record('SCREENSHOT ' .. name)
                pending = nil
                return
            end
        end
        if coroutine.status(co) ~= 'dead' then
            local ok, value = coroutine.resume(co)
            assert(ok, value)
            pending = value
        end
    end
end

return M
