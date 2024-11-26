GLOBALS = import "global"
import "drink"
import "track"
import "roll"

local gfx <const> = GLOBALS.gfx

--local deltaTime = 0
local horizonPcnt = 0.5 -- Percentage of track before the horizon
local absoluteTrackLength = 10000 -- Used to divide crank ticks by, resulting in more turns required to wind in track fully
local drinkFinishY = 180 -- Finish line y-coord for drink
local drinkStartY = 67 -- Starting y-coord of drink
local drinkFinishScale = 2.0 -- Scale of drink at finish line
local drinkStartScale = 0.5 -- Scale of drink at starting position
local finalDrinkTargetPos = 0 -- The target position of the drink based on crank input at the end of each frame
local crankTicks = 0 -- Store crank ticks
local crankAccelStartOfFrame = 0 -- Store crank acceleration
local crankAccelEndOfFrame = 0 -- Store crank acceleration

-- Game properties
local drinkFillAmount = 0.9
local drinkStability = 0.5
local trackStrength = 0.5
local trackRoughness = 0.25
local trackAbsorbency = 0.5

-- Game objects
local drink = nil
local track = nil
local roll = nil

function setUpBackground()
    
    -- Load bg image
    local backgroundImage = gfx.image.new( "Images/bg1.png" )
    assert( backgroundImage )

    -- setBackgroundDrawingCallback() to draw a background image
    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw( 0, 0 )
        end
    )
end

function getCrankTicks()
    
    -- Crank input variables
    local ticksPerRevolution = 360
    
    return playdate.getCrankTicks(ticksPerRevolution)
end

function getCrankAcceleration()    
    
    local change, acceleratedChange = playdate.getCrankChange()

    return acceleratedChange
end

function resetGame()    
    
    -- Remove all sprites
    gfx.sprite.removeAll()

    myGameSetUp()
end

function gameObjectsSetUp()
    
    -- Drink
    drink = Drink(drinkFillAmount, drinkStability, drinkStartScale, drinkFinishScale, drinkStartY, drinkFinishY, finalDrinkTargetPos)
    drink:setUp()

    -- Track
    track = Track(trackStrength, trackRoughness, trackAbsorbency)
    track:setUp()

    -- Roll
    roll = Roll()
    roll:setUp()

end

function getCrankInput()
    return getCrankTicks(), getCrankAcceleration()
end

function myGameSetUp()    
    
    gameObjectsSetUp()    
    setUpBackground()
end

-- Configure game
myGameSetUp()

-- Called by the OS 30 times every second, runs game logic and moves sprites
function playdate.update()
    
    if drink == nil then
        error("drink object is nil", 2)
    end

    if track == nil then
        error("track object is nil", 2)
    end

    if roll == nil then
        error("roll object is nil", 2)
    end
    
    -- Get time since last freme
    --deltaTime = playdate.getElapsedTime()
    --playdate.resetElapsedTime()
    
    -- Move track and drink based on polled crank input
    crankTicks, crankAccelStartOfFrame = getCrankInput()
    roll:animate(crankTicks, drink)
    track:move(crankTicks, drink, absoluteTrackLength, horizonPcnt)    
    drink:move(crankTicks, track, horizonPcnt)
    drink:checkSpill(crankAccelStartOfFrame, crankAccelEndOfFrame)

    -- Measure acceleration twice to calculate change in acceleration between frames    
    crankAccelEndOfFrame = getCrankAcceleration()

    -- Reset game
    if playdate.buttonIsPressed( playdate.kButtonA ) then
        resetGame()
    end

    -- Draw sprites and update timers
    gfx.sprite.update()
    playdate.timer.updateTimers()
end





