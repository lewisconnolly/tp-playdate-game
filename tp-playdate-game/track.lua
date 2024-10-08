class('Track').extends()

function Track:init(strength, roughness, absorbency)
    Track.super.init(self)  
    self.strength = strength
    self.roughness = roughness
    self.absorbency = absorbency
    self.turgidity = 0.001; -- Track starts dry
    self.tearThreshold = strength * (1 / turgidity) -- Inversely proportional to turgidity (wetter = easier to tear)
    self.slipThreshold = roughness * turgidity -- Proportional to turgidity (wetter = harder to slip)
end