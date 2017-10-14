local htmlparser = import(".htmlparser")
local LabelTTFEx = import(".LabelTTFEx")

local RichTextEx = class("RichTextEx", function()
	return ccui.RichText:create()
end)

local string = string
local ipairs = ipairs
local tonumber = tonumber

-- wapper this with project
local defaultFont = "0_UIPic/gamefont.TTF"
local defaultFontSize = 24
local defaultFontColor = cc.c3b(255, 255, 255)

-- #RRGGBB/#RGB to c3b
local function c3b_parse(s)
	local r, g, b = 0, 0, 0
	if #s == 4 then
		r = tonumber(string.rep(string.sub(s, 2, 2), 2), 16)
		g = tonumber(string.rep(string.sub(s, 3, 3), 2), 16)
		b = tonumber(string.rep(string.sub(s, 4, 4), 2), 16)
	elseif #s == 7 then
		r = tonumber(string.sub(s, 2, 3), 16)
		g = tonumber(string.sub(s, 4, 5), 16)
		b = tonumber(string.sub(s, 6, 7), 16)
	end
	return cc.c3b(r, g, b)
end

--[[
用法：
local RichTextEx = require("app.utils.RichTextEx")
local clickDeal = function(id, content)
	print(id, content)
end

RichTextEx.new([==[
<t c="#f00" s="50" id="click">Hello World!</t><br><i s="0_DEMO/icon/baogao_2.png" id="iamgeaa"></i>
]==], clickDeal)
	:addTo(self)
	:center()
]]--

-- do not support nesting
function RichTextEx:ctor(str, callback)
	local root = htmlparser.parse(str)
	self._callback = callback
	self:render(root.nodes)
end

function RichTextEx:render(nodes)
	local addTouch = function(target, id, content)
		target:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
			if event.name == "began" then
				return true
			end
			if event.name == "ended" then
				if self._callback then
					self._callback(id, content)
				end
			end
		end)
		target:setTouchEnabled(true)
	end

	local tag = {
		t = function(e) -- text
			local font = e.attributes.f or defaultFont
			local size = defaultFontSize
			if e.attributes.s then
				size = tonumber(e.attributes.s)
			end
			local color = defaultFontColor
			if e.attributes.c then
				color = c3b_parse(e.attributes.c)
			end
			local label = LabelTTFEx.new(e:getcontent(), font, size, color)
			if e.attributes.id then
				addTouch(label, e.attributes.id, e:getcontent())
				label:enableUnderLine()
			end
			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, label)
		end,
		i = function(e) -- image
			local isSpriteFrame = 0
			local src = e.attributes.s
			if string.byte(src, 1) == 35 then -- # spriteframe
				src = string.sub(src, 2)
				isSpriteFrame = 1
			end
			local image = ccui.ImageView:create(e.attributes.s, isSpriteFrame)
			local size = image:getContentSize()
			if e.attributes.w then
				size.width = tonumber(e.attributes.w)
			end
			if e.attributes.h then
				size.height = tonumber(e.attributes.h)
			end
			image:ignoreContentAdaptWithSize(false)
			image:setContentSize(size)
			if e.attributes.id then -- set underline for clicked text
				addTouch(image, e.attributes.id, src)
			end
			return ccui.RichElementCustomNode:create(0, display.COLOR_WHITE, 255, image)
		end,
		br = function(e) -- break
			return ccui.RichElementNewLine:create(0, display.COLOR_WHITE, 255)
		end,
	}

	for _, e in ipairs(nodes) do
		local element = tag[e.name](e)
		self:pushBackElement(element)
	end
end

return RichTextEx
