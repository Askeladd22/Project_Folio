local MenuParticles = {}

function MenuParticles.create_default(count)
    local total = math.max(1, tonumber(count) or 34)
    local particles = {}
    for i = 1, total do
        particles[i] = {
            x = 0.02 + 0.96 * (((i * 37) % 100) / 100),
            y = 0.02 + 0.96 * (((i * 53 + 17) % 100) / 100),
            drift = 0.0018 + ((i - 1) % 6) * 0.00045,
            sway = 0.0012 + ((i - 1) % 5) * 0.00045,
            phase = (i - 1) * 0.73,
            speed = 0.16 + ((i - 1) % 7) * 0.035,
            size = 0.52 + ((i - 1) % 4) * 0.20,
            depth = 0.70 + ((i - 1) % 5) * 0.09,
        }
    end
    return particles
end

function MenuParticles.update(particles, dt, reduced_animations)
    if reduced_animations then
        return
    end
    for _, particle in ipairs(particles or {}) do
        particle.phase = particle.phase + dt * particle.speed
        particle.y = particle.y - dt * particle.drift * particle.depth
        if particle.y < -0.03 then
            particle.y = 1.02
        end
    end
end

function MenuParticles.draw(particles, width, height, ui_scale, high_contrast, alpha_mul)
    local scale = tonumber(ui_scale) or 1
    local alpha_scale = tonumber(alpha_mul) or 1
    for _, particle in ipairs(particles or {}) do
        local px = (particle.x + math.sin(particle.phase * (0.8 + particle.depth * 0.2)) * particle.sway) * width
        local py = (particle.y + math.cos(particle.phase * 0.55) * particle.sway * 0.8) * height
        local twinkle = 0.5 + 0.5 * math.sin(particle.phase * 1.6 + particle.depth)
        local alpha = (0.10 + 0.12 * twinkle) * (high_contrast and 1.15 or 1.0) * alpha_scale
        local core_radius = math.max(0.45, particle.size * scale * 0.90)
        local halo_radius = core_radius * 2.3

        love.graphics.setColor(0.93, 0.87, 0.76, alpha)
        love.graphics.circle("fill", px, py, core_radius)
        love.graphics.setColor(0.86, 0.79, 0.66, alpha * 0.42)
        love.graphics.circle("fill", px, py, halo_radius)
    end
end

return MenuParticles
