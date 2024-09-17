SFX = Object:extend()


function SFX:new(path, mode)
    self.sound = love.audio.newSource("assets/sounds/" .. path, mode) -- load new sound with passed arguemnts as source object
end


-- play source if not already playing
function SFX:play()
    if self.sound:isPlaying() then
        return
    end

    self.sound:play()
end


function SFX:stop()
    self.sound:stop()
end


function SFX:pause()
    self.sound:pause()
end


function SFX:setVolume(db)
    self.sound:setVolume(db)
end


function SFX:loop()
    self.sound:setLooping(true) -- source loops on end
end