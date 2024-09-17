Button = Object:extend()


function Button:new(y, width, height, text, func, game)
    self.width, self.height = width, height
    self.x = WINDOW_WIDTH / 2 - self.width / 2 -- always center on x-axis
    self.y = y

    self.text = text
    self.isHovered = false

    -- dimension for hovered effect
    local scale_factor = 1.05
    self.hoveredWidth = self.width * scale_factor
    self.hoveredHeight = self.height * scale_factor

    self.game = game

    -- functions to be called on button clicks
    self.funcs = {}
    self.funcs.start = function()
        self.game.currentState = self.game.states.running
        self.game:startNewGame()
    end
    self.funcs.quit = function()
        love.event.quit()
    end

    if func == "start" then
        self.func = self.funcs.start
    elseif func == "end" then
        self.func = self.funcs.quit
    end
end


function Button:update()
    local mouse_x, mouse_y = love.mouse.getPosition()

    -- determine if mouse cursor is in button dimensions
    if (mouse_x >= self.x and mouse_x <= self.x + self.width)
    and (mouse_y >= self.y and mouse_y <= self.y + self.height) then
        self.isHovered = true
        if love.mouse.isDown(1) then -- call function on mouse 1 click
            self.func()
        end
    else
        self.isHovered = false
    end
end


function Button:draw()
    local corner_radius = 12

    -- draw rectangle and text with adjusted values when button is being hovered
    if self.isHovered then
        local hover_x = self.x - (self.hoveredWidth - self.width) / 2
        local hover_y = self.y - (self.hoveredHeight - self.height) / 2
        love.graphics.setColor({1, 0.5, 0.5, 0.8})
        love.graphics.rectangle("fill", hover_x, hover_y, self.hoveredWidth, self.hoveredHeight, corner_radius, corner_radius)

        love.graphics.setColor({0, 0, 0})
        love.graphics.setFont(hoveredButtonFont)
        love.graphics.printf(self.text, hover_x, hover_y + (self.hoveredHeight / 2) - (buttonFont:getHeight() / 2), self.hoveredWidth, "center")
    else
        -- draw unhovered button with base values
        love.graphics.setColor({1, 1, 1})
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, corner_radius, corner_radius)

        love.graphics.setColor({0, 0, 0})
        love.graphics.setFont(buttonFont)
        love.graphics.printf(self.text, self.x, self.y + (self.height / 2) - (buttonFont:getHeight() / 2), self.width, "center")
    end

    love.graphics.setColor({1, 1, 1})
    love.graphics.setFont(defaultFont)
end
