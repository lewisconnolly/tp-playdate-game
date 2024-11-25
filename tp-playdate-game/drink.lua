local gfx <const> = GLOBALS.gfx

class('Drink').extends()

function Drink:init(fillAmount, stability, startScale, finishScale, startY, finishY, finalTargetPosition)
    Drink.super.init(self)  
    self.sprite = nil
    self.animationLoopWobble = nil
    self.dropletSprites = { }
    self.fillAmount = fillAmount
    self.stability = stability
    self.startScale = startScale
    self.finishScale = finishScale
    self.startY = startY
    self.finishY = finishY
    self.finalTargetPosition = finalTargetPosition
    self.spillThreshold = stability * (1 / fillAmount) -- Inversely proportional to fillAmount
    self.tipThreshold = stability * fillAmount -- Proportional to fillAmount
end

function Drink:setUp()
    
    -- Create sprite and animation loop
    local wobbleFrameTime = 330 -- Each frame of the animation will last 500ms
    local drinkWobbleAnimationImagetable = gfx.imagetable.new("Images/glassWobbleAnim")
    assert( drinkWobbleAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local drinkWobbleAnimationLoop = gfx.animation.loop.new(wobbleFrameTime, drinkWobbleAnimationImagetable, true)    
    -- Set sprite image to first frame of the animation
    local drinkSprite = gfx.sprite.new(drinkWobbleAnimationLoop:image())    

    -- Create droplet sprites
    local droplet1 = gfx.image.new("Images/waterdrop01.png")
    local droplet2 = gfx.image.new("Images/waterdrop02.png")
    local dropletSprites = { gfx.sprite.new(droplet1), gfx.sprite.new(droplet2) }

    -- Create object    
    self.sprite = drinkSprite
    self.animationLoopWobble = drinkWobbleAnimationLoop
    self.dropletSprites = dropletSprites

    -- Modify sprite and animation loop
    self.sprite:setZIndex(-1)
    self.sprite:setScale(self.startScale)
    self.sprite:moveTo( 200, self.startY )
    self.sprite:add()
    self.animationLoopWobble.paused = true -- Don't loop until wobble detected    
    self.sprite.update = function() -- Make sprite update function wobble loop animation
        self.sprite:setImage(self.animationLoopWobble:image())
        -- Optionally, removing the sprite when the animation finished
        if not self.animationLoopWobble:isValid() then
            self.sprite:remove()
        end
    end
end

function Drink:move(crankTicks, trackInstance, horizonPcnt)
    
    -- Drink position variables
    local drinkXPos, drinkYPos = self.sprite:getPosition()
    local targetScale = 0
    local baseTargetPos = 0
    local distToMove = 0
    local differenceFromPrevFrame = 0

    -- Move drink in front of track if past horizon point
    if not trackInstance.isLongTrack then
        self.sprite:setZIndex(2)
    end

    -- If crank has been turned and drink is not at the finish line
    if crankTicks >= 1 and drinkYPos < self.finishY then        
        
        -- Scale drink proportional to remaining track
        targetScale = self.startScale + (1.0 - trackInstance.length) * (self.finishScale - self.startScale)
        self.sprite:setScale(targetScale, targetScale)
        
        -- After track reaches 'horizon', begin moving drink towards screen
        if trackInstance.length < horizonPcnt then        
            
            -- After passing horizon, move drink by the percentage of track that has passed the horizon point towards the finish line
            drinkXPos, drinkYPos = self.sprite:getPosition()                     
            baseTargetPos = self.startY + (1.0 - (trackInstance.length / horizonPcnt)) * (self.finishY - self.startY)
            
            -- Get difference between new and old target positions in case previous position further ahead than new position
            if baseTargetPos - self.finalTargetPosition < 0 then
                differenceFromPrevFrame = math.abs(self.finalTargetPosition - baseTargetPos)
            end
            
            -- Increase position by base target + difference
            self.finalTargetPosition =  baseTargetPos + differenceFromPrevFrame
            distToMove = self.finalTargetPosition - drinkYPos
            
            -- If distance to move is negative or past the finish line then move to finish line
            if (distToMove >= 0 and drinkYPos + distToMove <= self.finishY) then
                self.sprite:moveBy( 0, distToMove ) 
            else
                self.sprite:moveBy( 0, self.finishY - drinkYPos )
            end                            
        end
    elseif crankTicks <= -1 then

    end
end

function Drink:checkSpill(crankAccelSmpl1, crankAccelSmpl2)
    
    -- Only check spill if not at finish line
    local drinkXPos, drinkYPos = self.sprite:getPosition()

    if drinkYPos >= self.finishY then
        return
    end

    local delay = 0
    local animationTimer

    function stopWobbleAnimation()
            
        -- Stop animation and set to upright frame
        self.animationLoopWobble.paused = true
        self.animationLoopWobble.frame = 1
        self.sprite:setImage(self.animationLoopWobble:image())
    end

    -- Calculate jerk (difference in acceleration between frames) to handle acceleration and deceleration
    local jerk = math.abs(crankAccelSmpl1 - crankAccelSmpl2)

    if jerk > 0 then
        -- Max value can be derived from max crank change multiplied by acceleration formula
        -- 359.9999 * (1.0 / (0.2 + math.pow(1.04, -math.abs(359.9999) + 20.0))))
        -- But that is far too large (1799.985) in reality so is limited to half the max angle change
        -- Negative values not used so minimum is 0
        -- Normalized because spill threshold is between 0 and 1
        -- https://devforum.play.date/t/acceleratedchange-in-c-sdk/6992/4
        local normalizedJerk = GLOBALS.normalize(jerk, 0, 180)

        -- If acceleration greater than threshold then wobble drink
        if normalizedJerk > self.spillThreshold then
            -- Create timer to play all frames of animation
            delay = self.animationLoopWobble.delay * -- frame time * num frames + extra frame of lag
                    self.animationLoopWobble.endFrame +
                    self.animationLoopWobble.delay 
            if animationTimer ~= nil then animationTimer:reset() -- Reset timer if already created
            else animationTimer = playdate.timer.performAfterDelay(delay, stopWobbleAnimation) end -- Create timer
            if self.animationLoopWobble.paused then self.animationLoopWobble.paused = false end -- Play animation

            self:createSpill()
        end
    end
end

function Drink:createSpill()
    
    local drinkXPos, drinkYPos = self.sprite:getPosition()    
    
    local arc = playdate.geometry.arc.new(drinkXPos, drinkYPos, 5, 0, 90, true)

    local point = arc:pointOnArc(2, true)

    self.dropletSprites[1]:setZIndex(3)
    self.dropletSprites[1]:setScale(1.0)
    self.dropletSprites[1]:moveTo( point.x, point.y )
    self.dropletSprites[1]:add()
end