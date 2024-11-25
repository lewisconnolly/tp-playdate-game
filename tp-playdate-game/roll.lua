local gfx <const> = GLOBALS.gfx

class('Roll').extends()

function Roll:init()
    Roll.super.init(self)
    self.sprite = nil
    self.animationLoop = nil
end

function Roll:setUp()

    -- Create sprite and animation loop
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local rollAnimationImagetable = gfx.imagetable.new("Images/tprollAnim")
    assert( rollAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local rollAnimationLoop = gfx.animation.loop.new(frameTime, rollAnimationImagetable, true)    
    -- Set sprite image to first frame of the animation
    local rollAnimatedSprite = gfx.sprite.new(rollAnimationLoop:image())    

    -- Create object
    self.sprite = rollAnimatedSprite
    self.animationLoop = rollAnimationLoop

    -- Modify sprite and animation loop
    self.sprite:setZIndex(3)
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

function Roll:animate(crankTicks, drinkInstance)
    
    -- Drink position variables
    local drinkXPos, drinkYPos = drinkInstance.sprite:getPosition()
    
    if crankTicks >= 1 and drinkYPos < drinkInstance.finishY then         
        -- Play roll looping animation        
        self.animationLoop.paused = false 
    else
         -- Stop roll looping animation        
        self.animationLoop.paused = true
    end
end