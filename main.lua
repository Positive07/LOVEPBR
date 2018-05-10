----------------------------
    -- Initialization
----------------------------
-- Require modules
local scene    = require "scene"
local renderer = require "renderer"

----------------------------
    -- Main Functions
----------------------------
function love.load()
    -- Load scene data ont renderer
    renderer:init(scene)
end

function love.draw()
    -- Clear last frame
    love.graphics.push("all")

    -- Draw scene
    renderer:draw(scene)

    -- Display frame
    love.graphics.pop()
end