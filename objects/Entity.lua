-- base class for player, enemy and spell classes
Entity = Object:extend()


function Entity:new(x, y, speed, scale, hitbox)
    self.x = x or 0
    self.y = y or 0
    self.speed = speed or 100
    self.spriteScale = scale or 1
    self.hitboxRadius = (hitbox * self.spriteScale) or (5 * self.spriteScale)
end