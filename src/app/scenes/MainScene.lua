local creator = require("app.utils.creator")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
	local root = creator.parseJson("creator/main.json")
	root:addTo(self)
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
