local PENDING, FULFILLED, REJECTED = "pending", "fulfilled", "rejected"
local HANDLER_RESOLVE, HANDLER_REJECT, HANDLER_PROMISE = 1, 2, 3

REJECTION_HANDLER_ID = REJECTION_HANDLER_ID or 0
UNHANDLED_PROMISES = UNHANDLED_PROMISES or {}

local Promise = {
    state = PENDING,
    value = nil,
}
Promise.__index = Promise

function Promise:new()
    local instance = {
        onResolve = onResolve,
        onReject = onReject,
        handlers = {}
    }
    setmetatable(instance, Promise)
    return instance
end

function Promise:__tostring()
    local value = ""
    if (self.value) then
        value = ", value="..tostring(self.value)
    elseif (self.reason) then
        value = ", reason="..tostring(self.reason)
    end
    return "Promise{state="..self.state..value.."}"
end

function Promise:resolve(value)
    if (self.state == PENDING) then
        self.state = FULFILLED
        self.value = value
        self:_handle(value)
    end
    return self
end

function Promise:reject(reason)
    if (self.state == PENDING) then
        self.state = REJECTED
        self.reason = reason
        self:_handle(reason)
    end
    return self
end

function Promise:next(onResolve, onReject)
    -- Ignore an argument if it is not a function.
    if (not isfunction(onResolve)) then onResolve = nil end
    if (not isfunction(onReject)) then onReject = nil end

    local promise = Promise:new()
    self.handlers[#self.handlers + 1] = {
        [HANDLER_RESOLVE] = onResolve,
        [HANDLER_REJECT] = onReject,
        [HANDLER_PROMISE] = promise
    }

    if (self.state ~= PENDING) then
        timer.Simple(0, function()
            if (self.state == FULFILLED) then
                self:_handle(self.value)
            else
                self:_handle(self.reason)
            end
        end)
    end

    if (DEBUG_IGNOREUNHANDLED) then
        return promise
    end

    if (self.rejectionHandlerID) then
        promise.rejectionHandlerID = self.rejectionHandlerID
    else
        promise.rejectionHandlerID = REJECTION_HANDLER_ID
        UNHANDLED_PROMISES[REJECTION_HANDLER_ID] = true
        REJECTION_HANDLER_ID = REJECTION_HANDLER_ID + 1
    end
    return promise
end

function Promise:catch(onReject)
    return self:next(nil, onReject)
end

function Promise:_handle(value)
    -- Do not allow promises to resolve to themselves.
    if (value == self) then
        return self:reject("cannot resolve to self")
    end

    -- Adopt state if value is a promise.
    if (istable(value) and value.next) then
        if (value.state) then
            -- Adopt the rejection handler ID.
            if (not DEBUG_IGNOREUNHANDLED) then
                UNHANDLED_PROMISES[value.rejectionHandlerID] = nil
                value.rejectionHandlerID = self.rejectionHandlerID
            end

            -- Handle resolving to a promise.
            self.state = value.state
            if (value.state == PENDING) then
                self.value = value.value
                self.reason = value.reason
                value:next(function(newValue)
                    self:resolve(newValue)
                    return newValue
                end, function(reason)
                    self:reject(reason)
                    value.rejectionHandlerID = nil
                    return reason
                end)
            elseif (value.state == FULFILLED) then
                self:_handle(value.value)
            else
                self:reject(value.reason)
            end
            return
        elseif (isfunction(value.next)) then
            -- Handle resolving to a thenable.
            self.state = PENDING
            self.value = nil
            local first = true
            local function resolvePromise(newValue)
                if (first) then
                    self:resolve(newValue)
                    first = nil
                end
            end
            local function rejectPromise(reason)
                if (first) then
                    self:reject(reason)
                    first = nil
                end
            end
            local status, result =
                pcall(value.next, resolvePromise, rejectPromise)
            if (not status and first) then
                self:reject(result)
            end
            return
        end
    end

    -- If value is not special, just resolve normally.
    local handler, onResolve, onReject, promise
    local isRejected = self.state == REJECTED

    for i = 1, #self.handlers do
        handler = self.handlers[i]
        onResolve = handler[HANDLER_RESOLVE]
        onReject = handler[HANDLER_REJECT]
        promise = handler[HANDLER_PROMISE]

        if (isRejected) then
            if (onReject) then
                local status, result = pcall(onReject, value)
                if (status) then
                    promise:_handle(result)

                    if (self.rejectionHandlerID) then
                        UNHANDLED_PROMISES[self.rejectionHandlerID] = nil
                    end
                else
                    promise:reject(result)
                end
            else
                promise:reject(value)
            end
        else
            if (onResolve) then
                local status, result = pcall(onResolve, value)
                if (status) then
                    promise:_handle(result)
                else
                    promise:reject(result)
                end
            else
                promise:resolve(value)
            end
        end
    end
    self.handlers = {}
    if (isRejected and not DEBUG_IGNOREUNHANDLED) then
        local trace = debug.traceback()
        timer.Simple(0.1, function()
            if (
                UNHANDLED_PROMISES[self.rejectionHandlerID] and
                not DEBUG_IGNOREUNHANDLED
            ) then
				UNHANDLED_PROMISES[self.rejectionHandlerID] = nil
                ErrorNoHalt(
                    "Unhandled rejection: "..tostring(self.reason or "").."\n"
                )
                print(trace)
            end
        end)
    end
end

deferred = {}

function deferred.isPromise(value)
    return istable(value)
        and isfunction(value.next)
        and isfunction(value.resolve)
        and value.state
end

function deferred.new()
    local promise =  Promise:new()

    -- Bookkeeping for unhandled promises.
    if (not DEBUG_IGNOREUNHANDLED) then
        promise.rejectionHandlerID = REJECTION_HANDLER_ID
        UNHANDLED_PROMISES[REJECTION_HANDLER_ID] = true
        REJECTION_HANDLER_ID = REJECTION_HANDLER_ID + 1
    end

    return promise
end

function deferred.reject(reason)
    return deferred.new():reject(reason)
end

function deferred.resolve(value)
    return deferred.new():resolve(value)
end

function deferred.all(promises)
    assert(istable(promises), "promises must be a table of promises")
    local results = {}
    local d = deferred.new()
    local method = "resolve"
    local expected = #promises
    local finished = 0

    if (finished == expected) then
        return d:resolve(results)
    end

    local onFinish = function(i, resolved)
        return function(value)
            results[i] = value
            if (not resolved) then
                method = "reject"
            end
            finished = finished + 1
            if (finished == expected) then
                d[method](d, results)
            end
            return value
        end
    end

    for i = 1, expected do
        promises[i]:next(onFinish(i, true), onFinish(i, false))
    end

    return d
end

function deferred.map(args, fn)
    assert(istable(args), "args must be a table of values")
    assert(isfunction(fn), "map called without a function")

    local expected = #args
    local finished = 0
    local results = {}
    local d = deferred.new()

    if (expected == 0) then
        return d:resolve(results)
    end

    for i = 1, expected do
        fn(args[i], i, expected):next(function(value)
            results[i] = value
            finished = finished + 1

            if (finished == expected) then
                d:resolve(results)
            end
        end, function(reason)
            d:reject(reason)
        end)
    end

    return d
end

function deferred.fold(promises, folder, initial)
    assert(istable(promises), "promises must be a table")
    assert(isfunction(folder), "folder must be a function")

    local d = deferred.new()
    local total = initial
    local length = #promises

    if (length == 0) then
        return d:resolve(total)
    end

    local i = 1

    local function onRejected(reason)
        d:reject(reason)
        return reason
    end

    local function handle(value)
        total = folder(total, value, i, length)

        if (i == length) then
            d:resolve(total)
            return value
        end

        i = i + 1
        promises[i]:next(handle, onRejected)
        return value
    end

    promises[1]:next(handle, onRejected)
    return d
end

function deferred.filter(promises, filter)
    return deferred.fold(promises, function(acc, value)
        if (filter(value)) then
            acc[#acc + 1] = value
        end
        return acc
    end, {})
end

function deferred.each(promises, fn)
    return deferred.fold(promises, function(_, value, i, length)
        -- Ignore return value.
        fn(value, i, length)
    end, nil):next(function()
        -- Clear the return value.
        return nil
    end)
end

function deferred.some(promises, count)
    assert(istable(promises), "promises must be a table")
    assert(
        isnumber(count) and count >= 0 and math.floor(count) == count,
        "count must be a non-negative integer"
    )

    local d = deferred.new()
    local results = {}
    local finished = 0
    if (count == finished) then
        return d:resolve(results)
    end

    for _, promise in ipairs(promises) do
        promise:next(function(value)
            if (d.state ~= PENDING) then return value end

            finished = finished + 1
            results[finished] = value
            if (finished == count) then
                d:resolve(results)
            end
            return value
        end, function(reason)
            d:reject(reason)
        end)
    end

    return d
end

function deferred.any(promises)
    return deferred.some(promises, 1)
        :next(function(results)
            return results[1]
        end)
end
