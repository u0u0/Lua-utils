local TableViewCell = class("TableViewCell", function()
	return cc.Node:create()
end)

function TableViewCell:ctor()
	self.index = 0
end

function TableViewCell:setIndex(index)
	self.index = index
end

function TableViewCell:getIndex(index)
	return self.index
end

function TableViewCell:reset()
	self.index = 0
end



local TableView = class("TableView", function()
	return ccui.ScrollView:create()
end)

local TableViewDirection = {
	none = 0,
	vertical = 1,
	horizontal = 2
}

local TableViewFuncType = {
	cellSize = "_cellSizeAtIndex",		--获取cell size,返回width, height
	cellNum = "_numberOfCells",			--获取cell数量
	cellLoad = "_loadCellAtIndex",		--加载cell，必须返回一个cell
	cellUnload = "_unloadCellAtIndex"	--卸载一个cell时触发
}

local TableViewFillOrder = {
	topToBottom = 1,
	bottomToTop = 2,
	leftToRight = 3,
	rightToLeft = 4
}

function TableView:ctor(size)
	self._cellsPos = {}	--记录每个cell的位置

	self._cellsUsed = {} --记录正在使用的cell
	self._cellsIndex = {} --记录正在使用的cell的index
	self._cellsFreed = {} --记录当前未使用的cell

	self.direction = TableViewDirection.none
	self.fillOrder = TableViewFillOrder.topToBottom

	self:addEventListener(function (self, type)
		if type >= 4 then
			self:_scrollViewDidScroll()
		end
	end)
	self:setBounceEnabled(true)

	self:init(size)
end

function TableView:init(size)
	self:setContentSize(size or cc.size(0, 0))
	self:_updateCellsPosition()
	self:_updateContentSize()
end

--[[
    @desc: 注册TableViewFuncType定义的方法
    author:BogeyRuan
    time:2019-08-14 09:48:58
    --@type:
	--@func: 
    @return:
]]
function TableView:registerFunc(type, func)
	assert(self[type], "Invalid func type")
	self[type] = func
end

--[[
    @desc: 获取index位置上的cell，可能为空
    author:BogeyRuan
    time:2019-08-14 09:49:28
    --@index: 
    @return:
]]
function TableView:cellAtIndex(index)
	if self._cellsIndex[index] then
		for k,v in pairs(self._cellsUsed) do
			if v:getIndex() == index then
				return v, k
			end
		end
	end
end

--[[
    @desc: 重新加载
    author:BogeyRuan
    time:2019-08-13 18:32:31
    @return:
]]
function TableView:reloadData()
	self.direction = TableViewDirection.none

	local cell = table.remove(self._cellsUsed, 1)
	while cell do
		cell:setVisible(false)
		table.insert(self._cellsFreed, cell)
		cell:reset()
		cell = table.remove(self._cellsUsed, 1)
	end
	self._cellsUsed = {}
	self._cellsIndex = {}

	self:_updateCellsPosition()
	self:_updateContentSize()

	if self:_numberOfCells() > 0 then
		self:_scrollViewDidScroll()
	end
end

--[[
    @desc: 在尽量不改变位置的情况下重新加载
    author:BogeyRuan
    time:2019-08-13 18:32:45
    @return:
]]
function TableView:reloadDataInPos()
	local baseSize = self:getContentSize()
	local x, y = self:getInnerContainer():getPosition()
	local beforeSize = self:getInnerContainerSize()

	local cell = table.remove(self._cellsUsed, 1)
	while cell do
		cell:setVisible(false)
		table.insert(self._cellsFreed, cell)
		cell:reset()
		cell = table.remove(self._cellsUsed, 1)
	end
	self._cellsUsed = {}
	self._cellsIndex = {}

	self:_updateCellsPosition()
	self:_updateContentSize()

	local afterSize = self:getInnerContainerSize()
	if afterSize.width < baseSize.width or afterSize.height < baseSize.height then
		self:_setInnerContainerInitPos()
	else
		local offset = cc.p(x, beforeSize.height - afterSize.height + y)
		offset = cc.p(math.max(offset.x, baseSize.width - afterSize.width), math.min(0, offset.y))
		self:getInnerContainer():setPosition(offset)
	end

	if self:_numberOfCells() > 0 then
		self:_scrollViewDidScroll()
	end
end

--[[
    @desc: 返回一个闲置的cell，可能为空
    author:BogeyRuan
    time:2019-08-13 18:33:26
    @return:
]]
function TableView:dequeueCell()
	return table.remove(self._cellsFreed, 1)
end

--[[
    @desc: 设置填充方向，对竖着滚动的有效
    author:BogeyRuan
    time:2019-08-13 18:33:55
    --@order: 
    @return:
]]
function TableView:setFillOrder(order)
	if self.fillOrder ~= order then
		self.fillOrder = order
		if #self._cellsUsed > 0 then
			self:reloadData()
		end
	end
end

--[[
    @desc: 根据index更新cell
    author:BogeyRuan
    time:2019-08-13 18:34:37
    --@index: 
    @return:
]]
function TableView:updateCellAtIndex(index)
	if index <= 0 then
		return
	end
	local cellsCount = self:_numberOfCells()
	if cellsCount == 0 or index > cellsCount then
		return
	end
	local cell, newIndex = self:cellAtIndex(index)
	if cell then
		self:_moveCellOutOfSight(cell, newIndex)
	end
	cell = self:_loadCellAtIndex(index)
	self:_setIndexForCell(index, cell)
	self:_addCellIfNecessary(cell)
end

--[[
    @desc: 在index位置插入
    author:BogeyRuan
    time:2019-08-13 18:35:04
    --@index: 
    @return:
]]
function TableView:insertCellAtIndex(index)
	if index <= 0 then
		return
	end
	local cellsCount = self:_numberOfCells()
	if cellsCount == 0 or index > cellsCount then
		return
	end
	local cell, newIndex = self:cellAtIndex(index)
	if cell then
		for i = newIndex, #self._cellsUsed do
			cell = self._cellsUsed[i]
			self:_setIndexForCell(cell:getIndex() + 1, cell)
			self._cellsIndex[cell:getIndex()] = true
		end
	end

	cell = self:_loadCellAtIndex(index)
	self:_setIndexForCell(index, cell)
	self:_addCellIfNecessary(cell)

	self:_updateCellsPosition()
	self:_updateContentSize()
end

--[[
    @desc: 移除index位置的cell
    author:BogeyRuan
    time:2019-08-13 18:35:22
    --@index: 
    @return:
]]
function TableView:removeCellAtIndex(index)
	if index <= 0 then
		return
	end
	local cellsCount = self:_numberOfCells()
	if cellsCount == 0 or index > cellsCount then
		return
	end
	local cell, newIndex = self:cellAtIndex(index)
	if cell then
		self:_moveCellOutOfSight(cell, newIndex)
		self:_updateCellsPosition()
		local cellSize = #self._cellsUsed
		for i = cellSize, newIndex, -1 do
			cell = self._cellsUsed[i]
			if i == cellSize then
				self._cellsIndex[cell:getIndex()] = nil
			end
			self:_setIndexForCell(cell:getIndex() - 1, cell)
			self._cellsIndex[cell:getIndex()] = true
		end
	end
end
--------------------------------------------------

function TableView:_scrollViewDidScroll()
	local cellsCount = self:_numberOfCells()
	if cellsCount <= 0 then
		return
	end

	local baseSize = self:getContentSize()
	if self._isUsedCellsDirty then
		self._isUsedCellsDirty = false
		table.sort(self._cellsUsed, function(a, b)
			return a:getIndex() < b:getIndex()
		end)
	end

	local startIdx, endIdx, idx, maxIdx = 0, 0, 0, 0
	local offset = cc.p(self:getInnerContainer():getPosition())
	offset = cc.p(-offset.x, -offset.y)
	maxIdx = math.max(cellsCount, 1)
	if self.fillOrder == TableViewFillOrder.topToBottom then
		offset.y = offset.y + baseSize.height
	elseif self.fillOrder == TableViewFillOrder.rightToLeft then
		offset.x = offset.x + baseSize.width
	end
	startIdx = self:_indexFromOffset(clone(offset)) or maxIdx

	if self.fillOrder == TableViewFillOrder.topToBottom then
		offset.y = offset.y - baseSize.height
	elseif self.fillOrder == TableViewFillOrder.bottomToTop then
		offset.y = offset.y + baseSize.height
	end
	if self.fillOrder == TableViewFillOrder.leftToRight then
		offset.x = offset.x + baseSize.width
	elseif self.fillOrder == TableViewFillOrder.rightToLeft then
		offset.x = offset.x - baseSize.width
	end
	endIdx = self:_indexFromOffset(clone(offset)) or maxIdx

	if #self._cellsUsed > 0 then --移除顶部节点
		local cell = self._cellsUsed[1]
		idx = cell:getIndex()
		while idx < startIdx do
			self:_moveCellOutOfSight(cell, 1)
			if #self._cellsUsed > 0 then
				cell = self._cellsUsed[1]
				idx = cell:getIndex()
			else
				break
			end
		end
	end

	if #self._cellsUsed > 0 then --移除底部节点
		local cell = self._cellsUsed[#self._cellsUsed]
		idx = cell:getIndex()
		while idx <= maxIdx and idx > endIdx do
			self:_moveCellOutOfSight(cell, #self._cellsUsed)
			if #self._cellsUsed > 0 then
				cell = self._cellsUsed[#self._cellsUsed]
				idx = cell:getIndex()
			else
				break
			end
		end
	end

	for i = startIdx, endIdx do --更新节点
		if not self._cellsIndex[i] then
			self:updateCellAtIndex(i)
		end
	end
end


function TableView:_setIndexForCell(index, cell)
	cell:setAnchorPoint(cc.p(0, 0))
	cell:setPosition(self:_offsetFromIndex(index))
	cell:setIndex(index)
end

function TableView:_moveCellOutOfSight(cell, index)
	table.insert(self._cellsFreed, table.remove(self._cellsUsed, index))
	self._cellsIndex[cell:getIndex()] = nil
	self._isUsedCellsDirty = true
	self:_unloadCellAtIndex(cell:getIndex())

	cell:reset()
	cell:setVisible(false)
end

function TableView:_addCellIfNecessary(cell)
	cell:setVisible(true)
	if cell:getParent() ~= self:getInnerContainer() then
		self:addChild(cell)
	end
	table.insert(self._cellsUsed, cell)
	self._cellsIndex[cell:getIndex()] = true
	self._isUsedCellsDirty = true
end

function TableView:_indexFromOffset(offset)
	local size = self:getInnerContainerSize()
	if self.fillOrder == TableViewFillOrder.topToBottom then
		offset.y = size.height - offset.y
	elseif self.fillOrder == TableViewFillOrder.rightToLeft then
		offset.x = size.width - offset.x
	end
	local search
	if self.direction == TableViewDirection.horizontal then
		search = offset.x
	else
		search = offset.y
	end

	local low = 1
	local high = self:_numberOfCells()
	while high >= low do
		local index = math.floor(low + (high - low) / 2)
		local cellSatrt = self._cellsPos[index]
		local cellEnd = self._cellsPos[index + 1]
		if search >= cellSatrt and search <= cellEnd then
			return index
		elseif search < cellSatrt then
			high = index - 1
		else
			low = index + 1
		end
	end
	if low <= 1 then
		return 1
	end
end

function TableView:_offsetFromIndex(index)
	local offset
	if self.direction == TableViewDirection.horizontal then
		offset = cc.p(self._cellsPos[index], 0)
	else
		offset = cc.p(0, self._cellsPos[index])
	end
	local cellSize = cc.size(self:_cellSizeAtIndex(index))
	if self.fillOrder == TableViewFillOrder.topToBottom then
		offset.y = self:getInnerContainerSize().height - offset.y - cellSize.height
	elseif self.fillOrder == TableViewFillOrder.rightToLeft then
		offset.x = self:getInnerContainerSize().width - offset.x - cellSize.width
	end
	return offset
end

function TableView:_updateContentSize()
	local baseSize = self:getContentSize()
	local size = self:getInnerContainerSize()
	local cellsCount = self:_numberOfCells()
	local dir = self:getDirection()

	if cellsCount > 0 then
		local maxPos = self._cellsPos[#self._cellsPos]
		if dir == TableViewDirection.horizontal then
			size.width = math.max(baseSize.width, maxPos)
		else
			size.height = math.max(baseSize.height, maxPos)
		end
	end
	self:getInnerContainer():setContentSize(size)
	self:_setInnerContainerInitPos()
end

function TableView:_setInnerContainerInitPos()
	local dir = self:getDirection()
	if self.direction ~= dir then
		if dir == TableViewDirection.horizontal then
			if self.fillOrder == TableViewFillOrder.leftToRight then
				self:getInnerContainer():setPosition(cc.p(0, 0))
			elseif self.fillOrder == TableViewFillOrder.rightToLeft then
				self:getInnerContainer():setPosition(cc.p(self:_getMinContainerOffset().x, 0))
			end
		else
			if self.fillOrder == TableViewFillOrder.topToBottom then
				self:getInnerContainer():setPosition(cc.p(0, self:_getMinContainerOffset().y))
			elseif self.fillOrder == TableViewFillOrder.bottomToTop then
				self:getInnerContainer():setPosition(cc.p(0, 0))
			end
		end
		self.direction = dir
	end
end

function TableView:_updateCellsPosition()
	local cellsCount = self:_numberOfCells()
	self._cellsPos = {}

	if cellsCount > 0 then
		local curPos = 0
		local cellSize
		local dir = self:getDirection()
		for i = 1, cellsCount do
			table.insert(self._cellsPos, curPos)
			cellSize = cc.size(self:_cellSizeAtIndex(i))
			if dir == TableViewDirection.horizontal then
				curPos = curPos + cellSize.width
			else
				curPos = curPos + cellSize.height
			end
		end
		table.insert(self._cellsPos, curPos) --多添加一个可以用来获取最后一个cell的右侧或者底部
	end
end

function TableView:_getMinContainerOffset()
	local con = self:getInnerContainer()
	local ap = con:getAnchorPoint()
	local conSize = con:getContentSize()
	local baseSize = self:getContentSize()
	return cc.p(baseSize.width - (1 - ap.x) * conSize.width, baseSize.height - (1 - ap.y) * conSize.height)
end

--------------------------------------------------
function TableView:_cellSizeAtIndex(index)
	return 0, 0
end

function TableView:_numberOfCells()
	return 0
end

function TableView:_loadCellAtIndex(index)
	local cell = self:dequeueCell()
	if not cell then
		return TableViewCell.new()
	end
	return cell
end

function TableView:_unloadCellAtIndex(index)
end

cc.TableView = TableView
cc.TableViewCell = TableViewCell
cc.TableViewFillOrder = TableViewFillOrder
cc.TableViewDirection = TableViewDirection
cc.TableViewFuncType = TableViewFuncType