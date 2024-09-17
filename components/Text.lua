Text = Object:extend()


function Text:new(content, x, y, font, color)
    self.content = content

    self.x, self.y = x, y

    self.font = font
    self.color = color

    -- calculate coordinates for x and/or y centering
    if self.x == "center" then
        self.x = (WINDOW_WIDTH - self.font:getWidth(self.content)) / 2
    end
    if self.y == "center" then
        self.y = (WINDOW_HEIGHT - self.font:getHeight(self.content)) / 2
    end
end


function Text:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color)

    love.graphics.print(self.content, self.x, self.y)

    love.graphics.setFont(defaultFont)
    love.graphics.setColor({1, 1, 1})
end