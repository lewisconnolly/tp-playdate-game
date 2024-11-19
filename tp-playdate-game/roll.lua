class('Roll').extends()

function Roll:init(sprite, animationLoop)
    Roll.super.init(self)
    self.sprite = sprite
    self.animationLoop = animationLoop
end