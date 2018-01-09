local TableView = {}

--[[ In TableView, index is Lua index, from 1 to N
]]--

local ListView = ccui.ListView

--[[ internal method
self: listview
size: listview's ContentSize
item: to be check
]]--
local function checkInView(self, size, item)
	-- item convert relative to listview
	local posA = item:convertToWorldSpace(cc.p(0, 0))
	posA = self:convertToNodeSpace(posA)
	local sizeA = item:getContentSize()
	-- AABB
	local centerXdelta = (sizeA.width + size.width) / 2
	local centerYdelta = (sizeA.height + size.height) / 2
	if math.abs((posA.x + sizeA.width / 2) - (size.width / 2)) <= centerXdelta and
		math.abs((posA.y + sizeA.height / 2) - (size.height / 2)) <= centerYdelta then
		return true
	end
	return false
end

-- internal method
local function scrolling(self)
	if nil == self._innerP then return end

	local direction = self:getDirection()
	local size = self:getContentSize()

	local isForward = false
	if 1 == direction then -- VERTICAL
		local py = self:getInnerContainer():getPositionY()
		if self._innerP < py then -- 加载下方数据
			isForward = true
		end
		self._innerP = py
	else
		local px = self:getInnerContainer():getPositionX()
		if self._innerP > px then -- 加载右方数据
			isForward = true
		end
		self._innerP = px
	end

	local item
	if isForward then
		item = ListView.getItem(self, self._tailIndex - 1)
		if self:_checkInView(size, item) then -- tail in view
			repeat -- add tail
				item = ListView.getItem(self, self._tailIndex)
				if nil == item then break end
				if not self:_checkInView(size, item) then
					break
				end
				self._tailIndex = self._tailIndex + 1
				item:addChild(self:_loadSource(self._tailIndex))
			until false
			repeat -- remove head
				item = ListView.getItem(self, self._headIndex - 1)
				if self:_checkInView(size, item) then
					break
				end
				item:removeAllChildren()
				self:_unloadSource(self._headIndex)
				self._headIndex = self._headIndex + 1
			until false
		else -- tail out of view, jump scrolling
			-- remove all
			for i = self._headIndex, self._tailIndex do
				item = ListView.getItem(self, i - 1)
				item:removeAllChildren()
				self:_unloadSource(i)
				self._headIndex = nil
			end
			-- find new head and tail
			repeat
				item = ListView.getItem(self, self._tailIndex)
				if nil == item then break end
				if self:_checkInView(size, item) then
					self._tailIndex = self._tailIndex + 1
					item:addChild(self:_loadSource(self._tailIndex))
					if nil == self._headIndex then
						self._headIndex = self._tailIndex
					end
				else
					if self._headIndex then
						break
					else
						self._tailIndex = self._tailIndex + 1
					end
				end
			until false
		end
	else -- not isForward
		item = ListView.getItem(self, self._headIndex - 1)
		if self:_checkInView(size, item) then -- head in view
			repeat -- add head
				item = ListView.getItem(self, self._headIndex - 2)
				if nil == item then break end
				if not self:_checkInView(size, item) then
					break
				end
				self._headIndex = self._headIndex - 1
				item:addChild(self:_loadSource(self._headIndex))
			until false
			repeat -- remove tail
				item = ListView.getItem(self, self._tailIndex - 1)
				if self:_checkInView(size, item) then
					break
				end
				item:removeAllChildren()
				self:_unloadSource(self._tailIndex)
				self._tailIndex = self._tailIndex - 1
			until false
		else -- head out of view, jump scrolling
			-- remove all
			for i = self._headIndex, self._tailIndex do
				item = ListView.getItem(self, i - 1)
				item:removeAllChildren()
				self:_unloadSource(i)
				self._tailIndex = nil
			end
			-- find new head and tail
			repeat
				item = ListView.getItem(self, self._headIndex - 2)
				if nil == item then break end
				if self:_checkInView(size, item) then
					self._headIndex = self._headIndex - 1
					item:addChild(self:_loadSource(self._headIndex))
					if nil == self._tailIndex then
						self._tailIndex = self._headIndex
					end
				else
					if self._tailIndex then
						break
					else
						self._headIndex = self._headIndex - 1
					end
				end
			until false
		end
	end
end

--[[ external method, must be called at least once.
self: listview
index: make sure item of index is in viewRect, auto load and unload items.
]]--
local function jumpTo(self, index)
	self:stopAllActions()
	self:performWithDelay(function()
		local direction = self:getDirection()
		local size = self:getContentSize()

		local checkTab = {}
		local items = ListView.getItems(self)
		for i = self._headIndex, self._tailIndex do
			checkTab[i] = false
		end
		-- adjust scroll view
		local item = items[index]
		assert(index >= 1 and index <= #items, "Wrong index range")

		if 1 == direction then -- VERTICAL
			local destY = size.height - item:getPositionY() - item:getContentSize().height
			destY = math.min(0, destY)
			self:getInnerContainer():setPositionY(destY)
			self._innerP = destY
		else
			local destX = size.width - item:getPositionX() - item:getContentSize().width
			destX = math.min(0, destX)
			self:getInnerContainer():setPositionX(destX)
			self._innerP = destX
		end
		-- find items in viewRect
		for i = index, 1, -1 do
			if not self:_checkInView(size, items[i]) then
				break
			end
			self._headIndex = i
		end
		for i = index, #items do
			if not self:_checkInView(size, items[i]) then
				break
			end
			self._tailIndex = i
		end
		-- add new
		for i = self._headIndex, self._tailIndex do
			if nil == checkTab[i] then
				items[i]:addChild(self:_loadSource(i))
			end
			checkTab[i] = true
		end
		-- remove out of view
		for i, k in pairs(checkTab) do
			if false == k then
				items[i]:removeAllChildren()
				self:_unloadSource(i)
			end
		end
	end, 0)
end

local function createDefaultWidget()
	local layer = ccui.Layout:create()
	-- layer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	-- layer:setBackGroundColor(cc.c3b(0, 0, 255))
	return layer
end

-- init default items, _sizeSource() will be use in this stage
local function initDefaultItems(self, total)
	local items = ListView.getItems(self)
	local oldTotal = #items
	-- remove old items and reset cursor
	for i = self._headIndex, self._tailIndex do
		items[i]:removeAllChildren()
	end
	self._headIndex = 0
	self._tailIndex = -1
	self._innerP = nil
	-- clean defaut widgets
	ListView.removeAllItems(self)
	-- size may change, so need to add defaut widgets again
	for i = 1, total do
		local widget = createDefaultWidget()
		widget:setContentSize(self:_sizeSource(i))
		ListView.pushBackCustomItem(self, widget)
	end
end

local function insertRow(self, index)
	local widget = createDefaultWidget()
	widget:setContentSize(self:_sizeSource(index))
	ListView.insertCustomItem(self, widget, index - 1)

	if index > self._tailIndex then
		return -- no need to change cursor
	end

	if index <= self._headIndex then
		index = self._headIndex
	end
	local item = ListView.getItem(self, index - 1)
	item:addChild(self:_loadSource(index))

	self._tailIndex = self._tailIndex + 1
end

local function deleteRow(self, index)
	ListView.removeItem(self, index - 1)

	if index > self._tailIndex then
		return -- no need to change cursor
	end

	if index < self._headIndex then
		self._headIndex = self._headIndex - 1
	else
		self:_unloadSource(index)
	end

	local item = ListView.getItem(self, self._tailIndex - 1)
	if item then
		item:addChild(self:_loadSource(self._tailIndex))
	else
		self._tailIndex = self._tailIndex - 1
	end
end

--[[ convert a ccui.ListView -> TableView
listview, is a instance of ccui.ListView
sizeSource = function(self, index)
	return cc.size(100, 50)
end
loadSource = function(self, index)
	return display.newNode() -- which size is equal to sizeSource(index)
end
unloadSource = function(self, index)
	print("You can unload texture of index here")
end

note:	listview:addScrollViewEventListener() MUST call after TableView.attachTo()
]]--
function TableView.attachTo(listview, sizeSource, loadSource, unloadSource)
	-- new internal data
	listview._sizeSource = sizeSource
	listview._loadSource = function(self, index)
		local node = loadSource(self, index)
		node:ignoreAnchorPointForPosition(false)
		node:setAnchorPoint(cc.p(0, 0))
		node:pos(0, 0)
		return node
	end
	listview._unloadSource = unloadSource

	-- multiple calls protection
	if listview._headIndex then
		return
	end

	listview._headIndex = 0 -- init to defaut cursor
	listview._tailIndex = -1 -- init to defaut cursor
	-- hide ccui.ListView 's item methods
	local function protectInfo ()
		assert(nil, "The ListView method is protected by TableView")
	end
	listview.pushBackDefaultItem = protectInfo
	listview.insertDefaultItem = protectInfo
	listview.pushBackCustomItem = protectInfo
	listview.insertCustomItem = protectInfo
	listview.removeLastItem = protectInfo
	listview.removeItem = protectInfo
	listview.removeAllItems = protectInfo
	listview.getItem = protectInfo
	listview.getItems = protectInfo
	listview.getIndex = protectInfo
	-- new internal mothods
	listview._checkInView = checkInView
	listview._scrolling = scrolling
	-- new external mothods
	listview.jumpTo = jumpTo
	listview.initDefaultItems = initDefaultItems
	listview.insertRow = insertRow
	listview.deleteRow = deleteRow

	-- init event
	listview:addScrollViewEventListener(function(self, type)
		if type == 4 then -- SCROLLING
			-- avoid crash while remove touch node in scrolling event
			self:performWithDelay(function()
				self:_scrolling()
			end, 0)
		end
		if self._scrollCB then
			self:_scrollCB(type)
		end
	end)
	listview.addScrollViewEventListener = function(self, cb)
		self._scrollCB = cb
	end
end

return TableView
