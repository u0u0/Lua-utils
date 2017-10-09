local creator = {}
local cc = cc
local spriteFrameCache = cc.SpriteFrameCache:getInstance()

local function loadFrames(spriteFrames)
	for _, info in ipairs(spriteFrames) do
		local frame = cc.SpriteFrame:create(
			info.texturePath,
			info.rect,
			info.rotated,
			info.offset,
			info.originalSize
		)
		-- XXX: info.centerRect is not use in Quick
		if frame then
			spriteFrameCache:addSpriteFrame(frame, info.name)
			print("Added frame:" .. info.name)
		end
	end
end

local function parseNode(obj, node)
	dump(node)
	return obj
end

local nodeFactory = {
	Scene = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
	end,
	Sprite = function(object)
		local node = cc.Node:create()
		return parseNode(node, object.node)
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
		local node = cc.Node:create()
		return parseNode(node, object.node)
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

	if "0.2" ~= tab.version then
		print("== Unsupport ceator json verson.")
		return
	end

	loadFrames(tab.spriteFrames)
	return parseRoot(tab.root)
end

return creator
