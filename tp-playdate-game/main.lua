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
local deltaTime = 0
local horizonPcnt = 0.6
local finishY = 180
local startY = 60
local finishScale = 2.0
local startScale = 0.5
local drinkInstance = nil
local trackInstance = nil
local rollInstance = nil

function myGameSetUp()

    -- Set up drink object

    local drinkImage = gfx.image.new("Images/glass0.png")
    assert( drinkImage ) -- make sure the image was where we thought

    local drinkSprite = gfx.sprite.new( drinkImage )    
    drinkSprite:setZIndex(-1)
    drinkSprite:setScale(startScale)

    drinkInstance = Drink(drinkSprite, 0.9, 0.75)    
    
    drinkInstance.sprite:moveTo( 200, startY ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    drinkInstance.sprite:add() -- This is critical!

    -- Set up track object

    -- Each frame of the animation will last 200ms
    local frameTime = 200
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLine")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, true)
    trackAnimationLoop.paused = true
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())
    trackAnimatedSprite:setZIndex(1)

    -- Move track sprite to screen position
    trackAnimatedSprite:moveTo( 200, 120 )
    -- Add sprite to display list
    trackAnimatedSprite:add()

    -- Make sprite update function loop animation
    trackAnimatedSprite.update = function()
        trackAnimatedSprite:setImage(trackAnimationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not trackAnimationLoop:isValid() then
            trackAnimatedSprite:remove()
        end
    end    

    -- Create object
    trackInstance = Track(trackAnimatedSprite, trackAnimationLoop, 0.5, 0.25, 0.5)

    -- Set up roll object

    local rollImage = gfx.image.new("Images/tprollStatic.png")
    assert( rollImage )
    
    local rollSprite = gfx.sprite.new( rollImage )
    rollSprite:setZIndex(3)

    rollInstance = Roll(rollSprite)

    rollInstance.sprite:moveTo( 200, 120 )
    rollInstance.sprite:add()

    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new( "Images/bg1.png" )
    assert( backgroundImage )

    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw( 0, 0 )
        end
    )

end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

function playdate.update()
    
    -- Get time since last freme
    deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()
    
    -- Poll the d-pad and move our player accordingly.
    -- (There are multiple ways to read the d-pad; this is the simplest.)
    -- Note that it is possible for more than one of these directions
    -- to be pressed at once, if the user is pressing diagonally.

    -- Crank movement
    getCrankInput()

    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)
    gfx.sprite.update()
    playdate.timer.updateTimers()

end

function getCrankInput()
    
    local ticksPerRevolution = 360
    local crankTicks = playdate.getCrankTicks(ticksPerRevolution)
    
    local xPos, yPos = drinkInstance.sprite:getPosition()
    local currentTrackLength = trackInstance.length

    -- If crank has been turned and drink is not at the finish line
    if crankTicks >= 1 then        
        if yPos <= finishY then            
            -- Play track looping animation before track reaches horizon
            if trackInstance.isLongTrack then
                trackInstance.animationLoop.paused = false
            else
                trackInstance.animationLoop.paused = true
            end
            
            -- Decrease track length percentage of distance to simulate winding in
            trackInstance.length -= crankTicks / 1000
            
            -- Scale drink proportional to remaining track (get larger quicker as it moves towards screen to simulate perspective)
            local targetScale = startScale + (1.0 - (trackInstance.length / 1.0)) * (finishScale - startScale)                        
            drinkInstance.sprite:setScale(targetScale, targetScale)
            
            -- After track reaches 'horizon', begin moving drink towards screen
            if trackInstance.length < horizonPcnt then        
                -- Swap from looping animation to components animation
                if trackInstance.isLongTrack then
                    swapTrack()
                    drinkInstance.sprite:setZIndex(2)
                    trackInstance.isLongTrack = false
                end
                -- After passing horizon, move drink by  the percentage of track that has passed the horizon point towards the finish y-position
                local targetPos = startY + (1.0 - (trackInstance.length / horizonPcnt)) * (finishY - startY)
                local xPos, yPos = drinkInstance.sprite:getPosition()
                local distToMove = targetPos - yPos
                drinkInstance.sprite:moveBy( 0, distToMove ) 
                
                -- Change frame of track animation based on percentage of track remaining
                local pcntAlongVisibleTrack = 1.0 - (trackInstance.length / horizonPcnt)
                local matchingAnimFrame = math.floor(pcntAlongVisibleTrack * trackInstance.animationLoop.endFrame) -- endFrame returns total frames
                trackInstance.animationLoop.frame = matchingAnimFrame
                trackInstance.sprite:setImage(trackInstance.animationLoop:image())
                print(matchingAnimFrame)                                 
            end
        end        
    elseif crankTicks <= -1 then

    else
        -- Stop track looping animation
        trackInstance.animationLoop.paused = true
    end
end

function swapTrack()
    trackInstance.sprite:remove()
    
    -- Each frame of the animation will last 200ms
    local frameTime = 200
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLineAnim")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, false)
    trackAnimationLoop.paused = true
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())
    trackAnimatedSprite:setZIndex(1)

    -- Move track sprite to scren position
    trackAnimatedSprite:moveTo( 200, 120 )
    -- Add sprite to display list
    trackAnimatedSprite:add()

    trackAnimatedSprite.update = function()
        trackAnimatedSprite:setImage(trackAnimationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not trackAnimationLoop:isValid() then
            trackAnimatedSprite:remove()
        end
    end
    
    trackInstance.sprite = trackAnimatedSprite
    trackInstance.animationLoop = trackAnimationLoop
end
