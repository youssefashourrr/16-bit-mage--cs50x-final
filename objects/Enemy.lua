---@diagnostic disable: lowercase-global

Enemy = Entity:extend()


function Enemy:new(x, y, type, speed, scale, hitbox, player, health, damage, points, moveImage, attackImage, hitImage, deathImage)
    self.type = type

    -- initialize base class with its constructor
    Enemy.super.new(self, x, y, speed, scale, hitbox)

    self.frameWidth, self.frameHeight = 150, 150
    self.width, self.height = self.frameWidth * self.spriteScale, self.frameHeight * self.spriteScale -- scales with sprite scale
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2

    self.player = player
    local dx_from_spawn = self.player.centerX - self.centerX
    local dy_from_spawn = self.player.centerY - self.centerY

    -- calculate euclidean distance between player and enemy centers
    local distance_from_spawn = math.sqrt((dx_from_spawn * dx_from_spawn) + (dy_from_spawn * dy_from_spawn))

    -- calculate unit vectors for x and y movement
    self.directionX = dx_from_spawn / distance_from_spawn
    self.directionY = dy_from_spawn / distance_from_spawn

    self.health = health or 100
    self.damage = damage or 10
    self.points = points

    self.state = "moving"
    self.isAlive = true
    self.dtSinceLastAttack = 0
    self.attackCooldown = 0.75

    -- load in spritesheet images
    self.moveSpriteSheet = love.graphics.newImage(moveImage)
    self.attackSpriteSheet = love.graphics.newImage(attackImage)
    self.hitSpriteSheet = love.graphics.newImage(hitImage)
    self.deathSpriteSheet = love.graphics.newImage(deathImage)

    -- divide animation quads using external anim8 module
    self.moveGrid = anim8.newGrid(self.frameWidth, self.frameHeight, self.moveSpriteSheet:getWidth(), self.moveSpriteSheet:getHeight())
    self.attackGrid = anim8.newGrid(self.frameWidth, self.frameHeight, self.attackSpriteSheet:getWidth(), self.attackSpriteSheet:getHeight())
    self.hitGrid = anim8.newGrid(self.frameWidth, self.frameHeight, self.hitSpriteSheet:getWidth(), self.hitSpriteSheet:getHeight())
    self.deathGrid = anim8.newGrid(self.frameWidth, self.frameHeight, self.deathSpriteSheet:getWidth(), self.deathSpriteSheet:getHeight())

    -- some animations are flipped and/or played in reverse to make up for missing spritesheets
    self.animations = {
        moveRight = anim8.newAnimation(self.moveGrid('1-8', 1), 0.15),
        moveLeft = anim8.newAnimation(self.moveGrid('1-8', 1), 0.15):flipH(),

        attackRight = anim8.newAnimation(self.attackGrid('1-8', 1), 0.1),
        attackLeft = anim8.newAnimation(self.attackGrid('8-1', 1), 0.1):flipH(),

        hitRight = anim8.newAnimation(self.hitGrid('1-4', 1), 0.25),
        hitLeft = anim8.newAnimation(self.hitGrid('1-4', 1), 0.25):flipH(),

        deathRight = anim8.newAnimation(self.deathGrid('1-4', 1), 0.3),
        deathLeft = anim8.newAnimation(self.deathGrid('1-4', 1), 0.3):flipH()
    }

    self.currentAnimation = nil

    -- table storing separate tables for each enemy type's sounds
    self.sounds = {
        flyingEye = {
            death = SFX("enemies/flying eye/android-death.wav", "static"),
            attack = SFX("enemies/flying eye/bite.wav", "static")
        },
        goblin = {
            death = SFX("enemies/goblin/grunt.wav", "static"),
            attackV1 = SFX("enemies/goblin/swing (1).wav", "static"),
            attackV2 = SFX("enemies/goblin/swing (2).wav", "static"),
            attackV3 = SFX("enemies/goblin/swing (3).wav", "static")
        },
        mushroom = {
            death = SFX("enemies/mushroom/death-scream.wav", "static"),
            attack = SFX("enemies/mushroom/smack.wav", "static")
        }
    }
end


function Enemy:update(dt)
    if not self.isAlive then
        return
    end

    self:updateCenter()

    if self.health <= 0 then
        self.state = "dying"
        self:handleDeath(dt)
    end

    -- call functions according to the current state
    if self.state == "onCooldown" then
        self:handleAttackCooldown(dt)
    elseif self.state == "moving" then
        self:handleMovement(dt)
    elseif self.state == "attacking" then
        self:handleAttackState(dt)
    elseif self.state == "damaged" then
        self:handleDamage(dt)
    end

    self.currentAnimation:update(dt)
end


function Enemy:updateCenter()
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2
end


-- abstracted distance calculation to its own function
function Enemy:calculateDistanceToPlayer()
    local dx = self.player.centerX - self.centerX
    local dy = self.player.centerY - self.centerY
    local distance = math.sqrt(dx * dx + dy * dy)
    return dx, dy, distance
end


function Enemy:handleMovement(dt)
    local dx, dy, distance = self:calculateDistanceToPlayer()

    -- set animation based on player's relative position 
    if dx < 0 then
        self.currentAnimation = self.animations.moveLeft
    else
        self.currentAnimation = self.animations.moveRight
    end

    self.directionX = dx / distance
    self.directionY = dy / distance

    -- change x,y coordinates using unit vectors for direction and speed for rate of change
    self.x = self.x + self.directionX * self.speed * dt
    self.y = self.y + self.directionY * self.speed * dt

    -- check if hitboxes are close enough to attack
    if distance < self.hitboxRadius + self.player.hitboxRadius then
        self.state = "attacking"
    end
end


function Enemy:handleAttackState(dt)
    -- set animation to attacking if not already set
    if self.currentAnimation ~= self.animations.attackLeft and self.currentAnimation ~= self.animations.attackRight then
        if self.directionX < 0 then
            self.currentAnimation = self.animations.attackLeft
        else
            self.currentAnimation = self.animations.attackRight
        end

        -- play attack sound effect depending on enemy type
        if self.type == "flying eye" then
            self.sounds.flyingEye.attack:setVolume(0.5)
            self.sounds.flyingEye.attack:play()
        elseif self.type == "goblin" then
            local sfx_index = math.random(1, 3)
            if sfx_index == 1 then
                self.sounds.goblin.attackV1:play()
            elseif sfx_index == 2 then
                self.sounds.goblin.attackV2:play()
            else
                self.sounds.goblin.attackV3:play()
            end
        else
            self.sounds.mushroom.attack:play()
        end
    end

    -- switch to cooldown state when attack animation is finished
    if (self.currentAnimation == self.animations.attackLeft and self.currentAnimation.position == 1)
    or (self.currentAnimation == self.animations.attackRight and self.currentAnimation.position == #self.currentAnimation.frames) then
        self.state = "onCooldown"
    end
end


-- manage cooldown between attacks
function Enemy:handleAttackCooldown(dt)
    self.dtSinceLastAttack = self.dtSinceLastAttack + dt
    if self.dtSinceLastAttack >= self.attackCooldown then
        self.state = "moving"
        self.dtSinceLastAttack = 0
    end
end


function Enemy:handleDamage(dt)
    -- set animation if not already set
    if self.currentAnimation ~= self.animations.hitLeft and self.currentAnimation ~= self.animations.hitRight then
        if self.directionX < 0 then
            self.currentAnimation = self.animations.hitLeft
        else
            self.currentAnimation = self.animations.hitRight
        end
    end

    -- switch to moving state when animation is finished
    if (self.currentAnimation == self.animations.hitLeft or self.currentAnimation == self.animations.hitRight)
    and self.currentAnimation.position == #self.currentAnimation.frames then
        self.state = "moving"
    end
end


function Enemy:handleDeath(dt)
    -- set death animation if not already set
    if self.currentAnimation ~= self.animations.deathLeft and self.currentAnimation ~= self.animations.deathRight then
        if self.directionX < 0 then
            self.currentAnimation = self.animations.deathLeft
        else
            self.currentAnimation = self.animations.deathRight
        end

        -- play death sound effect depending on enemy type
        if self.type == "flying eye" then
            self.sounds.flyingEye.death:play()
        elseif self.type == "goblin" then
            self.sounds.goblin.death:play()
        else
            self.sounds.mushroom.death:play()
        end
    end

    if (self.currentAnimation == self.animations.deathLeft or self.currentAnimation == self.animations.deathRight)
    and self.currentAnimation.position == #self.currentAnimation.frames then
        self.isAlive = false
        -- calculate points added to score on enemy kill based on current level
        local level_multiplier = math.min(game.level * 0.75 + 1, 12)
        game.score = game.score + math.floor(self.points * level_multiplier)
    end
end


-- push enemy out of the player's hitbox based on the overlap
function Enemy:resolveCollisionsWithPlayer()
    local dx = self.centerX - self.player.centerX
    local dy = self.centerY - self.player.centerY
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local min_distance = self.hitboxRadius + self.player.hitboxRadius

    if distance < min_distance then
        local overlap = min_distance - distance
        local direction_x = dx / distance
        local direction_y = dy / distance
        local damping = 0.75
        self.x = self.x + direction_x * overlap * damping
        self.y = self.y + direction_y * overlap * damping

        self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2
    end
end


-- push enemy out of other enemies' hitbox based on their overlap
function Enemy:resolveCollisionsWithOtherEnemies(enemies)
    for i = 1, #enemies do
        local other = enemies[i]
        if other ~= self then
            local dx = self.centerX - other.centerX
            local dy = self.centerY - other.centerY
            local distance = math.sqrt((dx * dx) + (dy * dy))
            local min_distance = (self.hitboxRadius * 2) + other.hitboxRadius

            if distance < min_distance then
                local overlap = min_distance - distance
                local direction_x = dx / distance
                local direction_y = dy / distance

                -- both enemies are moved away from one another at the same rate
                self.x = self.x + direction_x * overlap / 2
                self.y = self.y + direction_y * overlap / 2
                other.x = other.x - direction_x * overlap / 2
                other.y = other.y - direction_y * overlap / 2

                self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2
                other.centerX, other.centerY = other.x + other.width / 2, other.y + other.height / 2
            end
        end
    end
end


function Enemy:draw()
    if not self.isAlive then
        return
    end

    -- find current spritesheet based on the current animation
    local current_animation_sheet
    if self.currentAnimation == self.animations.moveLeft or self.currentAnimation == self.animations.moveRight then
        current_animation_sheet = self.moveSpriteSheet
    elseif self.currentAnimation == self.animations.attackLeft or self.currentAnimation == self.animations.attackRight then
        current_animation_sheet = self.attackSpriteSheet
    elseif self.currentAnimation == self.animations.hitLeft or self.currentAnimation == self.animations.hitRight then
        current_animation_sheet = self.hitSpriteSheet
    elseif self.currentAnimation == self.animations.deathLeft or self.currentAnimation == self.animations.deathRight then
        current_animation_sheet = self.deathSpriteSheet
    end

    self.currentAnimation:draw(current_animation_sheet, self.x, self.y, nil, self.spriteScale)
end
