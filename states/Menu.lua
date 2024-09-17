Menu = Object:extend()


function Menu:new(gameInstance)
    self.background = love.graphics.newImage("assets/images/this-is-cs50.jpeg")

    self.bgm = SFX("bgm/Reincarnated-Echoes.mp3", "stream")
    self.bgm:setVolume(0.6)
    self.bgm:loop()

    -- functional menu buttons
    self.startButton = Button(300, 175, 85, "START", "start", gameInstance)
    self.quitButton = Button(450, 175, 85, "EXIT", "end", gameInstance)
end


-- keep track of button states and if they are clicked
function Menu:update()
    self.startButton:update()
    self.quitButton:update()
end


function Menu:draw()
    love.graphics.draw(self.background, -400, -150)
    self.startButton:draw()
    self.quitButton:draw()
end