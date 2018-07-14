nut.db = nut.db or {}
nut.util.include("nutscript/gamemode/config/sv_database.lua")

local function ThrowQueryFault(query, fault)
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

-- mysqloo for MySQL storage.
modules.mysqloo = {
	query = function(query, callback)
		if (nut.db.object) then
			local object = nut.db.object:query(query)

			if (callback) then
				function object:onSuccess(data)
					callback(data, self:lastInsert())
				end
			end

			function object:onError(fault)
				if (nut.db.object:status() == mysqloo.DATABASE_NOT_CONNECTED) then
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
		local object = nut.db.object

		if (object) then
			return object:escape(value)
		else
			return sql.SQLStr(value, true)
		end
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

		function object:onConnected()
			nut.db.object = self
			nut.db.escape = modules.mysqloo.escape
			nut.db.query = modules.mysqloo.query

			for k, v in ipairs(MYSQLOO_QUEUE) do
				nut.db.query(v[1], v[2])
			end

			MYSQLOO_QUEUE = {}

			if (callback) then
				callback()
			end
			
			hook.Run("OnMySQLOOConnected")
		end

		function object:onConnectionFailed(fault)
			ThrowConnectionFault(fault)
		end

		object:connect()

		timer.Create("nutMySQLWakeUp", 300, 0, function()
			nut.db.query("SELECT 1 + 1")
		end)

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
	`_steamID` VARCHAR(20) NOT NULL,
	`_steamName` VARCHAR(32) NOT NULL,
	`_firstJoin` DATETIME NOT NULL,
	`_lastJoin` DATETIME NOT NULL,
	`_data` VARCHAR(255) NOT NULL,
	`_intro` BINARY(1) NOT NULL,
	PRIMARY KEY (`_steamID`),
	UNIQUE INDEX `_steamID` (`_steamID`)
);

CREATE TABLE IF NOT EXISTS `nut_characters` (
	`_id` INT(12) NOT NULL AUTO_INCREMENT,
	`_steamID` VARCHAR(20) NOT NULL,
	`_name` VARCHAR(70) NOT NULL,
	`_desc` VARCHAR(512) NOT NULL,
	`_model` VARCHAR(255) NOT NULL,
	`_attribs` VARCHAR(512) NOT NULL,
	`_schema` VARCHAR(24) NOT NULL,
	`_createTime` DATETIME NOT NULL,
	`_lastJoinTime` DATETIME NOT NULL,
	`_data` VARCHAR(1024) NOT NULL,
	`_money` INT(10) UNSIGNED NULL DEFAULT '0',
	`_faction` VARCHAR(12) NOT NULL,
	PRIMARY KEY (`_id`),
	UNIQUE INDEX `_id` (`_id`)
);

CREATE TABLE IF NOT EXISTS `nut_inventories` (
	`_invID` INT(12) NOT NULL AUTO_INCREMENT,
	`_charID` INT(12) NULL DEFAULT NULL,
	`_invType` VARCHAR(24) NULL DEFAULT NULL,
	PRIMARY KEY (`_invID`),
	UNIQUE INDEX `_invID` (`_invID`)
);

CREATE TABLE IF NOT EXISTS `nut_items` (
	`_itemID` INT(12) NOT NULL AUTO_INCREMENT,
	`_invID` INT(12) NOT NULL,
	`_uniqueID` VARCHAR(60) NOT NULL,
	`_data` VARCHAR(512) NOT NULL,
	`_x` INT(4) NOT NULL,
	`_y` INT(4) NOT NULL,
	`_quantity` INT(12) NOT NULL DEFAULT '1',
	PRIMARY KEY (`_itemID`),
	UNIQUE INDEX `_itemID` (`_itemID`)
);

CREATE TABLE IF NOT EXISTS `nut_schemadata` (
	`_schema` VARCHAR(255) NOT NULL,
	`_id` VARCHAR(255) NOT NULL,
	`_data` VARCHAR(1024) NOT NULL,
	PRIMARY KEY (`_schema`, `_id`),
	UNIQUE INDEX `_schema` (`_schema`),
	UNIQUE INDEX `_id` (`_id`)
)]]

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
	_y integer,
	_quantity integer
);

CREATE TABLE IF NOT EXISTS nut_schemadata (
	_schema varchar,
	_id varchar,
	_data varchar
);]]

local DROP_QUERY = [[
DROP TABLE IF EXISTS `nut_players`;
DROP TABLE IF EXISTS `nut_characters`;
DROP TABLE IF EXISTS `nut_inventories`;
DROP TABLE IF EXISTS `nut_items`;
DROP TABLE IF EXISTS `nut_schemadata`]]

local DROP_QUERY_LITE = [[
DROP TABLE IF EXISTS nut_players;
DROP TABLE IF EXISTS nut_characters;
DROP TABLE IF EXISTS nut_inventories;
DROP TABLE IF EXISTS nut_items;
DROP TABLE IF EXISTS nut_schemadata]]

function nut.db.wipeTables()
	local function callback()
		MsgC(Color(255, 0, 0), "[Nutscript] ALL NUTSCRIPT DATA HAS BEEN WIPED\n")
	end

	if (nut.db.object) then
		local queries = string.Explode(";", DROP_QUERY)

		for i = 1, #queries do
			nut.db.query(queries[i], callback)
		end
	else
		nut.db.query(DROP_QUERY_LITE, callback)
	end

	nut.db.loadTables()
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
			nut.db.wipeTables()
		end
	end
end)

function nut.db.loadTables()
	if (nut.db.object) then
		-- This is needed to perform multiple queries since the string is only 1 big query.
		local queries = string.Explode(";", MYSQL_CREATE_TABLES)

		for i = 1, 4 do
			nut.db.query(queries[i])
		end
	else
		nut.db.query(SQLITE_CREATE_TABLES)
	end

	hook.Run("OnLoadTables")
end

function nut.db.convertDataType(value)
	if (type(value) == "string") then
		return "'"..nut.db.escape(value).."'"
	elseif (type(value) == "table") then
		return "'"..nut.db.escape(util.TableToJSON(value)).."'"
	end

	return value
end

function nut.db.insertTable(value, callback, dbTable)
	local query = "INSERT INTO "..("nut_"..(dbTable or "characters")).." ("
	local keys = {}
	local values = {}

	for k, v in pairs(value) do
		keys[#keys + 1] = k
		values[#keys] = k:find("steamID") and v or nut.db.convertDataType(v)
	end

	query = query..table.concat(keys, ", ")..") VALUES ("..table.concat(values, ", ")..")"
	nut.db.query(query, callback)
end

function nut.db.updateTable(value, callback, dbTable, condition)
	local query = "UPDATE "..("nut_"..(dbTable or "characters")).." SET "
	local changes = {}

	for k, v in pairs(value) do
		changes[#changes + 1] = k.." = "..(k:find("steamID") and v or nut.db.convertDataType(v))
	end

	query = query..table.concat(changes, ", ")..(condition and " WHERE "..condition or "")
	nut.db.query(query, callback)
end

function GM:OnMySQLOOConnected()
	nut.db.prepared = {}
	function nut.db.prepare(key, str, values)
		nut.db.prepared[key] = {
			object = nut.db.object:prepare(str),
			values = values,
		}
	end

	function nut.db.preparedCall(key, callback, ...)
		local preparedStatement = nut.db.prepared[key]

		if (preparedStatement) then
			local prepObj = preparedStatement.object

			function prepObj.onSuccess(qu, data)
				if (callback) then
					callback()
				end
			end

			local arguments = {...}

			if (table.Count(arguments) == table.Count(preparedStatement.values)) then
				local index = 1

				for name, type in pairs(preparedStatement.values) do
					if (type == MYSQLOO_INTEGER) then
						prepObj:setNumber(index, arguments[index]) 
					elseif (type == MYSQLOO_STRING) then
						print(arguments[index])
						prepObj:setString(index, nut.db.convertDataType(arguments[index])) 
					elseif (type == MYSQLOO_BOOL) then
						prepObj:setBoolean(index, arguments[index]) 
					end
					
					index = index + 1
				end
			end

			prepObj:start()

			return prepObj
		else
			MsgC(Color(255, 0, 0), "INVALID PREPARED STATEMENT\n")
		end
	end

	hook.Run("RegisterPreparedQueries")
	MYSQLOO_PREPARED = true
end

MYSQLOO_INTEGER = 0
MYSQLOO_STRING = 1
MYSQLOO_BOOL = 2
function GM:RegisterPreparedQueries()
	MsgC(Color(0, 255, 0), "[Nutscript] ADDED 2 PREPARED STATEMENTS\n")
	nut.db.prepare("itemQuantity", "UPDATE nut_items SET _quantity = ? WHERE _itemID = ?", {_quantity = MYSQLOO_INTEGER, _itemID = MYSQLOO_INTEGER})
	nut.db.prepare("itemData", "UPDATE nut_items SET _data = ? WHERE _itemID = ?", {_quantity = MYSQLOO_STRING, _itemID = MYSQLOO_INTEGER})
end