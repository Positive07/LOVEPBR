local cpml   = require "cpml"
local matrix = require "renderer.matrix"
----------------------------
    -- Setup
----------------------------
local renderer = {
    camera = require "renderer/g_camera",
    light  = require "renderer/g_light",
    model  = require "renderer/g_model",

    -- Shaders
    shader = {
        lighting = love.graphics.newShader("shader/3DShader.glsl"),
        shadow   = love.graphics.newShader("shader/3DShadow.glsl"),
        skybox   = love.graphics.newShader("shader/3DSkybox.glsl"),
    },

    -- Skybox
    skybox = {},
}

----------------------------
    -- Main Functions
----------------------------
function renderer:init(scene)
    self.light:init(scene)

    -- Load scene models
    for key, model in pairs(scene["model"]) do
        scene["model"][key] = self.model(model)
    end

    -- load skybox texture
    self.skybox.cubemap = love.graphics.newCubeImage(
        "media/image/" .. scene["skybox"],
        {
            linear = true,
            mipmaps = true,
        }
    )

    -- Build skybox geometry
	local vertices = {
        -- Top
        {-1, -1, 1}, {1, -1, 1},
        {1, 1, 1}, {-1, 1, 1},

        -- Bottom
        {1, -1, -1}, {-1, -1, -1},
        {-1, 1, -1}, {1, 1, -1},

        -- Front
        {-1, -1, -1}, {1, -1, -1},
        {1, -1, 1}, {-1, -1, 1},

        -- Back
        {1, 1, -1}, {-1, 1, -1},
        {-1, 1, 1}, {1, 1, 1},

        -- Right
        {1, -1, -1}, {1, 1, -1},
        {1, 1, 1}, {1, -1, 1},

        -- Left
        {-1, 1, -1}, {-1, -1, -1},
        {-1, -1, 1}, {-1, 1, 1}
	}

    local indices = {
        1, 2, 3, 3, 4, 1,
        5, 6, 7, 7, 8, 5,
        9, 10, 11, 11, 12, 9,
        13, 14, 15, 15, 16, 13,
        17, 18, 19, 19, 20, 17,
        21, 22, 23, 23, 24, 21,
    }

    local layout = {
        {"VertexPosition", "float", 3},
    }

	self.skybox.model = love.graphics.newMesh(layout, vertices, "triangles", "static")
	self.skybox.model:setVertexMap(indices)
end

-- Bake shadow map for a light source
function renderer:bake_shadow_map(scene, light)
    -- Handle shadow data
    light.proj = cpml.mat4.from_ortho(-5, 5, -5, 5, -20, 20)
    light.view = cpml.mat4()
    light.view:look_at(light.view, cpml.vec3(unpack(light.position, 1, 3)), cpml.vec3(0, 0, 0), cpml.vec3(0, -1, 0))
    light.view_proj = light.view * light.proj

    -- Render shadows with front-face culling and enable depth testing (and writing)
    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("less", true)

    -- Send light view and projection matrices to the shadow shader
    self.shader.shadow:send("u_projection", "column", matrix(light.proj))
    self.shader.shadow:send("u_view", "column", matrix(light.view))

    -- Render to depth buffer
    love.graphics.setShader(self.shader.shadow)
    -- TODO: figure out how to render to depth canvas without passing a color canvas
    love.graphics.setCanvas({light.dummy, depthstencil = light.shadow})
    for k, v in pairs(scene.model) do
        v:draw(self.shader.shadow, true)
    end
    love.graphics.setCanvas()
    love.graphics.setShader()

    --Reset CullMode and DepthMode
    love.graphics.setMeshCullMode("none")
    love.graphics.setDepthMode()

    self.shader.lighting:send("shadow_canvas", light.shadow)
    self.shader.lighting:send("u_shadow_vp", "column", matrix(light.view_proj))
end

-- Draw skybox
function renderer:skybox_pass()
    -- Send skybox
    self.camera:send_to_skybox(self.shader.skybox)
    self.shader.skybox:send("skybox", self.skybox.cubemap)

	local m = cpml.mat4():identity()
	self.shader.skybox:send("u_model", "column", matrix(m))

    -- Draw skybox to main canvas
    love.graphics.setCanvas(self.camera.canvas)
    love.graphics.setShader(self.shader.skybox)
    love.graphics.clear()
    love.graphics.draw(self.skybox.model)
    love.graphics.setShader()
    love.graphics.setCanvas()
end

-- Main renderer pass
function renderer:main_pass(scene)
    -- Set main canvas parameters
    love.graphics.setMeshCullMode("back")
    love.graphics.setDepthMode("less", true)

    -- Draw scene to main canvas
    love.graphics.setCanvas(self.camera.canvas)
    love.graphics.setShader(self.shader.lighting)

    for k, v in pairs(scene.model) do
        v:draw(self.shader.lighting)
    end

    love.graphics.setShader()
    love.graphics.setCanvas()

    --Reset CullMode and DepthMode
    love.graphics.setMeshCullMode("none")
    love.graphics.setDepthMode()
end

function renderer:draw(scene)
    -- Send info to shaders
    self.camera:send_to_shader(self.shader.lighting)
    self.light:send_to_shader(self.shader.lighting)

    -- Bake shadows for available lights
    renderer:bake_shadow_map(scene, self.light.directional_light)

    self.shader.lighting:send("shadow_res", cvar.shadow_res)
    self.shader.lighting:send("reflection", self.skybox.cubemap)

    -- Render main canvas
    self:skybox_pass()
    self:main_pass(scene)

    -- Draw main canvas
    love.graphics.draw(self.camera.canvas[1])
end

return renderer