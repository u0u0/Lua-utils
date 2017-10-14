local LabelTTFEx = class("LabelTTFEx", function()
	return cc.Node:create() -- for underline draw
end)

function LabelTTFEx:ctor(text, font, size, color)
	local font = font or display.DEFAULT_TTF_FONT
	local size = size or display.DEFAULT_TTF_FONT_SIZE
	local color = color or display.COLOR_WHITE
	self.color = color

	local label
	if cc.FileUtils:getInstance():isFileExist(font) then
		label = cc.Label:createWithTTF(text, font, size)
		label:setColor(color)
	else
		label = cc.Label:createWithSystemFont(text, font, size)
		label:setTextColor(color)
	end

	local size = label:getContentSize()
	label:pos(size.width / 2, size.height / 2):addTo(self)
	self.label = label

	self:setContentSize(size) -- for Richtext
	self:setAnchorPoint(cc.p(0.5, 0.5)) -- same as label
end

function LabelTTFEx:enableUnderLine()
	if self.line then return end

	local size = self:getContentSize()
	local borderWidth = size.height / 18
	local line = display.newLine(
		{{0, borderWidth / 2}, {size.width, borderWidth / 2}},
		{
			borderColor = cc.c4f(self.color.r / 255, self.color.g / 255, self.color.b / 255, 1.0),
			borderWidth = borderWidth
		}
	):addTo(self)
	self.line = line
	return self
end

function LabelTTFEx:enableItalics()
	self.label:setRotationSkewX(12)
	-- fix the contentSize
	local size = self:getContentSize()
	size.width = size.width * 1.02
	self:setContentSize(size)
	return self
end

-- ONLY worked for External font
function LabelTTFEx:enableBold()
	self.label:enableShadow(cc.c4b(self.color.r, self.color.g, self.color.b, 255), cc.size(0.9, 0), 0)
	return self
end

return LabelTTFEx
