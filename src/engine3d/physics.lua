
require('lib.core')local Logger = require('src.core.engine_bridge').logger
local DieCollisions = require('src.engine3d.die_collision')

local materials = {}

materials.presets = {
  wood = {
    mass = 1.2,
    restitution = 0.25,
    friction = 0.75,
    linear_damping = 0.15,
    angular_damping = 0.20,
    color = {0.55, 0.35, 0.18},
  },
  rubber = {
    mass = 1.0,
    restitution = 0.35,
    friction = 0.85,
    linear_damping = 0.10,
    angular_damping = 0.15,
    color = {0.08, 0.08, 0.10},
  },
  plastic = {
    mass = 0.8,
    restitution = 0.30,
    friction = 0.70,
    linear_damping = 0.12,
    angular_damping = 0.18,
    color = {0.9, 0.2, 0.2},
  },
  metal = {
    mass = 2.0,
    restitution = 0.45,
    friction = 0.60,
    linear_damping = 0.08,
    angular_damping = 0.12,
    color = {0.66, 0.68, 0.70},
  },
  bone = {
    mass = 1.8,
    restitution = 0.30,
    friction = 0.80,
    linear_damping = 0.12,
    angular_damping = 0.18,
    color = {0.97, 0.94, 0.86},
  },
}

function materials.apply(body, preset)
  if not body or not preset then return end
  if preset.mass       then body.mass = preset.mass; body.invMass = (preset.mass ~= 0) and (1 / preset.mass) or 0 end
  if preset.restitution then body.restitution = preset.restitution end
  if preset.friction    then body.friction = preset.friction end
  if preset.linear_damping then body.linear_damping = preset.linear_damping end
  if preset.angular_damping then body.angular_damping = preset.angular_damping end
  body.material = preset
  return body
end

function materials.get(name)
  return materials.presets[name]
end


local box={ timeleft=0 }
box.linear_damping = 0.18
box.angular_damping = 0.18
box.pos_slop = 0.05
box.pos_percent = 0.08
box.max_steps = 5
box.dv_max = 50
box.sleep_linear = 0.15
box.sleep_angular = 0.20
box.sleep_time = 0.08
box.log_buffer = {}
function box:set(x,y,z,gravity,bounce,friction,dt) 
  self.x,self.y,self.z=x or self.x, y or self.y, z or self.z
  self.gravity=gravity or self.gravity
  self.bounce=bounce or self.bounce
  self.friction=friction or self.friction
  self.dt=dt or self.dt or (1/60)
  return self
end

-- Named configuration for production; positional set remains for legacy callers.
function box:configure(c)
  assert(c.fixed_dt and c.fixed_dt > 0 and c.fixed_dt < math.huge, 'fixed_dt must be positive and finite')
  assert(c.half_x > 0 and c.half_y > 0 and c.height > 0, 'positive world dimensions required')
  self:set(c.half_x,c.half_y,c.height,c.gravity,c.restitution,c.friction,c.fixed_dt)
  self.linear_damping=c.linear_damping or self.linear_damping
  self.angular_damping=c.angular_damping or self.angular_damping
  self.border_height=c.border_height or self.border_height
  return self
end

function box:update(dt)
  assert(type(dt)=='number' and dt==dt and dt>=0 and dt<math.huge, 'finite nonnegative dt required')
  if dt==0 then return end
  self.timeleft = self.timeleft + dt
  -- Retain fractional time and bounded catch-up debt. Excess wall time is
  -- explicitly discarded after a long stall, never hidden in a frame correction.
  local limit=self.max_backlog or .25
  if self.timeleft>limit then
    self.dropped_time=(self.dropped_time or 0)+(self.timeleft-limit)
    self.timeleft=limit
  end
  local maxSteps = self.max_steps or 5
  local steps = 0
  while (self.timeleft + 1e-12 >= self.dt) and (steps < maxSteps) do
    -- Angularly swept CCD cannot be reconstructed from end-step axes.
    -- Subdivide only when a moving die rotates substantially, ensuring
    -- intermediate cube orientations participate in SAT/contact response.
    -- Fixed-step time, backlog and after_step cadence stay unchanged.
    local peak_angular=0
    for i=1,#self do
      local die=self[i]
      if not die._manual_pending and not die.asleep then
        peak_angular=math.max(peak_angular,die.angular:abs())
      end
    end
    local angle_limit=self.max_rotation_per_substep or 0.12
    local substep_limit=self.max_angular_substeps or 12
    assert(angle_limit>0 and substep_limit>=1,
      'positive angular substep bounds required')
    local requested=math.max(1,math.ceil(peak_angular*self.dt/angle_limit))
    local count=math.min(requested,substep_limit)
    if requested>substep_limit then
      self.angular_substep_cap_hits=(self.angular_substep_cap_hits or 0)+1
    end
    self.angular_substeps=(self.angular_substeps or 0)+(count-1)
    local sub_dt=self.dt/count
    local emitted_pairs={}
    for substep=1,count do
      -- Previous fixed-step centers are required for continuous pair collision
      -- checks even when bodies no longer overlap at the end of the frame.
      local old_positions={}
      for i=1,#self do
        local p=self[i].position
        old_positions[i]={p[1],p[2],p[3]}
      end
      local gravity_vec = vector{0,0,-(self.gravity or 0) * sub_dt}
      for i=1,#self do
        local s=self[i]
        -- Keep held and waiting dice kinematic until released individually.
        if s._manual_pending then
          s.asleep=true
          s.sleep_timer=0
          s.velocity=vector{0,0,0}
        else
        if not s.asleep then
          local vertices_on_ground = 0
          local ground_z = 0.05
          local ground_vertices_z = {}
          local required_flat_vertices = s.flat_face_vertices or 4
          local flat_z_tolerance = s.flat_z_tolerance or 0.03
          for k=1,#s do
            local vertex_world_z = s[k][3] + s.position[3]
            if vertex_world_z <= ground_z then
              vertices_on_ground = vertices_on_ground + 1
              table.insert(ground_vertices_z, vertex_world_z)
            end
          end
          
          local is_flat = false
          if vertices_on_ground >= required_flat_vertices and #ground_vertices_z >= required_flat_vertices then
            local z_min = math.huge
            local z_max = -math.huge
            for _, z in ipairs(ground_vertices_z) do
              z_min = math.min(z_min, z)
              z_max = math.max(z_max, z)
            end
            is_flat = (z_max - z_min) < flat_z_tolerance
          end
          
          local v_mag = s.velocity:abs()
          local w_mag = s.angular:abs()
          local settle_linear = s.settle_linear or 0.20
          local settle_angular = s.settle_angular or 0.15
          if is_flat and v_mag < settle_linear and w_mag < settle_angular then
            s.velocity = vector{0,0,0}
            s.angular = vector{0,0,0}
            s.asleep = true
            s.sleep_timer = 999
          else
            s.velocity = s.velocity + gravity_vec
            s:update(sub_dt)
            s:box(-self.x,-self.y,0,self.x,self.y,self.z,self.bounce,self.friction)
            
            local border_height = self.border_height or 1.5
            local rim_margin = 0.3
            local rim_z_min = border_height * 0.3
            local rim_z_max = border_height + 0.5
            
            local pos = s.position
            local near_x_edge = math.abs(pos[1]) > (self.x - rim_margin)
            local near_y_edge = math.abs(pos[2]) > (self.y - rim_margin)
            local in_rim_zone = pos[3] > rim_z_min and pos[3] < rim_z_max
            
            if in_rim_zone and (near_x_edge or near_y_edge) then
              local push_strength = 2.0 * sub_dt
              if near_x_edge then
                local dir = pos[1] > 0 and -1 or 1
                s.velocity[1] = s.velocity[1] + dir * push_strength
              end
              if near_y_edge then
                local dir = pos[2] > 0 and -1 or 1
                s.velocity[2] = s.velocity[2] + dir * push_strength
              end
              s.velocity[3] = s.velocity[3] - push_strength * 0.5
              s.asleep = false
              s.sleep_timer = 0
            end
            
            local ld = (s.linear_damping ~= nil) and s.linear_damping or self.linear_damping or 0
            local ad = (s.angular_damping ~= nil) and s.angular_damping or self.angular_damping or 0
            if ld and ld > 0 then
              local vf = 1 - math.min(0.99, ld * sub_dt)
              s.velocity = s.velocity * vf
            end
            if ad and ad > 0 then
              local af = 1 - math.min(0.99, ad * sub_dt)
              s.angular = s.angular * af
            end
            if math.abs(s.angular[3])<0.1 then s.angular[3]=0 end
          end
        else
          s.velocity = vector{0,0,0}
          s.angular = vector{0,0,0}
        end
        
        local v_mag = s.velocity:abs()
        local w_mag = s.angular:abs()
        local sleep_thresh_v = self.sleep_linear or 0.05
        local sleep_thresh_w = self.sleep_angular or 0.15
        local sleep_time = self.sleep_time or 0.4
        local near_ground = s.position[3] < 1.2
        
        if v_mag < sleep_thresh_v and w_mag < sleep_thresh_w and near_ground then
          s.sleep_timer = (s.sleep_timer or 0) + sub_dt
          if s.sleep_timer >= sleep_time and not s.asleep then
            s.asleep = true
            s.velocity = vector{0,0,0}
            s.angular = vector{0,0,0}
            s.wall_hits = 0
          end
        else
          s.sleep_timer = 0
          s.asleep = false
        end
        end -- skip integration on waiting/held body
      end
      
      -- SAT for rotating cubes; swept SAT prevents high-speed pass-through
      -- and contact-point impulses drive rotation. No sphere-only response.
      DieCollisions.solve(self,old_positions,sub_dt,emitted_pairs)
    end -- rotation-aware substeps
    if self.after_step then self:after_step(self.dt) end
    self.timeleft = math.max(0,self.timeleft - self.dt)
    self.simulated_time=(self.simulated_time or 0)+self.dt
    steps = steps + 1
  end
  
  if self.log_buffer and #self.log_buffer > 0 then
    local fh = io.open("physics_log.txt","a")
    if fh then
      for _,line in ipairs(self.log_buffer) do fh:write(line) end
      fh:close()
    end
    table.clear(self.log_buffer)
  end
end

local body={position=vector{}, velocity=vector{}, angular=vector{}, mass=0, theta=0}
function body:set(pos,vel,ang,m,th)
  self.position=vector(pos) or self.position
  self.velocity=vector(vel) or self.velocity
  self.angular=vector(ang) or self.angular
  self.mass=m or self.mass
  self.invMass = (self.mass ~= 0) and (1 / self.mass) or 0
  self.theta=th or self.theta
  local r = 0
  for k=1,#self do r = math.max(r, vector(self[k] or {0,0,0}):abs()) end
  self.radius = r * 0.75
  return self
end

function body:effect(impulse, displacement)
  local dv = vector{0,0,0}
  local da = vector{0,0,0}
  if (self.mass or 0) ~= 0 then
    dv = vector(impulse) / self.mass
  end
  if (self.theta or 0) ~= 0 and displacement then
    da = (displacement ^ impulse) / self.theta
  end
  return dv, da
end

function body:push(impulse, displacement)
  local dv, da = self:effect(impulse, displacement)
  local dv_mag = dv:abs()
  local dv_max = (self.dv_max or box.dv_max or 50)
  if dv_mag > dv_max then
    local t = (love and love.timer and love.timer.getTime()) or os.time()
    local fh = io.open("physics_log.txt","a")
    if fh then
      fh:write(string.format("[ANOMALY] time=%.3f body:push clamped dv=%.3f -> %.3f pos=(%.3f,%.3f,%.3f)\n", t, dv_mag, dv_max, self.position[1], self.position[2], self.position[3]))
      fh:close()
    else
      Logger.debug("[ANOMALY] could not open physics_log.txt to write anomaly")
    end
    dv = dv * (dv_max / dv_mag)
  end
  self.velocity = self.velocity + dv
  self.angular = self.angular + da
end

function body:update(dt)
  self.position=self.position+self.velocity*dt
  local r=rotation():set(self.angular:abs()*dt, self.angular:norm())
  for i=1,#self do self[i]=r(self[i]) end
end


function body:wall(index, normal, restitution, friction)
  local d = self[index]
  local e = (self.restitution ~= nil) and self.restitution or restitution
  local f = (self.friction ~= nil) and self.friction or friction

  local s = normal..(self.angular^d + self.velocity)
  
  if self.asleep and math.abs(s) < 0.05 then
    return
  end
  
  if self.asleep and math.abs(s) >= 0.05 then
    self.asleep = false
    self.sleep_timer = 0
  end
  
  -- Emit the approaching contact speed, never a positional correction.
  -- This callback cannot modify the existing wall impulse calculation.
  if s < -0.001 and self.on_contact then
    self.on_contact(self, normal[3] > 0.5 and "floor" or "rim", -s)
  end

  local cv,ca = self:effect(normal,d)

  local cs = ca^d + cv
  local constraint = (1 + e) * s / (cs..normal)
  
  self.wall_hits = (self.wall_hits or 0) + 1
  if self.wall_hits > 150 then
    self.velocity = self.velocity * 0.2
    self.angular = self.angular * 0.3
    self.wall_hits = 0
  end
  
  local steps = 11
  local impulse = -constraint * normal / steps
  local abs = impulse:abs()
  for i=1,steps do
    self:push(impulse,d)
    local tangent_vel = self.angular^d + self.velocity
    tangent_vel = (tangent_vel - (normal..tangent_vel) * normal)
    self:push(tangent_vel:norm() * f * (-abs), d)
  end
  self._last_wall = {index=index, normal=normal}
end

function body:parallel(normal, min, max, restitution, friction)
  local lowest, highest = nil,nil
  local lowesta, highesta = min,max
  for i=1,#self do
    local a=(self[i]+self.position)..normal
    if a<=lowesta then
      lowest=i 
      lowesta=a
    end
    if a>=highesta then 
      highest=i 
      highesta=a
    end
  end
  
  local penetration_threshold = 0.001
  
  if lowest and (min - lowesta) > penetration_threshold then
    self:wall(lowest,normal,restitution,friction)
    if not self.asleep then
      self.position=self.position+normal*(min-lowesta)
    end
  end
  
  if highest and (highesta - max) > penetration_threshold then
    self:wall(highest,-normal,restitution,friction)
    if not self.asleep then
      self.position=self.position+normal*(max-highesta)
    end
  end
  
end

function body:box(x1,y1,z1,x2,y2,z2,restitution,friction)
  self:parallel(vector{0,0,1},z1,z2,restitution, friction)
  self:parallel(vector{1,0,0},x1,x2,restitution, friction)
  self:parallel(vector{0,1,0},y1,y2,restitution, friction)
end

return {
  box = box,
  body = body,
  materials = materials,
}
