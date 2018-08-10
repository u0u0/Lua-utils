local creator = {}
local cc = cc
local spriteFrameCache = cc.SpriteFrameCache:getInstance()

local function loadFrames(spriteFrames)
	for _, info in ipairs(spriteFrames) do
		-- fix the value
		info.rect.width = info.rect.w
		info.rect.height = info.rect.h
		info.originalSize.width = info.rect.w
		info.originalSize.height = info.rect.h
		local frame = cc.SpriteFrame:create(
			info.texturePath,
			info.rect,
			info.rotated,
			info.offset,
			info.originalSize
		)
		-- XXX: info.centerRect is not use in Quick
		-- info.centerRect.width = info.centerRect.w
		-- info.centerRect.height = info.centerRect.h
		if frame then
			spriteFrameCache:addSpriteFrame(frame, info.name)
			print("Added frame:" .. info.name)
		end
	end
end

local function parseNode(obj, node)
	-- node.colliders, node.groupIndex not support
	obj:setAnchorPoint(node.anchorPoint)
	obj:setCascadeOpacityEnabled(node.cascadeOpacityEnabled)
	if node.color then
		obj:setColor(node.color)
	end
	if node.contentSize then
		obj:setContentSize(node.contentSize)
	end
	obj:setVisible(node.enabled)
	if node.globalZOrder then
		obj:setGlobalZOrder(node.globalZOrder)
	end
	obj:setLocalZOrder(node.localZOrder)
	obj:setOpacity(node.opacity)
	obj:setOpacityModifyRGB(node.opacityModifyRGB)
	if node.tag then
		obj:setTag(node.tag)
	end
	obj.name = node.name
	if node.position then
		obj:setPosition(node.position.x, node.position.y)
	end
	if node.rotationSkewX then
		obj:setRotationSkewX(node.rotationSkewX)
	end
	if node.rotationSkewY then
		obj:setRotationSkewY(node.rotationSkewY)
	end
	if node.scaleX then
		obj:setScaleX(node.scaleX)
	end
	if node.scaleY then
		obj:setScaleY(node.scaleY)
	end
	if node.skewX then
		obj:setSkewX(node.skewX)
	end
	if node.skewY then
		obj:setSkewY(node.skewY)
	end

	return obj
end

local nodeFactory = {
	Scene = function(object)
		local node = cc.Node:create() -- use node replace with scene
		return parseNode(node, object.node)
	end,
	Node = function(object)
		local node = cc.Node:create()
		return parseNode(node, object)
	end,
	Sprite = function(object)
		-- FIXME sizeMode?spriteType?trimEnabled?
		local sprite = cc.Sprite:createWithSpriteFrameName(object.spriteFrameName)
		sprite:setBlendFunc(object.srcBlend, object.dstBlend)
		return parseNode(sprite, object.node)
	end,
	EditBox = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	Button = function(object)
		local btn = ccui.Button:create(object.spriteFrameName, object.pressedSpriteFrameName,
			object.disabledSpriteFrameName, 1)
		return parseNode(btn, object.node)
	end,
	Label = function(object)
		local text = ccui.Text:create(object.labelText, object.fontName, object.fontSize)
		text:setTextColor(object.node.color)
		-- horizontalAlignment
		if "Left" == object.horizontalAlignment then
			text:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		elseif "Center" == object.horizontalAlignment then
			text:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		else
			text:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
		end
		-- verticalAlignment
		if "Bottom" == object.verticalAlignment then
			text:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM)
		elseif "Center" == object.verticalAlignment then
			text:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		else
			text:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
		end
		-- FIXME overflowType?enableWrap?lineHeight?enableWrap?
		object.node.color = nil -- cancel node setting
		object.node.contentSize = nil -- make Lable do it own size
		return parseNode(text, object.node)
	end,
	ScrollView = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	Toggle = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	ToggleGroup = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	Slider = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
}

local function adjustPosition(node)
	local parent = node:getParent()
	local p_ap = parent:getAnchorPoint()
	local p_cs = parent:getContentSize()
	local offsetX = p_ap.x * p_cs.width
	local offsetY = p_ap.y * p_cs.height
	node:setPosition(node:getPositionX() + offsetX, node:getPositionY() + offsetY)
end

local function parseRoot(root)
	if not nodeFactory[root.object_type] then
		print("Unsupport node tpye:", root.object_type)
		return
	end

	local rootNode = nodeFactory[root.object_type](root.object)
	for _, child in ipairs(root.children) do
		local node = parseRoot(child)
		rootNode:addChild(node)
		adjustPosition(node)
	end
	return rootNode
end

function creator.parseJson(file)
	local data = cc.FileUtils:getInstance():getDataFromFile(file)
	local tab = json.decode(data)
	if not tab then
		print("==Fail to parse json from file:", file)
		return
	end

	print(tab.version)

	loadFrames(tab.spriteFrames)
	return parseRoot(tab.root)
end

return creator
