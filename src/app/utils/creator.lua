local creator = {}
local cc = cc
local LabelTTFEx = import(".LabelTTFEx")
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
	obj:setContentSize(node.contentSize)
	obj:setVisible(node.enabled)
	obj:setGlobalZOrder(node.globalZOrder)
	obj:setGlobalZOrder(node.globalZOrder)
	obj:setLocalZOrder(node.localZOrder)
	obj:setOpacity(node.opacity)
	obj:setOpacityModifyRGB(node.opacityModifyRGB)
	obj:setTag(node.tag)
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
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	Label = function(object)
		local label = LabelTTFEx.new(object.labelText, object.fontName,
			object.fontSize, object.node.color)
		-- horizontalAlignment
		if "Left" == object.horizontalAlignment then
			label.label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		elseif "Center" == object.horizontalAlignment then
			label.label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		else
			label.label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
		end
		-- verticalAlignment
		if "Bottom" == object.verticalAlignment then
			label.label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM)
		elseif "Center" == object.verticalAlignment then
			label.label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		else
			label.label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
		end
		-- FIXME overflowType?enableWrap?lineHeight?enableWrap?
		object.node.color = nil -- cancel node setting
		return parseNode(label, object.node)
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

local function parseRoot(root)
	if not nodeFactory[root.object_type] then
		print("Unsupport node tpye:", root.object_type)
		return
	end

	local rootNode = nodeFactory[root.object_type](root.object)
	for _, child in ipairs(root.children) do
		rootNode:addChild(parseRoot(child))
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

	if "0.3" ~= tab.version then
		print("== Unsupport ceator json verson.")
		return
	end

	loadFrames(tab.spriteFrames)
	return parseRoot(tab.root)
end

return creator
