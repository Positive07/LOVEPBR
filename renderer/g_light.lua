----------------------------
    -- Lighting World
----------------------------
local light = {
    directional_light = {},
}

----------------------------
    -- Light Source Functions
----------------------------
function light:init(scene)
    local l = self.directional_light
    local res = cvar.shadow_res

    -- Reset light tables
    l.position = scene["directional_light"].position or {0, 0, 0}
    l.color    = scene["directional_light"].color or {1, 1, 1, 1}
    l.shadow   = love.graphics.newCanvas(res, res, {format = "depth24", readable = true})
    l.shadow:setDepthSampleMode("less")
    l.shadow:setFilter("linear", "linear")
end

----------------------------
    -- Main Functions
----------------------------
function light:send_to_shader(shader)
    -- Send directional light data
    shader:send("directional_light", self.directional_light.position)
    shader:send("directional_color", self.directional_light.color)
end

return light