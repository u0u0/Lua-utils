local Updater = {}

local scheduler = require("framework.scheduler")
local FileUtils = cc.FileUtils:getInstance()
local maxHTTPRequest = 5
local configFileName = "version.json"
local extName = "URes"
local extTmpName = "UTmp"
local writablePath = string.gsub(FileUtils:getWritablePath(), "\\", "/")
local extPath = writablePath .. extName .. "/"
local extTmp = writablePath .. extTmpName .. "/"
local cpu = "32"
if jit.arch:sub(-2) == "64" then
	cpu = "64"
end

-- ********** internal function ********
local function copyFile(src, dest)
	local buf = FileUtils:getDataFromFile(src)
	if buf then
		local pInfo = io.pathinfo(dest)
		if false == FileUtils:isDirectoryExist(pInfo.dirname) then
			FileUtils:createDirectory(pInfo.dirname) -- Create path recursively
		end
		FileUtils:writeStringToFile(buf, dest)
	end
end

local function saveFile(path, buf)
	local pInfo = io.pathinfo(path)
	if false == FileUtils:isDirectoryExist(pInfo.dirname) then
		FileUtils:createDirectory(pInfo.dirname) -- Create path recursively
	end
	FileUtils:writeStringToFile(buf, path)
end

-- compare the string version, return true if need doUpdate
local function checkVersion(my, server)
	my = string.split(my, ".")
	server = string.split(server, ".")
	for i = 1, 3 do
		mVer = tonumber(my[i])
		mSver = tonumber(server[i])
		if mVer < mSver then
			return true
		elseif mVer > mSver then
			return false
		end
	end
	return false
end

local function isNeedDownload(name, md5)
	-- check game packages is need for this device
	if string.sub(name, #name - 3) == ".zip" then
		if string.sub(name, #name - 5, #name - 4) ~= cpu then
			return false
		end
	end
	-- check if downloaded
	local path = extTmp .. name
	if FileUtils:isFileExist(path) and crypto.md5file(path) == md5 then
		return false
	end
	return true
end

-- check if the remain file is OK
local function isRemainOK(name, md5)
	local path = FileUtils:fullPathForFilename(name)
	if string.find(path, extPath, 1, true) == 1 then -- ext files
		if FileUtils:isFileExist(path) and crypto.md5file(path) == md5 then
			copyFile(path, extTmp .. name) -- copy extPath => extTmp
			return true
		end
		return false
	end
	-- apk files always OK
	return true
end

local function getDiff(my, server)
	local change = {}
	local size = 0

	local serverAsserts = server.asserts
	for k, v in pairs(my.asserts) do
		local value = serverAsserts[k]
		if value then
			-- get changing files
			if value[1] ~= v[1] then
				if isNeedDownload(k, value[1]) then
					table.insert(change, {url = k, total = value[2]})
					size = size + value[2]
				end
			else
				if not isRemainOK(k, value[1]) then
					table.insert(change, {url = k, total = value[2]})
					size = size + value[2]
				end
			end
			value.checked = true
		end
	end

	for k, value in pairs(serverAsserts) do
		if value.checked then -- clean tmp value
			value.checked = nil
		else -- get new adding files
			if isNeedDownload(k, value[1]) then
				size = size + value[2]
				table.insert(change, {url = k, total = value[2]})
			end
		end
	end

	return {
		change = change,
		size = size,
		packages = server.packages,
	}
end

local function doUpdate(url, callback, info)
	-- info UI to update the size
	callback(2, info.size, 0)

	-- http download dealing
	local curHttp = 0
	local totalGetSize = 0
	local totalErrorCount = 0

	local notifySize = function(diff)
		totalGetSize = totalGetSize + diff
		callback(2, info.size, totalGetSize)
	end

	local notifyError = function(downInfo)
		curHttp = curHttp - 1
		totalErrorCount = totalErrorCount + 1
		notifySize(-downInfo.getSize) -- cancel getting size
		downInfo.isReqed = nil
		downInfo.getSize = nil
	end

	local newRequest = function(index)
		local downInfo = info.change[index]
		local downUrl = url .. "/" .. downInfo.url
		local request = network.createHTTPDownload(function(event)
			local request = event.request
			if event.name == "completed" then
				local code = request:getResponseStatusCode()
				if code ~= 200 and code ~= 206 then
					notifyError(downInfo)
					return
				end

				-- info size
				curHttp = curHttp - 1
				local diff = request:getResponseDataLength() - downInfo.getSize
				notifySize(diff)
				-- mark downloaded
				info.change[index] = nil
				if totalErrorCount > 0 then -- optimize for remove error count
					totalErrorCount = totalErrorCount - 1
				end
			elseif event.name == "progress" then
				local diff = event.dltotal - downInfo.getSize
				notifySize(diff)
				downInfo.getSize = event.dltotal
			else
				notifyError(downInfo)
			end
		end, downUrl, extTmp .. downInfo.url)

		-- add downloading mark
		downInfo.isReqed = true -- is downloading
		downInfo.getSize = 0 -- downloaded size
		curHttp = curHttp + 1
		request:start()
	end

	Updater._scheduler = scheduler.scheduleUpdateGlobal(function()
		-- check exit
		if 0 == table.nums(info.change) then
			scheduler.unscheduleGlobal(Updater._scheduler)
			-- remove extPath, then rename extTmp -> extPath
			FileUtils:removeDirectory(extPath)
			FileUtils:renameFile(writablePath, extTmpName, extName)
			FileUtils:purgeCachedEntries() -- clear filename search cache
			-- reload game.zip, purgeCachedData
			for _, zip in ipairs(info.packages) do
				cc.LuaLoadChunksFromZIP(zip .. cpu .. ".zip")
			end
			cc.Director:getInstance():purgeCachedData()
			-- notify to start play scene
			__UpdaterInited = nil
			callback(1)
			return
		end
		-- no downloading, and reach the maxHTTPRequest
		if 0 == curHttp and totalErrorCount >= maxHTTPRequest then
			scheduler.unscheduleGlobal(Updater._scheduler)
			callback(5, -1)
			return
		end
		-- a request per frame event
		if curHttp < maxHTTPRequest and table.nums(info.change) > curHttp then
			for index, downInfo in pairs(info.change) do
				if true ~= downInfo.isReqed then
					newRequest(index)
					break
				end
			end
		end
	end)
end

local function checkUpdate(url, callback)
	-- we had set SearchPath, so we will get the right file
	local data = FileUtils:getDataFromFile(configFileName)
	assert(data, "Error: fail to get data from config.json")
	data = json.decode(data)
	assert(data, "Error: fail to parser config.json")

	-- get version.json
	local request = network.createHTTPRequest(function(event)
		local request = event.request
		if event.name == "completed" then
			local code = request:getResponseStatusCode()
			if code ~= 200 then
				callback(4, code)
				return
			end

			-- do the real things
			local response = request:getResponseString()
			response = json.decode(response)
			if checkVersion(data.EngineVersion, response.EngineVersion) then
				callback(6)
			elseif checkVersion(data.GameVersion, response.GameVersion) then
				-- save config
				saveFile(extTmp .. configFileName, request:getResponseData())
				local info = getDiff(data, response)
				if network.isLocalWiFiAvailable() then
					doUpdate(url, callback, info)
				else -- need UI pop confirm to continue
					callback(7, info.size, function()
						doUpdate(url, callback, info)
					end)
				end
			else
				print("== no need update")
				__UpdaterInited = nil
				callback(1)
			end
		elseif event.name == "progress" then
			-- print("progress" .. event.dltotal)
		else
			callback(5, request:getErrorCode())
		end
	end, url .. "/" .. configFileName, "GET")
	request:setTimeout(30)
	request:start()
end

local function getHeadUrl(headUrl, callback)
	if not network.isInternetConnectionAvailable() then
		callback(3)
		return
	end

	local request = network.createHTTPRequest(function(event)
		local request = event.request
		if event.name == "completed" then
			local code = request:getResponseStatusCode()
			if code ~= 200 then
				callback(4, code)
				return
			end

			-- get head version url, start get version json
			local url = request:getResponseString()
			url = string.gsub(url, "[\n\r]", "") -- remove newline
			checkUpdate(url, callback)
		elseif event.name == "progress" then
			-- print("progress" .. event.dltotal)
		else
			callback(5, request:getErrorCode())
		end
	end, headUrl, "GET")
	request:setTimeout(15)
	request:start()
end

--[[ apk's "res/game32.zip" had been loaded by cpp code.
check and load the right package's, then restart the LoadingScene
callback(code, param1, param2)
	1 success
	2 update(param1:total, param2:cur)
	3 Network connect fail
	4 HTTP Server error(param1:httpCode)
	5 HTTP request error(param1:requestCode)
	6 EngineVersion old, need apk or ipa update
	7 Need update, (param1:total, param2:func), wait UI check WIFI.
--]]
function Updater.init(sceneName, headUrl, callback)
	if __UpdaterInited then
		-- extends loaded, start the network checking now
		getHeadUrl(headUrl, callback)
		return
	end
	__UpdaterInited = true

	-- get config in apk
	local sandbox = FileUtils:getDataFromFile("res/" .. configFileName)
	sandbox = json.decode(sandbox)
	-- add extPath before apk path
	FileUtils:setSearchPaths{extPath, "res/"}
	-- get config in URes or apk
	local data = FileUtils:getDataFromFile(configFileName)
	data = json.decode(data)
	if checkVersion(data.EngineVersion, sandbox.EngineVersion)
		or checkVersion(data.GameVersion, sandbox.GameVersion) then
		-- apk has update, so remove old URes.
		FileUtils:removeDirectory(extPath)
		FileUtils:purgeCachedEntries()
		data = sandbox -- use apk data to init
	end

	-- let the first frame display, and avoid to replaceScene in the scene ctor(BUG)
	scheduler.performWithDelayGlobal(function()
		-- load chunks
		for _, zip in ipairs(data.packages) do
			cc.LuaLoadChunksFromZIP(zip .. cpu .. ".zip")
		end
		print("== restarting", sceneName)
		cc.Director:getInstance():replaceScene(require(sceneName).new())
	end, 0)
end

return Updater
