Player = Entity:extend()


function Player:new(x, y, speed, scale, hitbox, health)
    -- initialize base class with its constructor
    Player.super.new(self, x, y, speed, scale, hitbox)

    -- starting health and current health values
    self.maxHealth = health
    self.health = self.maxHealth

    -- sprite dimensions
    self.frameWidth, self.frameHeight = 16, 16

    -- scaling width, height with sprite drawing scale
    self.width, self.height = self.frameWidth * self.spriteScale, self.frameHeight * self.spriteScale
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2

    self.spriteSheet = love.graphics.newImage("assets/images/player-spritesheet.png")
    self.grid = anim8.newGrid(self.frameWidth, self.frameHeight, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())

    -- invincibility properties to manage object between health reduction instances
    self.isInvincible = false
    self.invincibilityTimer = 0
    self.invincibilityLimit = 1

    -- animation table for all four directions
    self.animations = {}
    self.animations.up = anim8.newAnimation(self.grid('5-8', 1), 0.15)
    self.animations.left = anim8.newAnimation(self.grid('5-8', 2), 0.15)
    self.animations.down = anim8.newAnimation(self.grid('1-4', 1), 0.15)
    self.animations.right = anim8.newAnimation(self.grid('1-4', 2), 0.15)

    self.currentAnimation = self.animations.down

    -- table for all sounds and their variations
    self.sounds = {
        death = SFX("player/death.wav", "static"),
        castV1 = SFX("player/spell-cast (1).wav", "static"),
        castV2 = SFX("player/spell-cast (2).wav", "static"),
        registerV1 = SFX("player/hit-register (1).wav", "static"),
        registerV2 = SFX("player/hit-register (2).wav", "static"),
        registerV3 = SFX("player/hit-register (3).wav", "static")
    }
end


function Player:update(dt)
    self.centerX, self.centerY = self.x + self.width / 2, self.y + self.height / 2 -- update center every frame

    local is_moving = false -- flag to handle idle animation

    -- WASD keyboard mapping to move in different directions
    if love.keyboard.isDown("w") then
        self.currentAnimation = self.animations.up
        self.y = self.y - self.speed * dt
        is_moving = true
    end

    if love.keyboard.isDown("a") then
        self.currentAnimation = self.animations.left
        self.x = self.x - self.speed * dt
        is_moving = true
    end

    if love.keyboard.isDown("s") then
        self.currentAnimation = self.animations.down
        self.y = self.y + self.speed * dt
        is_moving = true
    end

    if love.keyboard.isDown("d") then
        self.currentAnimation = self.animations.right
        self.x = self.x + self.speed * dt
        is_moving = true
    end

    if not is_moving then
        self.currentAnimation:gotoFrame(1)
    end

    self.currentAnimation:update(dt)

end


-- checking collisions by observing distance between hitboxes
function Player:isCollidingWithEnemy(enemy)
    local dx = self.centerX - enemy.centerX
    local dy = self.centerY - enemy.centerY
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local collsion_distance = self.hitboxRadius + enemy.hitboxRadius

    if distance < collsion_distance then
        return true
    end
    return false
end


function Player:detectEnemyAttacks(enemies, dt)
    if self.health <= 0 then
        -- save new highscore if current score is higher
        if game.score > game.highscore then
            local savefile_w = io.open("highscore.txt", "w")
            if savefile_w ~= nil then
                game.isHighscore = true
                savefile_w:write(game.score)
                savefile_w:close()
            end
        end
        -- play death sound two times for amplification (not ideal)
        for i = 1, 2 do
            self.sounds.death:setVolume(1)
            self.sounds.death:play()
        end
        game.currentState = game.states.gameOver -- change to game over state
        return
    end

    -- handling invincibility cooldown and timer
    if self.isInvincible then
        self.invincibilityTimer = self.invincibilityTimer + dt
        if self.invincibilityTimer >= self.invincibilityLimit then
            self.isInvincible = false
            self.invincibilityTimer = 0
        end
        return
    end

    for i = 1, #enemies do
        local e = enemies[i]
        -- checking if current enemy is colliding with play and is in attack state
        if self:isCollidingWithEnemy(e) and e.state == "attacking" then
            self.health = self.health - e.damage
            self.isInvincible = true
            self.invincibilityTimer = 0
            break
        end
    end
end


-- edge wrapping functionality to never move out of window bounds
function Player:wrapEdges()
    local offset = 5

    if self.x > WINDOW_WIDTH + offset then
        self.x = 0 - self.width
    elseif self.x < 0 - self.width - offset then
        self.x = WINDOW_WIDTH + offset
    end

    if self.y > WINDOW_HEIGHT + offset then
        self.y = 0 - self.height + offset
    elseif self.y < 0 - self.height - offset then
        self.y = WINDOW_HEIGHT
    end
end


function Player:draw()
    -- draw blend mode depends on invincibility flag
    if self.isInvincible then
        love.graphics.setBlendMode("add")
    else
        love.graphics.setBlendMode("alpha")
    end

    self.currentAnimation:draw(self.spriteSheet, self.x, self.y, nil, self.spriteScale)
    love.graphics.setBlendMode("alpha")
end