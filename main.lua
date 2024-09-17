---@diagnostic disable: lowercase-global

math.randomseed(os.time())

-- import LOVE framework, classic module, anim8 module
love = require "love"
Object = require "modules.classic"
anim8 = require "modules.anim8"

WINDOW_WIDTH, WINDOW_HEIGHT = 1024, 896 -- window dimension globals


function love.load()
    -- load all other game files -> objects, components, etc.
    require "states.Game"
    require "states.Menu"
    require "components.Text"
    require "components.Button"
    require "components.SFX"
    require "objects.Entity"
    require "objects.Player"
    require "objects.Spell"
    require "objects.Enemy"

    love.graphics.setDefaultFilter("nearest", "nearest")

    -- initialize and load in all fonts to be used throughout the project
    defaultFont = love.graphics.getFont()
    pauseFont = love.graphics.newFont("assets/fonts/MightySouly.ttf", 96)
    gameOverFont = love.graphics.newFont("assets/fonts/MightySouly.ttf", 124)
    subHeadFont = love.graphics.newFont("assets/fonts/NerkoOne.ttf", 32)
    buttonFont = love.graphics.newFont("assets/fonts/BebasNeue.ttf", 54)
    cs50Font = love.graphics.newFont("assets/fonts/Handjet-SemiBold.ttf", 42)
    hoveredButtonFont = love.graphics.newFont("assets/fonts/BebasNeue.ttf", 54 * 1.1)
    hudFont = love.graphics.newFont("assets/fonts/ConcertOne.ttf", 32)
    highscoreFont = love.graphics.newFont("assets/fonts/ChakraPetch-SemiBoldItalic.ttf", 72)

    game = Game() -- main game object
    menu = Menu(game)
end


-- listen to key presses and act according to state
function love.keypressed(key, scancode, isrepeat)
    if game.currentState == game.states.running then
        -- fire spell from player's position
        if key == "f" or key == "space" then
            local spell_x, spell_y
            local spell_speed = 300
            local spell_scale = 2
            local spell_direction
            local spell_hitbox_radius = 12.5
            local spell_damage = 50

            -- set the spell's direction based on the player's current animation to match with spell animation
            if game.player.currentAnimation == game.player.animations.up then
                spell_direction = "up"
                spell_x = game.player.x + (game.player.width / 2) - 15
                spell_y = game.player.y - 10
            elseif game.player.currentAnimation == game.player.animations.left then
                spell_direction = "left"
                spell_x = game.player.x
                spell_y = game.player.y + (game.player.height / 2)
            elseif game.player.currentAnimation == game.player.animations.down then
                spell_direction = "down"
                spell_x = game.player.x + (game.player.width / 2) - 15
                spell_y = game.player.y + game.player.height - 10
            elseif game.player.currentAnimation == game.player.animations.right then
                spell_direction = "right"
                spell_x = game.player.x + game.player.width - 40
                spell_y = game.player.y + (game.player.height / 2)
            end

            fireball = Spell(spell_x, spell_y, spell_speed, spell_scale, spell_direction, spell_hitbox_radius, spell_damage)
            table.insert(game.spells, fireball)

            -- play random sound effect on spell cast
            local sfx_index = math.random(1, 2)
            if sfx_index == 1 then
                game.player.sounds.castV1:setVolume(0.5)
                game.player.sounds.castV1:play()
            else
                game.player.sounds.castV2:play()
            end

        elseif key == "escape" then
            game.currentState = game.states.paused
        end
    elseif game.currentState == game.states.paused then
        if key == "escape" then
            game.currentState = game.states.running -- unpause game
        end
    elseif game.currentState == game.states.gameOver then
        if key == "space" then
            game.currentState = game.states.running
            game:startNewGame()
        elseif key == "escape" then
            love.event.quit()
        end
    end
end


-- handle background music based on game state
function manageBGM()
    if game.currentState == game.states.running then
        menu.bgm:stop()
        game.bgm:play()
    elseif game.currentState == game.states.menu then
        game.bgm:stop()
        menu.bgm:play()
    elseif game.currentState == game.states.paused then
        game.bgm:pause()
    else
        game.bgm:stop()
    end
end


function love.update(dt)
    manageBGM()

    if game.currentState == game.states.running then
        game.totalTime = game.totalTime + dt

        game.player:update(dt)
        game.player:wrapEdges()
        game.player:detectEnemyAttacks(game.enemies, dt)

        for i = #game.spells, 1, -1 do
            -- remove spells if they go out of bounds or collide with an enemy
            if game.spells[i]:detectHits(game.enemies) or game.spells[i].x > WINDOW_WIDTH or game.spells[i].x < 0
            or game.spells[i].y > WINDOW_HEIGHT or game.spells[i].y < 0 then
                table.remove(game.spells, i)
            else
                game.spells[i]:update(dt)
            end
        end

        game:updateLevel(dt)
        game:manageEnemySpawns(dt)

        for i = #game.enemies, 1, -1 do
            -- despawn enemies with less than zero health
            if not game.enemies[i].isAlive then
                table.remove(game.enemies, i)

            else
                game.enemies[i]:update(dt)
                if game.enemies[i].state ~= "dying" then -- no collisions are managed on enemies in the dying state
                    game.enemies[i]:resolveCollisionsWithPlayer(game.player)
                    game.enemies[i]:resolveCollisionsWithOtherEnemies(game.enemies)
                end
            end
        end
    elseif game.currentState == game.states.menu then
        menu:update()
    end
end


function drawRunningElements()
    local bg_scale_x, bg_scale_y = WINDOW_WIDTH / game.background:getWidth(), WINDOW_HEIGHT / game.background:getHeight() -- scale bg image with window dimensions
    love.graphics.draw(game.background, 0, 0, 0, bg_scale_x, bg_scale_y)

    -- low opacity black rectangle to emulate a lowered brightness effect over the background image
    love.graphics.setColor({0, 0, 0, 0.3})
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setColor({1, 1, 1, 1})

    bgText = Text("THIS IS CS50", "center", "center", cs50Font, {1, 1, 1, 0.8})
    bgText:draw()

    -- properties for a rectangle used as a health bar
    local health_ratio = game.player.health / game.player.maxHealth
    local healthbar_width, healthbar_height = 180, 25
    local healthbar_x, healthbar_y = 60, 850
    local healthbar_alpha = 0.75

    love.graphics.setColor({0.85, 1 * health_ratio, 0, healthbar_alpha}) -- rectangle width decreaes as current health to max health ratio decreases
    love.graphics.rectangle("fill", healthbar_x , healthbar_y, healthbar_width * health_ratio, healthbar_height)
    love.graphics.setColor({1, 1, 1})

    -- hud text elements
    levelText = Text("INTENSITY: " .. game.level, 840, 830, hudFont, {0, 0, 0})
    scoreText = Text("SCORE: " .. game.score, 10, 800, hudFont, {0, 0, 0})
    hpText = Text("HP:", 10, 840, hudFont, {0, 0, 0})
    highscore = Text("HIGHSCORE: " .. game.highscore, 10, 10, hudFont, {1, 0.969, 0})

    levelText:draw()
    scoreText:draw()
    hpText:draw()
    highscore:draw()

    game.player:draw()

    for i = 1, #game.spells do
        game.spells[i]:draw()
    end

    for i = 1, #game.enemies do
        game.enemies[i]:draw()
    end
end


function drawPausedElements()
    -- same elements as running state except for background text
    local bg_scale_x, bg_scale_y = WINDOW_WIDTH / game.background:getWidth(), WINDOW_HEIGHT / game.background:getHeight()
    love.graphics.draw(game.background, 0, 0, 0, bg_scale_x, bg_scale_y)

    local health_ratio = game.player.health / game.player.maxHealth
    local healthbar_width, healthbar_height = 180, 25
    local healthbar_x, healthbar_y = 60, 850
    local healthbar_alpha = 0.85

    love.graphics.setColor({0.85, 1 * health_ratio, 0, healthbar_alpha})
    love.graphics.rectangle("fill", healthbar_x , healthbar_y, healthbar_width * health_ratio, healthbar_height)
    love.graphics.setColor({1, 1, 1})

    levelText = Text("INTENSITY: " .. game.level, 840, 830, hudFont, {0, 0, 0})
    scoreText = Text("SCORE: " .. game.score, 10, 800, hudFont, {0, 0, 0})
    hpText = Text("HP:", 10, 840, hudFont, {0, 0, 0})
    highscore = Text("HIGHSCORE: " .. game.highscore, 10, 10, hudFont, {1, 0.969, 0})

    levelText:draw()
    scoreText:draw()
    hpText:draw()
    highscore:draw()

    game.player:draw()

    for i = 1, #game.spells do
        game.spells[i]:draw()
    end

    for i = 1, #game.enemies do
        game.enemies[i]:draw()
    end

    -- low opacity rectangle to fade out the game elements behind the text
    love.graphics.setColor({0, 0, 0, 0.5})
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setColor({1, 1, 1})

    pauseText = Text("PAUSED", "center", "center", pauseFont, {1, 1, 1})
    pauseSub = Text("press \"ESC\" to continue", "center", 500, subHeadFont, {0.5, 1, 0.5})

    pauseText:draw()
    pauseSub:draw()
end


function drawGameOverElements()
    -- draw running elements except for hud text and health bar
    local bg_scale_x, bg_scale_y = WINDOW_WIDTH / game.background:getWidth(), WINDOW_HEIGHT / game.background:getHeight()
    love.graphics.draw(game.background, 0, 0, 0, bg_scale_x, bg_scale_y)

    game.player:draw()

    for i = 1, #game.spells do
        game.spells[i]:draw()
    end

    for i = 1, #game.enemies do
        game.enemies[i]:draw()
    end

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    gameOverSub = Text("SPACEBAR FOR ANOTHER RUN", "center", 835, subHeadFont, {1, 1, 1})
    finalScoreText = Text(game.score .. " points", "center", 500, subHeadFont, {1, 0.576, 0})

    gameOverSub:draw()
    finalScoreText:draw()

    -- display different text if the current highscore is beaten
    if game.isHighscore then
        newHighText = Text("NEW HIGHSCORE!", "center", "center", highscoreFont, {1, 0.984, 0})
        newHighText:draw()
    else
        gameOverText = Text("YOU DIED", "center", "center", pauseFont, {1, 0, 0})
        gameOverText:draw()
    end
end


-- call draw function for each game state
function love.draw()
    if game.currentState == game.states.running then
        drawRunningElements()

    elseif game.currentState == game.states.menu then
        menu:draw()

    elseif game.currentState == game.states.paused then
        drawPausedElements()

    elseif game.currentState == game.states.gameOver then
        drawGameOverElements()
    end
end