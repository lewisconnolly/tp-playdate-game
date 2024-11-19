class('Drink').extends()

function Drink:init(sprite, animationLoopWobble, fillAmount, stability)
    Drink.super.init(self)  
    self.sprite = sprite
    self.animationLoopWobble = animationLoopWobble
    self.fillAmount = fillAmount
    self.stability = stability
    self.spillThreshold = stability * (1 / fillAmount) -- Inversely proportional to fillAmount
    self.tipThreshold = stability * fillAmount -- Proportional to fillAmount
end