Spell = Entity:extend()


function Spell:new(x, y, speed, scale, rotation, hitbox, damage)
    -- initialize base class with its constructor
    Spell.super.new(self, x, y, speed, scale, hitbox)

    self.rotation = rotation
    self.damage = damage

    -- set sprite dimensions based on scale argument
    self.width, self.height = 16 * self.spriteScale, 16 * self.spriteScale
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2

    self.enemiesHit = {} -- to not damage the same enemy more than once

    -- spritesheets animation quads setup
    self.spriteSheetRightLeft = love.graphics.newImage("assets/images/spells/fireball-right-left-spritesheet.png")
    self.gridRightLeft = anim8.newGrid(16, 16, self.spriteSheetRightLeft:getWidth(), self.spriteSheetRightLeft:getHeight())

    self.spriteSheetUpDown = love.graphics.newImage("assets/images/spells/fireball-up-down-spritesheet.png")
    self.gridUpDown = anim8.newGrid(16, 16, self.spriteSheetUpDown:getWidth(), self.spriteSheetUpDown:getHeight())

    -- table for animations in all four directions
    self.animations = {}
    self.animations.up = anim8.newAnimation(self.gridUpDown('1-6', 1), 0.15)
    self.animations.left = anim8.newAnimation(self.gridRightLeft('1-6', 2), 0.15)
    self.animations.down = anim8.newAnimation(self.gridUpDown('1-6', 2), 0.15)
    self.animations.right = anim8.newAnimation(self.gridRightLeft('1-6', 1), 0.15)

    self.currentAnimation = self.animations.right
end


-- checking collsion with euclidean distance between centers and hitboxes
function Spell:isCollidingWithEnemy(enemy)
    local dx = self.centerX - enemy.centerX
    local dy = self.centerY - enemy.centerY
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local collsion_distance = self.hitboxRadius + enemy.hitboxRadius

    if distance < collsion_distance then
        return true
    end
    return false
end


function Spell:detectHits(enemies)
    for i = 1, #enemies do
        local e = enemies[i]
        -- do not register collision for enemies in dying state
        if self:isCollidingWithEnemy(e) then
            if e.state == "dying" then
                goto continue -- jump to continue
            end

            -- make sure that enemy was not already damaged by spell
            if not self.enemiesHit.e then
                self.enemiesHit.e = true
                e.state = "damaged"
                e.health = e.health - self.damage -- reduce enemy health by spell's damage value

                -- play random sound effect
                local sfx_index = math.random(1, 3)
                if sfx_index == 1 then
                    game.player.sounds.registerV1:play()
                elseif sfx_index == 2 then
                    game.player.sounds.registerV2:play()
                else
                    game.player.sounds.registerV3:play()
                end

                return true
            end
        ::continue::
        end
    end
    return false
end


function Spell:update(dt)
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2 -- update center coordinates

    -- set animation and direction based on where the player sprite is facing
    if self.rotation == "up" then
        self.currentAnimation = self.animations.up
        self.y = self.y - self.speed * dt
    end

    if self.rotation == "left" then
        self.currentAnimation = self.animations.left
        self.x = self.x - self.speed * dt
    end

    if self.rotation == "down" then
        self.currentAnimation = self.animations.down
        self.y = self.y + self.speed * dt
    end

    if self.rotation == "right" then
        self.currentAnimation = self.animations.right
        self.x = self.x + self.speed * dt
    end

    self.currentAnimation:update(dt)
end


function Spell:draw()
    -- spritesheet to draw based on current animation
    local current_spritesheet
    if self.rotation == "right" or self.rotation == "left" then
        current_spritesheet = self.spriteSheetRightLeft
    else
        current_spritesheet = self.spriteSheetUpDown
    end
    self.currentAnimation:draw(current_spritesheet, self.x, self.y, nil, self.spriteScale)
end