local M = {}

-- Libraries
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"    

-- Global references
M.gfx = playdate.graphics

-- Shared functions
function M.normalize(value, min, max)
    return (value - min) / (max - min)
end

return M