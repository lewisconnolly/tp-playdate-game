import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "drink.lua"
import "track.lua"
import "roll.lua"

local gfx <const> = playdate.graphics
--local deltaTime = 0
local horizonPcnt = 0.6 -- Percentage of track before the horizon
local finishY = 180 -- Finish line y-coord for drink
local startY = 67 -- Starting y-coord of drink
local finishScale = 2.0 -- Scale of drink at finish line
local startScale = 0.5 -- Scale of drink at starting position
local finalDrinkTargetPos = 0 -- The target position of the drink based on crank input at the end of each frame
local crankTicks = 0 -- Store crank ticks

-- Game objects
local drinkInstance = nil
local trackInstance = nil
local rollInstance = nil

function setUpDrink()
    
    -- Create sprite
    local drinkImage = gfx.image.new("Images/glass0.png")
    assert( drinkImage ) -- make sure the image was where we thought

    local drinkSprite = gfx.sprite.new( drinkImage )    
    
    -- Creat object
    drinkInstance = Drink(drinkSprite, 0.9, 0.75)    

    -- Modify sprite
    drinkInstance.sprite:setZIndex(-1)
    drinkInstance.sprite:setScale(startScale)
    drinkInstance.sprite:moveTo( 200, startY )
    drinkInstance.sprite:add()
end

function setUpTrack()

    -- Create sprite and animation loop
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLine")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, true)    
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())    

    -- Create object
    trackInstance = Track(trackAnimatedSprite, trackAnimationLoop, 0.5, 0.25, 0.5)

    -- Modify sprite and animation loop
    trackInstance.sprite:setZIndex(1)
    trackInstance.sprite:moveTo( 200, 120 )
    trackInstance.sprite:add()
    trackInstance.animationLoop.paused = true -- Don't loop until crank input detected    
    trackInstance.sprite.update = function() -- Make sprite update function loop animation
        trackInstance.sprite:setImage(trackInstance.animationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not trackInstance.animationLoop:isValid() then
            trackInstance.sprite:remove()
        end
    end
end

function setUpRoll()

    -- Create sprite and animation loop
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local rollAnimationImagetable = gfx.imagetable.new("Images/tprollAnim")
    assert( rollAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local rollAnimationLoop = gfx.animation.loop.new(frameTime, rollAnimationImagetable, true)    
    -- Set sprite image to first frame of the animation
    local rollAnimatedSprite = gfx.sprite.new(rollAnimationLoop:image())    

    -- Create object
    rollInstance = Roll(rollAnimatedSprite, rollAnimationLoop)

    -- Modify sprite and animation loop
    rollInstance.sprite:setZIndex(3)
    rollInstance.sprite:moveTo( 200, 120 )
    rollInstance.sprite:add()
    rollInstance.animationLoop.paused = true -- Don't loop until crank input detected    
    rollInstance.sprite.update = function() -- Make sprite update function loop animation
        rollInstance.sprite:setImage(rollInstance.animationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not rollInstance.animationLoop:isValid() then
            rollInstance.sprite:remove()
        end
    end
end

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

function moveTrack(crankTicks)
     
    if drinkInstance == nil then
        error("drinkInstance is nil", 2)
    end

    if trackInstance == nil then
        error("trackInstance is nil", 2)
    end

    -- Drink position variables
     local drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()
    
    -- Track animation variables
    local pcntAlongVisibleTrack = 0
    local matchingAnimFrame = 0

    -- If crank has been turned and drink is not at the finish line
    if crankTicks >= 1 and drinkYPos < finishY then         
        
        -- Play track looping animation before track reaches horizon
        if trackInstance.isLongTrack then
            trackInstance.animationLoop.paused = false
        else
            trackInstance.animationLoop.paused = true
        end

         -- Decrease track length
         trackInstance.length -= crankTicks / 1000

          -- After track reaches 'horizon', begin moving drink towards screen
        if trackInstance.length < horizonPcnt then        
            -- Swap from looping animation to segmented animation
            if trackInstance.isLongTrack then
                swapTrack()
                drinkInstance.sprite:setZIndex(2)
                trackInstance.isLongTrack = false
            end
            
            -- Change frame of track animation based on percentage of track remaining
            pcntAlongVisibleTrack = 1.0 - (trackInstance.length / horizonPcnt)
            -- endFrame returns total frames
            -- Add lag to track animation based on percentage of track travelled to stop track outpacing drink
            matchingAnimFrame = math.floor(pcntAlongVisibleTrack * trackInstance.animationLoop.endFrame) - math.ceil(pcntAlongVisibleTrack * 10) 
            trackInstance.animationLoop.frame = math.max(0, matchingAnimFrame)
            trackInstance.sprite:setImage(trackInstance.animationLoop:image())
        end
    elseif crankTicks <= -1 then

    else
        -- Stop track looping animation
        trackInstance.animationLoop.paused = true
    end
end

function moveDrink(crankTicks)
    
    if drinkInstance == nil then
        error("drinkInstance is nil", 2)
    end

    if trackInstance == nil then
        error("trackInstance is nil", 2)
    end

    -- Drink position variables
    local drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()
    local targetScale = 0
    local baseTargetPos = 0
    local distToMove = 0
    local differenceFromPrevFrame = 0

    -- If crank has been turned and drink is not at the finish line
    if crankTicks >= 1 and drinkYPos < finishY then        
        
        -- Scale drink proportional to remaining track
        targetScale = startScale + (1.0 - trackInstance.length) * (finishScale - startScale)
        drinkInstance.sprite:setScale(targetScale, targetScale)
        
        -- After track reaches 'horizon', begin moving drink towards screen
        if trackInstance.length < horizonPcnt then        
            
            -- After passing horizon, move drink by the percentage of track that has passed the horizon point towards the finish line
            drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()                     
            baseTargetPos = startY + (1.0 - (trackInstance.length / horizonPcnt)) * (finishY - startY)
            
            -- Get difference between new and old target positions in case previous position further ahead than new position
            if baseTargetPos - finalDrinkTargetPos < 0 then
                differenceFromPrevFrame = math.abs(finalDrinkTargetPos - baseTargetPos)
            end
            
            -- Increase position by base target + difference
            finalDrinkTargetPos =  baseTargetPos + differenceFromPrevFrame
            distToMove = finalDrinkTargetPos - drinkYPos
            
            -- If distance to move is negative or past the finish line then move to finish line
            if (distToMove >= 0 and drinkYPos + distToMove <= finishY) then
                drinkInstance.sprite:moveBy( 0, distToMove ) 
            else
                drinkInstance.sprite:moveBy( 0, finishY - drinkYPos )
            end                            
        end
    elseif crankTicks <= -1 then

    end
end

function animateRoll(crankTicks)
    
    if drinkInstance == nil then
        error("drinkInstance is nil", 2)
    end

    if rollInstance == nil then
        error("rollInstance is nil", 2)
    end

    -- Drink position variables
    local drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()
    
    if crankTicks >= 1 and drinkYPos < finishY then         
        -- Play roll looping animation        
        rollInstance.animationLoop.paused = false 
    else
         -- Stop roll looping animation        
        rollInstance.animationLoop.paused = true
    end
end

function swapTrack()        
        
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLineAnim")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, false)
    trackAnimationLoop.paused = true -- Animation should not loop automatically
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())
    
    if trackInstance ~= nil then
        
        -- Update track object        
        trackInstance.sprite:remove() -- Remove sprite from looping animation
        trackInstance.sprite = trackAnimatedSprite
        trackInstance.animationLoop = trackAnimationLoop
        
        -- Modify sprite
        trackInstance.sprite:setZIndex(1)
        trackInstance.sprite:moveTo( 200, 120 )
        trackInstance.sprite:add()    
        trackInstance.sprite.update = function() -- Make sprite update function loop animation
            trackInstance.sprite:setImage(trackInstance.animationLoop:image())
            -- Optionally, removing the sprite when the animation finished
            if not trackInstance.animationLoop:isValid() then
                trackInstance.sprite:remove()
            end
        end
    else
        error("trackInstance is nil", 2)
    end
end

function resetGame()    
    
    -- Reset drink
    if drinkInstance ~= nil then drinkInstance.sprite:remove() end
    finalDrinkTargetPos = 0
    -- Reset track
    if trackInstance ~= nil then trackInstance.sprite:remove() end
    -- Reset roll
    if rollInstance ~= nil then rollInstance.sprite:remove() end
        
    myGameSetUp()
end

function myGameSetUp()    
    
    setUpDrink()
    setUpTrack()
    setUpRoll()
    setUpBackground()
end

-- Configure game
myGameSetUp()

-- Called by the OS 30 times every second, runs game logic and moves sprites
function playdate.update()
    
    -- Get time since last freme
    --deltaTime = playdate.getElapsedTime()
    --playdate.resetElapsedTime()
    
    -- Move track and drink based on polled crank input
    crankTicks = getCrankTicks()    
    animateRoll(crankTicks)
    moveTrack(crankTicks)
    moveDrink(crankTicks)

    -- Reset game
    if playdate.buttonIsPressed( playdate.kButtonA ) then
        resetGame()
    end

    -- Draw sprites and update timers
    gfx.sprite.update()
    playdate.timer.updateTimers()
end





