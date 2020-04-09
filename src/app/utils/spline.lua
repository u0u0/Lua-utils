local tableInsert = table.insert
local tablesort = table.sort
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local function point(x, y)
    return {x = x, y = y}
end

local function valuesOfKey(hashtable, key)
    local values = {}
    for k,v in pairs(hashtable) do
        if v[key] then
            values[k] = v[key]
        end
    end
    return values
end

--[[
    @desc: 根据点返回三次样条曲线
    author:Bogey
    time:2019-06-21 14:38:56
    --@points: 
    @return:
]]
local function spline(points)
    assert(#points >= 2, "A minimum of two points")
    tablesort(points, function (a, b)
        return a.x < b.x
    end)

    local xs = valuesOfKey(points, "x")
    local ys = valuesOfKey(points, "y")
    local ks = {}
    for i,v in ipairs(xs) do
        ks[i] = 0
    end

    local function zeroMat(r, c)
        local A = {}
        for i = 1, r do
            A[i] = {}
            for j = 1, c do
                A[i][j] = 0
            end
        end
        return A
    end

    local function swapRows(m, k, l)
        local p = m[k]
        m[k] = m[l]
        m[l] = p
    end

    local function maxMin(tb)
        local max, min
        for k,v in pairs(tb) do
            local value = tonumber(v) or 0
            if not max or max < value then
                max = value
            end
            if not min or min > value then
                min = value
            end
        end
        return max, min
    end

    local function solve(A, ks)
        local m = #A
        for k = 1, m do
            local i_max = 0
            local vali
            for i = k, m do
                if not vali or A[i][k] > vali then
                    i_max = i
                    vali = A[i][k]
                end
            end
            swapRows(A, k, i_max)
            for i = k + 2, m do
                for j = k + 2, m + 1 do
                    A[i][j] = A[i][j] - A[k][j] * (A[i][k] / A[k][k])
                end
                A[i][k] = 0
            end
        end
        for i = m, 1, -1 do
            local v = A[i][m + 1] / A[i][i]
            ks[i] = v
            for j = i, 1, -1 do
                A[j][m + 1] = A[j][m + 1] - A[j][i] * v
                A[j][i] = 0
            end
        end
        return ks
    end

    local function getNaturalKs(ks)
        local n = #xs
        local A = zeroMat(n, n + 1)

        for i = 2, n - 1 do
            A[i][i - 1] = 1 / (xs[i] - xs[i - 1])
            A[i][i] = 2 * (1 / (xs[i] - xs[i - 1]) + 1 / (xs[i + 1] - xs[i]))
            A[i][i + 1] = 1 / (xs[i + 1] - xs[i])
            A[i][n + 1] = 3 * ((ys[i] - ys[i - 1]) / ((xs[i] - xs[i - 1]) * (xs[i] - xs[i - 1])) + (ys[i + 1] - ys[i]) / ((xs[i + 1] - xs[i]) * (xs[i + 1] - xs[i])))
        end
        A[1][1] = 2 / (xs[2] - xs[1])
        A[1][2] = 1 / (xs[2] - xs[1])
        A[1][n + 1] = (3 * (ys[2] - ys[1])) / ((xs[2] - xs[1]) * (xs[2] - xs[1]))
        A[n][n - 1] = 1 / (xs[n] - xs[n - 1])
        A[n][n] = 2 / (xs[n] - xs[n - 1])
        A[n][n + 1] = (3 * (ys[n] - ys[n - 1])) / ((xs[n] - xs[n - 1]) * (xs[n] - xs[n - 1]))

        return solve(A, ks)
    end

    ks = getNaturalKs(ks)

    local function at(x)
        local i = 2
        while xs[i] < x do
            i = i + 1
        end
        local t = (x - xs[i - 1]) / (xs[i] - xs[i - 1])
        local a = ks[i - 1] * (xs[i] - xs[i - 1]) - (ys[i] - ys[i - 1])
        local b = -ks[i] * (xs[i] - xs[i - 1]) + (ys[i] - ys[i - 1])
        local q = (1 - t) * ys[i - 1] + t * ys[i] + t * (1 - t) * (a * (1 - t) + b * t)
        return q
    end

    local max, min = maxMin(xs)
    local points = {}
    for i = min, max do
        tableInsert(points, point(i, at(i)))
    end
    return points
end

return spline