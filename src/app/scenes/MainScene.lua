local creator = require("app.utils.creator")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
	self:TableViewTest()
end

function MainScene:CreatorTest()
	local root = creator.parseJson("creator/main.json")
	root:addTo(self)
end

function MainScene:TableViewTest()
	-- create listview, or get listview from csb
	local lv = ccui.ListView:create()
	lv:setContentSize(cc.size(300, 200))
	lv:center():addTo(self)
	lv:setBackGroundColorType(1)
	lv:setBackGroundColor(cc.c3b(0, 100, 0))
	lv:setAnchorPoint(cc.p(0.5, 0.5))
	lv:setItemsMargin(4)
	-- convert to tablevlew
	local TableView = require("app.utils.TableView")
	local sizeSource = function(self, index)
		return cc.size(300, 15)
	end
	local loadSoruce = function(self, index)
		return ccui.Text:create(index, "Airal", 18)
	end
	local unloadSoruce = function(self, index)
		print("do texture unload here:", index)
	end
	TableView.attachTo(lv, sizeSource, loadSoruce, unloadSoruce)
	lv:initDefaultItems(300)
	lv:jumpTo(300)
	lv:addScrollViewEventListener(function(ref, type)
		print("event:", type)
	end)
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
