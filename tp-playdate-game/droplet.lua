local gfx <const> = GLOBALS.gfx

class('Droplet').extends()

function Droplet:init(        
        sprite,
        spawnPoint,
        arcRadius,
        arcEndAngle,
        clockwise,
        scaleModifier
    )
    Droplet.super.init(self)  
    self.sprite = sprite
    self.arc = playdate.geometry.arc.new(spawnPoint.x, spawnPoint.y, arcRadius, 0, arcEndAngle, clockwise)
    self.arcEndpoint = arc:pointOnArc(10000, false) -- Distance a very large number and extend false to get endpoint    
    self.scaleModifier = scaleModifier
    self.animator = nil
end

-- Create droplet sprite and animator
function Droplet:setUp(drinkXScale, drinkYScale)
    
        
    -- If arc endpoint is above table then adjust arc to end at the edge of table
    if (self.arcEndpoint.y < 70) then
        self.arc = playdate.geometry.arc.new(self.arc.x, self.arc.y + 70 - self.arcEndpoint.y, self.arc.radius, 0, self.arc.endAngle, self.arc.clockwise)
    end

    -- Scale droplet based on current drink scale and random modifier
    local dropletXScale, dropletYScale = drinkXScale, drinkYScale
    dropletXScale = dropletXScale * drinkXScale * self.scaleModifier
    dropletYScale = dropletYScale * drinkYScale * self.scaleModifier
    
    -- Create animator for droplet
    -- 1000 is the duration of the animation in milliseconds
    -- playdate.easingFunctions.linear is the easing function to use for the animation
    self.animator = playdate.graphics.animator.new(1000, self.arc, playdate.easingFunctions.linear)
    self.animator.repeatCount = 0
    
    -- Draw droplets        
    self.sprite:setZIndex(3)
    self.sprite:setScale(dropletXScale, dropletYScale)
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

function Droplet:setSpriteZIndex(zIndex)
    self.sprite:setZIndex(zIndex)
end