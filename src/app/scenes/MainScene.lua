local creator = require("app.utils.creator")
require("app.utils.TableViewPro")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
	-- self:TableViewTest()
	self:TableViewProTest()
end

function MainScene:CreatorTest()
	local root = creator.parseJson("creator/main.json")
	root:addTo(self)
end

function MainScene:TableViewTest()
	-- create listview, or get listview from csb
	local lv = ccui.ListView:create()
	lv:setBounceEnabled(true)
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

function MainScene:TableViewProTest()
	local amount = 1000

    local tab = cc.TableView.new(cc.size(100,400))
    local function size(tableview, index)
        return 100, 100
    end

    local function number(tableview)
        return amount
    end

    local function loadCell(tableview, index)
		print("loadCell:", index)
        local cell = tableview:dequeueCell()
        if not cell then
            cell = cc.TableViewCell.new()
            local text = ccui.Text:create(index, "", 50):addTo(cell, 1, 666):align(display.LEFT_BOTTOM, 0, 0)
            text:setTextColor(cc.c3b(255,255,math.random(1, 255)))
		end
        cell:getChildByTag(666):setString(index)

        return cell
    end

	local function unloadCell(tableview, index)
		print("unloadCell:", index)
	end

    tab:setDirection(cc.TableViewDirection.vertical)
    tab:setFillOrder(cc.TableViewFillOrder.topToBottom)
    tab:registerFunc(cc.TableViewFuncType.cellSize, size)
    tab:registerFunc(cc.TableViewFuncType.cellNum, number)
    tab:registerFunc(cc.TableViewFuncType.cellLoad, loadCell)
    tab:registerFunc(cc.TableViewFuncType.cellUnload, unloadCell)
    tab:addTo(self):align(display.CENTER, display.cx, display.cy)
    tab:reloadData()

    local text = ccui.Text:create("resize tableview", "", 40):addTo(self):pos(display.cx, display.cy + 250)
	text:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
		if event.name == "ended" then
            amount = 18
            tab:reloadDataInPos()
		end
		return true
	end)
	text:setTouchEnabled(true)
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
