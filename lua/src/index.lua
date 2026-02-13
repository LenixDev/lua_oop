-- Iclass.lua

local Iclass = {}

function Iclass.new(config)
    -- Validate config
    assert(config.properties, "properties table required")
    
    local properties = config.properties or {}
    local constructorConfig = config.constructor or {}
    local accessor = config.accessor or {}
    local get = config.get or {}
    local set = config.set or {}
    
    -- Parse constructor
    local constructorOrder = {}
    local constructorOverloads = {}
    
    if constructorConfig[1] and type(constructorConfig[1]) == "table" then
        constructorOrder = constructorConfig[1]
        -- Remaining elements are single-arg overloads
        for i = 2, #constructorConfig do
            table.insert(constructorOverloads, constructorConfig[i])
        end
    end
    
    -- Detect conflicts
    local seen = {}
    
    for _, key in ipairs(accessor) do
        if seen[key] then
            error("Conflict: '" .. key .. "' defined multiple times")
        end
        seen[key] = "accessor"
    end
    
    for _, key in ipairs(get) do
        if seen[key] then
            error("Conflict: '" .. key .. "' already in " .. seen[key])
        end
        seen[key] = "get"
    end
    
    for _, key in ipairs(set) do
        if seen[key] then
            error("Conflict: '" .. key .. "' already in " .. seen[key])
        end
        seen[key] = "set"
    end
    
    -- Convert arrays to lookup tables
    local accessorMap = {}
    local getMap = {}
    local setMap = {}
    
    for _, key in ipairs(accessor) do
        accessorMap[key] = true
    end
    
    for _, key in ipairs(get) do
        getMap[key] = true
    end
    
    for _, key in ipairs(set) do
        setMap[key] = true
    end
    
    -- Helper function to create an object (class or instance)
    local function createObject(args)
        local private = {}
        
        -- Initialize properties with defaults
        for key, propConfig in pairs(properties) do
            local defaultValue = propConfig[2]
            private[key] = defaultValue
        end
        
        -- Apply constructor arguments if provided
        if args then
            if #args == 1 then
                -- Single arg - try overloads
                local value = args[1]
                local valueType = type(value)
                local matched = false
                
                for _, overloadKey in ipairs(constructorOverloads) do
                    local propConfig = properties[overloadKey]
                    
                    if propConfig and propConfig[1] == valueType then
                        -- Type matches
                        private[overloadKey] = value
                        matched = true
                        break
                    end
                end
                
                if not matched and #constructorOverloads > 0 then
                    error("No constructor overload matches type: " .. valueType)
                end
            else
                -- Multiple args - use order array
                for i, key in ipairs(constructorOrder) do
                    if args[i] ~= nil then
                        local propConfig = properties[key]
                        
                        if propConfig then
                            local expectedType = propConfig[1]
                            local actualType = type(args[i])
                            
                            if actualType ~= expectedType then
                                error("Type mismatch for '" .. key .. "': expected " .. expectedType .. ", got " .. actualType)
                            end
                            
                            private[key] = args[i]
                        end
                    end
                end
            end
        end
        
        -- Create object
        local obj = {}
        
        setmetatable(obj, {
            __index = function(t, key)
                -- Check for :new method
                if key == "new" then
                    return function(_, ...)
                        return createObject({...})
                    end
                end
                
                -- Check if readable
                if accessorMap[key] or getMap[key] then
                    return private[key]
                else
                    error("Cannot read property '" .. key .. "'")
                end
            end,
            
            __newindex = function(t, key, value)
                -- Check if writable
                if accessorMap[key] or setMap[key] then
                    -- Type check
                    local propConfig = properties[key]
                    if propConfig then
                        local expectedType = propConfig[1]
                        local actualType = type(value)
                        
                        if actualType ~= expectedType then
                            error("Type mismatch for '" .. key .. "': expected " .. expectedType .. ", got " .. actualType)
                        end
                    end
                    
                    private[key] = value
                else
                    error("Cannot write property '" .. key .. "'")
                end
            end
        })
        
        return obj
    end
    
    -- Create class as default instance (no constructor args)
    local class = createObject(nil)
    
    return class
end

local myClass = Iclass.new({
    properties = {
        name = {"string", nil},
        age = {"number", 44}
    },
    constructor = {{"name", "age"}, "age", "name"},
    get = {"name"},
    accessor = {"age"}
})

-- Class itself is an object
print(myClass.age)      -- 44
myClass.age = 50
print(myClass.age)      -- 50

-- Create instances
local ins1 = myClass:new("Bob", 25)
print(ins1.name)        -- Bob
print(ins1.age)         -- 25

local ins2 = myClass:new("Alice")
print(ins2.name)        -- Alice
print(ins2.age)         -- 44 (default)

-- Independent
ins1.age = 30
print(ins1.age)         -- 30
print(myClass.age)      -- 50 (unchanged)