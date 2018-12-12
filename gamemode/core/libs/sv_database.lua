nut.db = nut.db or {}
nut.util.include("nutscript/gamemode/config/sv_database.lua")

local function ThrowQueryFault(query, fault)
	if (isfunction(nut.db.onQueryError)) then
		return nut.db.onQueryError(query, fault)
	end
	MsgC(Color(255, 0, 0), "* "..query.."\n")
	MsgC(Color(255, 0, 0), fault.."\n")
end

local function ThrowConnectionFault(fault)
	MsgC(Color(255, 0, 0), "NutScript has failed to connect to the database.\n")
	MsgC(Color(255, 0, 0), fault.."\n")

	setNetVar("dbError", fault)
end

local modules = {}

-- SQLite for local storage.
modules.sqlite = {
	query = function(query, callback)
		local data = sql.Query(query)
		local fault = sql.LastError()

		if (data == false) then
			ThrowQueryFault(query, fault)
		end

		if (callback) then
			local lastID = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))

			callback(data, lastID)
		end
	end,
	escape = function(value)
		return sql.SQLStr(value, true)
	end,
	connect = function(callback)
		if (callback) then
			callback()
		end
	end
}

-- tmysql4 module for MySQL storage.
modules.tmysql4 = {
	query = function(query, callback)
		if (nut.db.object) then
			nut.db.object:Query(query, function(data, status, lastID)
				if (QUERY_SUCCESS and status == QUERY_SUCCESS) then
					if (callback) then
						callback(data, lastID)
					end
				else
					if (data and data[1]) then
						if (data[1].status) then
							if (callback) then
								callback(data[1].data, data[1].lastid)
							end

							return
						else
							lastID = data[1].error
						end
					end

					file.Write("nut_queryerror.txt", query)
					ThrowQueryFault(query, lastID or "")
				end
			end, 3)
		end
	end,
	escape = function(value)
		if (nut.db.object) then
			return nut.db.object:Escape(value)
		end

		return tmysql and tmysql.escape and tmysql.escape(value) or sql.SQLStr(value, true)
	end,
	connect = function(callback)
		if (!pcall(require, "tmysql4")) then
			return setNetVar("dbError", system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for tmysql4!")
		end

		local hostname = nut.db.hostname
		local username = nut.db.username
		local password = nut.db.password
		local database = nut.db.database
		local port = nut.db.port
		local object, fault = tmysql.initialize(hostname, username, password, database, port)

		if (object) then
			nut.db.object = object
			nut.db.escape = modules.tmysql4.escape
			nut.db.query = modules.tmysql4.query

			if (callback) then
				callback()
			end
		else
			ThrowConnectionFault(fault)
		end	
	end
}

MYSQLOO_QUEUE = MYSQLOO_QUEUE or {}
PREPARE_CACHE = {}

-- mysqloo for MySQL storage.
nut.db.prepared = nut.db.prepared or {}
modules.mysqloo = {
	query = function(query, callback)
		if (nut.db.getObject()) then
			local object = nut.db.getObject():query(query)

			if (callback) then
				function object:onSuccess(data)
					callback(data, self:lastInsert())
				end
			end

			function object:onError(fault)
				if (nut.db.getObject():status() == mysqloo.DATABASE_NOT_CONNECTED) then
					MYSQLOO_QUEUE[#MYSQLOO_QUEUE + 1] = {query, callback}
					nut.db.connect()

					return
				end

				ThrowQueryFault(query, fault)
			end

			object:start()
		end
	end,
	escape = function(value)
		local object = nut.db.getObject()

		if (object) then
			return object:escape(value)
		else
			return sql.SQLStr(value, true)
		end
	end,
	queue = function()
		local count = 0

		for k, v in pairs(nut.db.pool) do
			count = count + v:queueSize()
		end

		return count
	end,
	abort = function()
		for k, v in pairs(nut.db.pool) do
			v:abortAllQueries()
		end
	end,
	getObject = function()
		local lowest = nil
		local lowestCount = 0
		local lowestIndex = 0

		for k, db in pairs(nut.db.pool) do
			local queueSize = db:queueSize()
			if (!lowest || queueSize < lowestCount) then
				lowest = db
				lowestCount = queueSize
				lowestIndex = k
			end
		end

		if (not lowest) then
			error("failed to find database in the pool")
		end

		return lowest, lowestIndex
	end,
	connect = function(callback)
		if (!pcall(require, "mysqloo")) then
			return setNetVar("dbError", system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for mysqloo!")
		end

		if (mysqloo.VERSION != "9" || !mysqloo.MINOR_VERSION || tonumber(mysqloo.MINOR_VERSION) < 1) then
			MsgC(Color(255, 0, 0), "You are using an outdated mysqloo version\n")
			MsgC(Color(255, 0, 0), "Download the latest mysqloo9 from here\n")
			MsgC(Color(86, 156, 214), "https://github.com/syl0r/MySQLOO/releases")
			return
		end

		local hostname = nut.db.hostname
		local username = nut.db.username
		local password = nut.db.password
		local database = nut.db.database
		local port = nut.db.port
		local object = mysqloo.connect(hostname, username, password, database, port)

		nut.db.pool = {}
		local poolNum = 6 -- it won't utilize full potential beyond 6.
		local connectedPools = 0

		for i = 1, poolNum do
			nut.db.pool[i] = mysqloo.connect(hostname, username, password, database, port)
			local pool = nut.db.pool[i]
			pool:connect()

			function pool:onConnectionFailed(fault)
				ThrowConnectionFault(fault)
			end

			function pool:onConnected()
				pool:setCharacterSet("utf8")
				connectedPools = connectedPools + 1

				if (connectedPools == poolNum) then
					nut.db.escape = modules.mysqloo.escape
					nut.db.query = modules.mysqloo.query
					nut.db.prepare = modules.mysqloo.prepare
					nut.db.abort = modules.mysqloo.abort
					nut.db.queue = modules.mysqloo.queue
					nut.db.getObject = modules.mysqloo.getObject
					nut.db.preparedCall = modules.mysqloo.preparedCall

					for k, v in ipairs(MYSQLOO_QUEUE) do
						nut.db.query(v[1], v[2])
					end

					MYSQLOO_QUEUE = {}

					if (callback) then
						callback()
					end
					
					hook.Run("OnMySQLOOConnected")
				end
			end

			timer.Create("nutMySQLWakeUp" .. i, 1 + i, 0, function()
				pool:query("SELECT 1 + 1")
			end)
		end

		nut.db.object = nut.db.pool
	end,
	prepare = function(key, str, values)
		nut.db.prepared[key] = {
			query = str,
			values = values,
		}
	end,
	preparedCall = function(key, callback, ...)
		local preparedStatement = nut.db.prepared[key]

		if (preparedStatement) then
			local freeDB, freeIndex = nut.db.getObject()
			PREPARE_CACHE[key] = PREPARE_CACHE[key] or {}
			PREPARE_CACHE[key][freeIndex] = PREPARE_CACHE[key][freeIndex] or nut.db.getObject():prepare(preparedStatement.query)
			local prepObj = PREPARE_CACHE[key][freeIndex]

			function prepObj:onSuccess(data)
				if (callback) then
					callback(data, self:lastInsert())
				end
			end
			function prepObj:onError(err)
				print(err)
			end

			local arguments = {...}

			if (table.Count(arguments) == table.Count(preparedStatement.values)) then
				local index = 1

				for name, type in pairs(preparedStatement.values) do
					if (type == MYSQLOO_INTEGER) then
						prepObj:setNumber(index, arguments[index]) 
					elseif (type == MYSQLOO_STRING) then
						prepObj:setString(index, nut.db.convertDataType(arguments[index], true)) 
					elseif (type == MYSQLOO_BOOL) then
						prepObj:setBoolean(index, arguments[index]) 
					end
					
					index = index + 1
				end
			end

			prepObj:start()
		else
			MsgC(Color(255, 0, 0), "INVALID PREPARED STATEMENT : " .. key .. "\n")
		end
	end
}


-- Add default values here.
nut.db.escape = modules.sqlite.escape
nut.db.query = modules.sqlite.query

function nut.db.connect(callback)
	local dbModule = modules[nut.db.module]

	if (dbModule) then
		if (!nut.db.object) then
			dbModule.connect(callback)
		end

		nut.db.escape = dbModule.escape
		nut.db.query = dbModule.query
	else
		ErrorNoHalt("[NutScript] '"..(nut.db.module or "nil").."' is not a valid data storage method!\n")
	end
end

-- CREATE TABLE IF NOT EXISTS
-- GENERATED with http://dbdesigner.net

local MYSQL_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS `nut_players` (
	`_steamID` VARCHAR(20) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_steamName` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_firstJoin` DATETIME,
	`_lastJoin` DATETIME,
	`_data` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_intro` BINARY(1) NULL DEFAULT 0,
	PRIMARY KEY (`_steamID`)
);

CREATE TABLE IF NOT EXISTS `nut_characters` (
	`_id` INT(12) NOT NULL AUTO_INCREMENT,
	`_steamID` VARCHAR(20) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_name` VARCHAR(70) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_desc` VARCHAR(512) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_model` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_attribs` VARCHAR(512) DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`_schema` VARCHAR(24) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_createTime` DATETIME NOT NULL,
	`_lastJoinTime` DATETIME NOT NULL,
	`_data` VARCHAR(1024) DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`_money` INT(10) UNSIGNED NULL DEFAULT '0',
	`_faction` VARCHAR(12) DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`_id`)
);

CREATE TABLE IF NOT EXISTS `nut_inventories` (
	`_invID` INT(12) NOT NULL AUTO_INCREMENT,
	`_charID` INT(12) NULL DEFAULT NULL,
	`_invType` VARCHAR(24) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`_invID`)
);

CREATE TABLE IF NOT EXISTS `nut_items` (
	`_itemID` INT(12) NOT NULL AUTO_INCREMENT,
	`_invID` INT(12) NULL DEFAULT NULL,
	`_uniqueID` VARCHAR(60) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_data` VARCHAR(512) NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`_x` INT(4),
	`_y` INT(4),
	PRIMARY KEY (`_itemID`)
);

CREATE TABLE IF NOT EXISTS `nut_invdata` (
	`_invID` INT(12) NOT NULL,
	`_key` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_general_ci',
	`_value` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	FOREIGN KEY (`_invID`) REFERENCES nut_inventories(_invID) ON DELETE CASCADE,
	PRIMARY KEY (`_invID`, `_key`)
);
]]

local SQLITE_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS nut_players (
	_steamID varchar,
	_steamName varchar,
	_firstJoin datetime,
	_lastJoin datetime,
	_data varchar,
	_intro binary
);

CREATE TABLE IF NOT EXISTS nut_characters (
	_id integer PRIMARY KEY AUTOINCREMENT,
	_steamID varchar,
	_name varchar,
	_desc varchar,
	_model varchar,
	_attribs varchar,
	_schema varchar,
	_createTime datetime,
	_lastJoinTime datetime,
	_data varchar,
	_money varchar,
	_faction varchar
);

CREATE TABLE IF NOT EXISTS nut_inventories (
	_invID integer PRIMARY KEY AUTOINCREMENT,
	_charID integer,
	_invType varchar
);

CREATE TABLE IF NOT EXISTS nut_items (
	_itemID integer PRIMARY KEY AUTOINCREMENT,
	_invID integer,
	_uniqueID varchar,
	_data varchar,
	_x integer,
	_y integer
);

CREATE TABLE IF NOT EXISTS nut_invdata (
	_invID integer,
	_key text,
	_value text,
	FOREIGN KEY(_invID) REFERENCES nut_inventories(_invID),
	PRIMARY KEY (_invID, _key)
)
]]

local DROP_QUERY = [[
DROP TABLE IF EXISTS `nut_players`;
DROP TABLE IF EXISTS `nut_characters`;
DROP TABLE IF EXISTS `nut_inventories`;
DROP TABLE IF EXISTS `nut_items`;
DROP TABLE IF EXISTS `nut_invdata`;
DROP TABLE IF EXISTS `nut_inventories`;
]]

local DROP_QUERY_LITE = [[
DROP TABLE IF EXISTS nut_players;
DROP TABLE IF EXISTS nut_characters;
DROP TABLE IF EXISTS nut_inventories;
DROP TABLE IF EXISTS nut_items;
DROP TABLE IF EXISTS nut_invdata;
DROP TABLE IF EXISTS nut_inventories;
]]

function nut.db.wipeTables(callback)
	nut.db.onQueryError = nil
	local function realCallback()
		nut.db.query("SET FOREIGN_KEY_CHECKS = 1;", function()
			MsgC(
				Color(255, 0, 0),
				"[Nutscript] ALL NUTSCRIPT DATA HAS BEEN WIPED\n"
			)
			if (isfunction(callback)) then
				callback()
			end
		end)
	end

	if (nut.db.object) then
		local function startDeleting()
			local queries = string.Explode(";", DROP_QUERY)
			local done = 0
			for i = 1, #queries do
				queries[i] = string.Trim(queries[i])
				if (queries[i] == "") then
					done = done + 1
					continue
				end
				nut.db.query(queries[i], function()
					done = done + 1
					if (done >= #queries) then
						realCallback()
					end
				end)
			end
		end

		nut.db.query("SET FOREIGN_KEY_CHECKS = 0;", startDeleting)
	else
		nut.db.query(DROP_QUERY_LITE, realCallback)
	end
end

local resetCalled = 0
concommand.Add("nut_recreatedb", function(client, cmd, arguments)
	-- this command can be run in RCON or SERVER CONSOLE
	if (!IsValid(client)) then
		if (resetCalled < RealTime()) then
			resetCalled = RealTime() + 3

			MsgC(Color(255, 0, 0), "[Nutscript] TO CONFIRM DATABASE RESET, RUN 'nut_recreatedb' AGAIN in 3 SECONDS.\n")
		else
			resetCalled = 0
			
			MsgC(Color(255, 0, 0), "[Nutscript] DATABASE WIPE IN PROGRESS.\n")
			
			hook.Run("OnWipeTables")
			nut.db.wipeTables(nut.db.loadTables)
		end
	end
end)

function nut.db.loadTables()
	nut.db.onQueryError = nil
	if (nut.db.object) then
		-- This is needed to perform multiple queries since the string is only 1 big query.
		local queries = string.Explode(";", MYSQL_CREATE_TABLES)
		local i = 1

		local function done()
			hook.Run("NutScriptTablesLoaded")
		end

		local function doNextQuery()
			if (i > #queries) then
				return done()
			end
			local query = string.Trim(queries[i])
			if (query == "") then
				i = i + 1
				return doNextQuery()
			end
			print(query)
			nut.db.query(query, function()
				print(i)
				i = i + 1
				doNextQuery()
			end)
		end

		doNextQuery()
	else
		nut.db.query(SQLITE_CREATE_TABLES, function()
			hook.Run("NutScriptTablesLoaded")
		end)
	end

	hook.Run("OnLoadTables")
end

function nut.db.convertDataType(value, noEscape)
	if (type(value) == "string") then
		if (noEscape) then
			return value
		else
			return "'"..nut.db.escape(value).."'"
		end
	elseif (type(value) == "table") then
		if (noEscape) then
			return util.TableToJSON(value)
		else
			return "'"..nut.db.escape(util.TableToJSON(value)).."'"
		end
	elseif (value == NULL) then
		return "NULL"
	end

	return value
end

local function genInsertValues(value, dbTable)
	local query = "nut_"..(dbTable or "characters").." ("
	local keys = {}
	local values = {}

	for k, v in pairs(value) do
		keys[#keys + 1] = k
		values[#keys] = k:find("steamID") and v or nut.db.convertDataType(v)
	end

	return query
		..table.concat(keys, ", ")
		..") VALUES ("..table.concat(values, ", ")..")"
end

local function genUpdateList(value)
	local changes = {}
	for k, v in pairs(value) do
		changes[#changes + 1] = k.." = "..(k:find("steamID") and v or nut.db.convertDataType(v))
	end
	return table.concat(changes, ", ")
end

function nut.db.insertTable(value, callback, dbTable)
	local query = "INSERT INTO "..genInsertValues(value, dbTable)
	nut.db.query(query, callback)
end

function nut.db.updateTable(value, callback, dbTable, condition)
	local query = "UPDATE "..("nut_"..(dbTable or "characters")).." SET "
		..genUpdateList(value)
		..(condition and " WHERE "..condition or "")
	nut.db.query(query, callback)
end

function nut.db.select(fields, dbTable, condition, limit)
	local d = deferred.new()
	local from =
		type(fields) == "table" and table.concat(fields, ", ") or tostring(fields)
	local tableName = "nut_"..(dbTable or "characters")
	local query = "SELECT "..from.." FROM "..tableName

	if (condition) then
		query = query.." WHERE "..tostring(condition)
	end

	if (limit) then
		query = query.." LIMIT "..tostring(limit)
	end

	nut.db.query(query, function(results, lastID)
		d:resolve({results = results, lastID = lastID})
	end)
	return d
end

function nut.db.upsert(value, dbTable)
	local query
	if (nut.db.object) then
		query = "INSERT INTO "..genInsertValues(value, dbTable)
			.." ON DUPLICATE KEY UPDATE "
			..genUpdateList(value)
	else
		query = "INSERT OR REPLACE INTO "..genInsertValues(value, dbTable)
	end

	local d = deferred.new()
	nut.db.query(query, function(results, lastID)
		d:resolve({results = results, lastID = lastID})
	end)
	return d
end

function nut.db.delete(dbTable, condition)
	local query
	dbTable = "nut_"..(dbTable or "character")
	if (condition) then
		query = "DELETE FROM "..dbTable.." WHERE "..condition
	else
		query = "DELETE * FROM "..dbTable
	end

	local d = deferred.new()
	nut.db.query(query, function(results, lastID)
		d:resolve({results = results, lastID = lastID})
	end)
	return d
end

function GM:OnMySQLOOConnected()
	hook.Run("RegisterPreparedStatements")
	MYSQLOO_PREPARED = true
end

MYSQLOO_INTEGER = 0
MYSQLOO_STRING = 1
MYSQLOO_BOOL = 2
function GM:RegisterPreparedStatements()
	MsgC(Color(0, 255, 0), "[Nutscript] ADDED 2 PREPARED STATEMENTS\n")
	nut.db.prepare("itemData", "UPDATE nut_items SET _data = ? WHERE _itemID = ?", {MYSQLOO_STRING, MYSQLOO_INTEGER})
	nut.db.prepare("itemx", "UPDATE nut_items SET _x = ? WHERE _itemID = ?", {MYSQLOO_INTEGER, MYSQLOO_INTEGER})
	nut.db.prepare("itemy", "UPDATE nut_items SET _y = ? WHERE _itemID = ?", {MYSQLOO_INTEGER, MYSQLOO_INTEGER})
	nut.db.prepare("itemInstance", "INSERT INTO nut_items (_invID, _uniqueID, _data, _x, _y) VALUES (?, ?, ?, ?, ?)", {
		MYSQLOO_INTEGER,
		MYSQLOO_STRING,
		MYSQLOO_STRING,
		MYSQLOO_INTEGER,
		MYSQLOO_INTEGER,
	})
end
