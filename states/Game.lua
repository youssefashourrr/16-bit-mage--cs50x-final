Game = Object:extend()


function Game:new()
    -- all possible states for the game
    self.states = {
        running = "running",
        paused = "paused",
        menu = "menu",
        gameOver = "gameOver"
    }

    self.player = nil -- set player only when new game is initiated

    -- tables to keep track of all spell, enemy and sfx objects that were created during runtime
    self.spells = {}
    self.enemies = {}
    self.sounds = {}

    self.level = 1
    self.score = 0
    self.totalTime = 0

    -- get current highscore from txt file
    self.saveFileR = io.open("highscore.txt", "r")
    self.highscore = tonumber(self.saveFileR:read("*all"))
    self.isHighscore = false

    self.currentState = self.states.menu -- start in menu state

    -- values to manage enemy spawn rate
    self.baseSpawnRate = 3
    self.spawnRateFactor = 0.1
    self.timeSinceLastSpawn = 0

    self.levelDuration = 15
    self.timeSinceLastLevel = 0

    self.enemyTypes = {"flying eye", "goblin", "mushroom"}

    self.background = love.graphics.newImage("assets/images/pixel-art-grass-background.jpg") -- load background image

    self.bgm = SFX("bgm/8bit-Dungeon-Level.mp3", "stream")
    self.bgm:setVolume(0.8)
    self.bgm:loop()
end


function Game:startNewGame()
    self.level = 1
    self.score = 0
    self.totalTime = 0

    self.isHighscore = false

    self.timeSinceLastSpawn = 0
    self.timeSinceLastLevel = 0

    -- initialize player for new game instance
    local player_x, player_y = math.random(340, 640), math.random(300, 600)
    local player_speed = 200
    local player_scale = 7
    local player_hitbox_radius = 6
    local player_health = 200
    self.player = Player(player_x, player_y, player_speed, player_scale, player_hitbox_radius, player_health)

    -- reset object tables for new game
    self.spells = {}
    self.enemies = {}
    self.sounds = {}
end


-- update level variable as timer goes on
function Game:updateLevel(dt)
    self.timeSinceLastLevel = self.timeSinceLastLevel + dt
    if self.timeSinceLastLevel >= self.levelDuration then
        self.level = self.level + 1
        self.timeSinceLastLevel = 0
        return true
    end
end


-- spawn enemies in an increasing rate based on the current level and a simple calculation
function Game:manageEnemySpawns(dt)
    self.timeSinceLastSpawn = self.timeSinceLastSpawn + dt

    local spawnRate = (self.baseSpawnRate / (1 + (self.level * 0.5))) * 1.25

    if self.timeSinceLastSpawn >= spawnRate then
        self:spawnEnemy()
        self.timeSinceLastSpawn = 0
    end
end


function Game:spawnEnemy()
    local spawn_x, spawn_y
    local spawn_margin = 10

    -- randomize the side at which the enemy will spawn
    local side = math.random(1,4)
    if side == 1 then
        spawn_x = math.random(0, WINDOW_WIDTH)
        spawn_y = -spawn_margin
    elseif side == 2 then
        spawn_x = -spawn_margin
        spawn_y = math.random(0, WINDOW_HEIGHT)
    elseif side == 3 then
        spawn_x = math.random(0, WINDOW_WIDTH)
        spawn_y = WINDOW_HEIGHT + spawn_margin
    elseif side == 4 then
        spawn_x = WINDOW_WIDTH + spawn_margin
        spawn_y = math.random(0, WINDOW_HEIGHT)
    end

    local enemy_scale = 1
    local enemy_type
    local enemy_speed
    local enemy_hitbox_radius = 20
    local enemy_health
    local enemy_damage
    local enemy_points

    -- randomize enemy type with different properties for each type
    local enemy_index = math.random(1, #self.enemyTypes)
    if enemy_index == 1 then
        enemy_type = self.enemyTypes[1]
        enemy_speed = 300
        enemy_health = 50 + (game.level * 10)
        enemy_damage = 7 + game.level
        enemy_points = 5
    elseif enemy_index == 2 then
        enemy_type = self.enemyTypes[2]
        enemy_speed = 200
        enemy_health = 100 + (game.level * 15)
        enemy_damage = 10 + (game.level * 2)
        enemy_points = 10
    else
        enemy_type = self.enemyTypes[3]
        enemy_speed = 150
        enemy_health = 150 + (game.level * 20)
        enemy_damage = 15 + (game.level * 1.5)
        enemy_points = 7
    end

    local new_enemy = Enemy(spawn_x, spawn_y, enemy_type, enemy_speed, enemy_scale, enemy_hitbox_radius, self.player, enemy_health, enemy_damage, enemy_points,
                        "assets/images/enemies/" .. self.enemyTypes[enemy_index] .. "/run.png",
                        "assets/images/enemies/" .. self.enemyTypes[enemy_index] .. "/attack.png",
                        "assets/images/enemies/" .. self.enemyTypes[enemy_index] .. "/take-hit.png",
                        "assets/images/enemies/" .. self.enemyTypes[enemy_index] .. "/death.png")
    table.insert(self.enemies, new_enemy)
end
