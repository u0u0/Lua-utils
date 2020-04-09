local tableInsert = table.insert
local mathPow = math.pow
local ipairs = ipairs

local function YangHuiR3(line)
    local s = 1
    local nums = {1}
    for j = 1, line - 1 do
        s = (line - j) * s / j
        tableInsert(nums, s)
    end
    return nums
end

local function point(x, y)
    return {x = x, y = y}
end

--[[
    @desc: 根据控制点返回贝塞尔曲线
    author:Bogey
    time:2019-06-21 11:57:36
    --@points: 控制点
	--@segments: 采样，越大越平滑
    @return:
]]
local function bezier(points, segments)
    local pointNum = #points
    local nums = YangHuiR3(pointNum)
    local results = {points[1]}
    for i = 1, segments do
        local t = i / segments
        local x = 0
        local y = 0
        for k,v in ipairs(points) do
            x = x + nums[k] * mathPow(1 - t, pointNum - k) * mathPow(t, k - 1) * v.x
            y = y + nums[k] * mathPow(1 - t, pointNum - k) * mathPow(t, k - 1) * v.y
        end
        tableInsert(results, point(x, y))
    end
    return results
end

return bezier