local gfx <const> = GLOBALS.gfx

class('Track').extends()

function Track:init(strength, roughness, absorbency)
    Track.super.init(self)  
    self.sprite = nil  
    self.animationLoop = nil
    self.isLongTrack = true
    self.strength = strength
    self.roughness = roughness
    self.absorbency = absorbency
    self.length = 1.0
    self.wetness = 0.001 -- Track starts dry
    self.tearThreshold = strength * (1 / self.wetness) -- Inversely proportional to wetness (wetter = easier to tear)
    self.slipThreshold = roughness * self.wetness -- Proportional to turgidity (wetter = harder to slip)
end

function Track:setUp()

    -- Create sprite and animation loop
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLine")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, true)    
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())    

    -- Create object    
    self.sprite = trackAnimatedSprite
    self.animationLoop = trackAnimationLoop

    -- Modify sprite and animation loop
    self.sprite:setZIndex(1)
    self.sprite:moveTo( 200, 120 )
    self.sprite:add()
    self.animationLoop.paused = true -- Don't loop until crank input detected    
    self.sprite.update = function() -- Make sprite update function loop animation
        self.sprite:setImage(self.animationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not self.animationLoop:isValid() then
            self.sprite:remove()
        end
    end
end

function Track:move(crankTicks, drinkInstance, absoluteTrackLength, horizonPcnt)
     
    -- Drink position variables
     local drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()
    
    -- Track animation variables
    local pcntAlongVisibleTrack = 0
    local matchingAnimFrame = 0

    -- If crank has been turned and drink is not at the finish line
    if crankTicks >= 1 and drinkYPos < drinkInstance.finishY then         
        
        -- Play track looping animation before track reaches horizon
        if self.isLongTrack then
            self.animationLoop.paused = false
        else
            self.animationLoop.paused = true
        end

         -- Decrease track length
         self.length -= crankTicks / absoluteTrackLength

          -- After track reaches 'horizon', begin moving drink towards screen
        if self.length < horizonPcnt then        
            -- Swap from looping animation to segmented animation
            if self.isLongTrack then
                self:swap()
                drinkInstance.sprite:setZIndex(2)
                self.isLongTrack = false
            end
            
            -- Change frame of track animation based on percentage of track remaining
            pcntAlongVisibleTrack = 1.0 - (self.length / horizonPcnt)
            -- endFrame returns total frames
            -- Add lag to track animation based on percentage of track travelled to stop track outpacing drink
            matchingAnimFrame = math.floor(pcntAlongVisibleTrack * self.animationLoop.endFrame) - math.ceil(pcntAlongVisibleTrack * 10) 
            self.animationLoop.frame = math.max(0, matchingAnimFrame)
            self.sprite:setImage(self.animationLoop:image())
        end
    elseif crankTicks <= -1 then

    else
        -- Stop track looping animation
        self.animationLoop.paused = true
    end
end

function Track:swap()        
        
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local trackAnimationImagetable = gfx.imagetable.new("Images/tpLineAnim")
    assert( trackAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local trackAnimationLoop = gfx.animation.loop.new(frameTime, trackAnimationImagetable, false)
    trackAnimationLoop.paused = true -- Animation should not loop automatically
    -- Set sprite image to first frame of the animation
    local trackAnimatedSprite = gfx.sprite.new(trackAnimationLoop:image())
        
    -- Update track object        
    self.sprite:remove() -- Remove sprite from looping animation
    self.sprite = trackAnimatedSprite
    self.animationLoop = trackAnimationLoop
    
    -- Modify sprite
    self.sprite:setZIndex(1)
    self.sprite:moveTo( 200, 120 )
    self.sprite:add()    
    self.sprite.update = function() -- Make sprite update function loop animation
        self.sprite:setImage(self.animationLoop:image())
        -- Optionally, removing the sprite when the animation finished
        if not self.animationLoop:isValid() then
            self.sprite:remove()
        end
    end
end
