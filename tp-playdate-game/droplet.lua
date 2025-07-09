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
    self.scaleModifier = scaleModifier
    self.animator = nil

    -- If arc endpoint is above table then adjust arc to end at the edge of table
    if (self.arcEndpoint.y < 70) then
        self.arc = playdate.geometry.arc.new(self.arc.x, self.arc.y + 70 - self.arcEndpoint.y, self.arc.radius, 0, self.arc.endAngle, self.arc.clockwise)
    end
    
    -- Create animator for droplet
    -- 1000 is the duration of the animation in milliseconds
    -- playdate.easingFunctions.linear is the easing function to use for the animation
    self.animator = playdate.graphics.animator.new(1000, self.arc, playdate.easingFunctions.linear)
    self.animator.repeatCount = 0
    
    -- Draw droplets        
    self.sprite:setZIndex(3)
    self.sprite:setScale(self.spriteXScale, self.spriteYScale)
    self.sprite:moveTo( self.arc.x, self.arc.y )
    self.sprite:add()
    
    self.sprite:setAnimator(self.animator)
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