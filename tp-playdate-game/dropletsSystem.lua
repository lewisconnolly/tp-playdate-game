import "droplet"

local gfx <const> = GLOBALS.gfx

class('DropletsSystem').extends()

function DropletsSystem:init()
    DropletsSystem.super.init(self)  
    self.dropletSprites = {}
    self.droplets = {}    
    self.activeDroplets = {}
    --self.dropletAnimators = {}
end

function DropletsSystem:setUp()   
    
    -- Load droplet images
    local droplet1 = gfx.image.new("Images/waterdrop01.png")
    local droplet2 = gfx.image.new("Images/waterdrop02.png")
    self.dropletSprites = { gfx.sprite.new(droplet1), gfx.sprite.new(droplet2) }    

end

function DropletsSystem:getDroplets()
    return self.droplets
end

function DropletsSystem:createDroplet(
    normalizedJerk,
    origDrinkWidth,
    drinkSpriteXScale,
    drinkSpriteYScale,
    drinkSpriteWidth,
    drinkSpriteHeight,
    drinkSpriteXPos,
    drinkSpriteYPos,
    numDroplets
)
    
    local dropletSpawnPoint = {}
    local dropletArcEndAngle = 0
    local dropletBaseSpawnX = 0
    local dropletArcRadius = 0
    local clockwise = false
    local dropletSpawnYOffset = 0
    local dropletScaleModifier = 0.0

    -- Using width of drink sprite, scale based on current scale and add randomisation to arc radius 
    dropletArcRadius = origDrinkWidth * drinkSpriteXScale + math.random(0, math.floor(drinkSpriteWidth / 4))
    -- Set spawn point near mouth of glass, giving each droplet a random position within its own section
    -- to achieve a random but even distribution of droplets
    dropletBaseSpawnX = drinkSpriteXPos - origDrinkWidth / 2 + origDrinkWidth / numDroplets * (numDroplets - i - 1)
    dropletSpawnPoint.x = dropletBaseSpawnX + math.random(0, math.floor(origDrinkWidth / numDroplets))
    -- Set spawn point y position to be at the mouth of the glass, at the centre of the circle described by the arc radius        
    dropletSpawnYOffset = -(drinkSpriteHeight / 2) + dropletArcRadius    
    dropletSpawnPoint.y = drinkSpriteYPos + dropletSpawnYOffset
    -- Randomise size of droplets but more jerk should mean larger droplets
    dropletScaleModifier = math.random() * normalizedJerk
                
    -- Randomise direction droplet arc will take
    if math.random(0, 1) == 0 then clockwise = false else clockwise = true end
    
    -- Choose where droplet will land based on direction of arc and segements of circle described by angles
    if clockwise then
        dropletArcEndAngle = math.random(100, 125) 
    else
        dropletArcEndAngle = math.random(200, 245)
    end
    
    -- Create new droplet
    local dropletSprite = gfx.sprite.new()
    dropletSprite:setImage(self.dropletSprites[1]:getImage())

    local droplet = Droplet(
        dropletSprite,    
        dropletSpawnPoint,
        dropletArcRadius,
        dropletArcEndAngle,
        clockwise,
        dropletScaleModifier
    )

    droplet:setUp(drinkSpriteXScale, drinkSpriteYScale)
    --self.dropletAnimators[#self.dropletAnimators+1] = droplet:getAnimator()    
    self.droplets[#self.droplets+1] = droplet
    self.activeDroplets[#self.activeDroplets+1] = {sprite = droplet.sprite, arc = droplet.arc}    
end

function DropletsSystem:dryDroplets()
     
    -- Check spawned droplets are at end of arcs
     local count = #self.activeDroplets
     if count > 0 then
         for i = count, 1, -1 do
            -- Get end of arc for current droplet
            local arcEndPoint = self.activeDroplets[i]:getArc():pointOnArc(10000, false) -- Distance a very large number and extend false to get endpoint
            -- Get droplet position
            local dropletXPos, dropletYPos = self.activeDroplets[i]:getSprite():getPosition()
            
            -- If droplet at end of arc set z-index of droplet sprite lower than drink's
            if math.floor(dropletXPos) == math.floor(arcEndPoint.x) and math.floor(dropletYPos) == math.floor(arcEndPoint.y) then
                self.activeDroplets[i]:setSpriteZIndex(1)
            end            
         end
     end
end