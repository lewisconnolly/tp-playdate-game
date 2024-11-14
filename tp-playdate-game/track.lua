class('Track').extends()

function Track:init(sprite, animationLoop, strength, roughness, absorbency)
    Track.super.init(self)  
    self.sprite = sprite  
    self.animationLoop = animationLoop
    self.isLongTrack = true
    self.strength = strength
    self.roughness = roughness
    self.absorbency = absorbency
    self.length = 1.0
    self.wetness = 0.001 -- Track starts dry
    self.tearThreshold = strength * (1 / self.wetness) -- Inversely proportional to wetness (wetter = easier to tear)
    self.slipThreshold = roughness * self.wetness -- Proportional to turgidity (wetter = harder to slip)
end