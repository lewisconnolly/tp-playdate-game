local gfx <const> = GLOBALS.gfx

class('Droplet').extends()

function Droplet:init(        
        sprite,
        spawnPoint,
        arcRadius,
        arcEndAngle,
        clockwise,
        dropletXScale,
        dropletYScale
    )
    Droplet.super.init(self)  
    self.sprite = sprite
    self.spriteXScale = dropletXScale
    self.spriteYScale = dropletYScale
    self.arc = playdate.geometry.arc.new(spawnPoint.x, spawnPoint.y, arcRadius, 0, arcEndAngle, clockwise)
    self.arcEndpoint = self.arc:pointOnArc(10000, false) -- Distance a very large number and extend false to get endpoint    
    self.animator = nil
    self.spillSprite = nil
    self.spillAnimationLoop = nil

    -- If arc endpoint is above table then adjust arc to end at the edge of table
    if (self.arcEndpoint.y < 70) then
        self.arc = playdate.geometry.arc.new(self.arc.x, self.arc.y + 70 - self.arcEndpoint.y, self.arc.radius, 0, self.arc.endAngle, self.arc.clockwise)
    end
    
    -- Create animator for droplet
    -- 1000 is the duration of the animation in milliseconds
    -- playdate.easingFunctions.linear is the easing function to use for the animation
    self.animator = playdate.graphics.animator.new(1000, self.arc, playdate.easingFunctions.linear)
    self.animator.repeatCount = 0
    
    -- Create spill animation
    local frameTime = 200 -- Each frame of the animation will last 200ms
    local spillAnimationImagetable = gfx.imagetable.new("Images/spill1")
    assert( spillAnimationImagetable ) -- make sure the images were where we thought
    -- Setting the last argument to false makes the animation stop on the last frame
    local spillAnimationLoop = gfx.animation.loop.new(frameTime, spillAnimationImagetable, false)    
    -- Set sprite image to first frame of the animation
    self.spillSprite = gfx.sprite.new(spillAnimationLoop:image())
    self.spillAnimationLoop = spillAnimationLoop    

    -- Draw droplets        
    self.sprite:setZIndex(3)
    self.sprite:setScale(self.spriteXScale, self.spriteYScale)
    self.sprite:moveTo( self.arc.x, self.arc.y )
    self.sprite:add()
    
    self.sprite:setAnimator(self.animator)    
end

function Droplet:dry()
    -- Modify sprite and animation loop
    local spillPosX, spillPosY = self.sprite:getPosition()
    self.sprite:remove() -- Remove droplet sprite
    self.spillSprite:setScale(self.spriteXScale, self.spriteYScale)
    self.spillSprite:setZIndex(1)
    self.spillSprite:moveTo( spillPosX, spillPosY )
    self.spillSprite:add()
    self.spillAnimationLoop.paused = false -- Play through once   
    self.spillSprite.update = function() -- Make spill sprite update function loop animation
        self.spillSprite:setImage(self.spillAnimationLoop:image())
        -- Remove spill sprite when animation finished
        if not self.spillAnimationLoop:isValid() then
            self.spillSprite:remove()
        end
    end
end

function Droplet:getAnimator()
    return self.animator
end

function Droplet:getArc()
    return self.arc
end

function Droplet:getSprite()
    return self.sprite
end

function Droplet:getSpriteScale()
    return self.sprite:getScale()  
end

function Droplet:getSpritePosition()
    return self.sprite:getPosition()  
end