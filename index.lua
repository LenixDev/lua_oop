assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (members)
  local properties<const> = {}
  local propertiesValues<const> = {}

  -- initialize
  for varKey in pairs(members) do
    if varKey ~= "constructor" then
      properties[varKey] = {}
      if type(members[varKey]) == 'table' then
        propertiesValues[varKey] = members[varKey][1] ~= nil and members[varKey][1] or nil
        properties[varKey] = {
          isPrivate = members[varKey][2] == nil and true or members[varKey][2],
          isStatic = members[varKey][3] == nil and false or members[varKey][3] or false,
          isConst = members[varKey][4] == nil and false or members[varKey][4] or true,
        }
      else
        propertiesValues[varKey] = members[varKey]
        properties[varKey] = {
          isPrivate = true,
          isStatic = false,
          isConst =  true,
        }
      end
    elseif type(members[varKey]) ~= "function" then error("syntax error: constructor is not a function") end
  end

  return setmetatable({
    new = function(self, ...)
      local instance<const> = {}
      for propertyKey, property in pairs(properties) do
        if not property.isStatic then
          instance[propertyKey] = propertiesValues[propertyKey]
        end
      end

      if members.constructor then
        members.constructor(instance, nil, ...)
      else error('no constructor was provided') end

      for propertyKey in pairs(properties) do
        if not instance[propertyKey] then
          print(('the `%s` was not instantiated in constructor'):format(propertyKey))
        end
      end
      
    end
  }, {
    __metatable = false,
    __index = function(self, varKey)
      local property<const> = properties[varKey]
      assert(not property.isPrivate, ("`%s` property is private"):format(varKey))
      assert(property.isStatic, ("`%s` property is not static"):format(varKey))
      local value = propertiesValues[varKey]

      if type(value) == "function" then
        return function(_, ...)
          return value(propertiesValues, ...)
        end
      end

      return value
    end,
    __newindex = function(_, varKey, varValue)
      local property<const> = properties[varKey]
      assert(not property.isPrivate, ("`%s` property is private"):format(varKey))
      assert(property.isStatic, ("`%s` property is not static"):format(varKey))
      assert(not property.isConst, ("`%s` property is constant"):format(varKey))
      propertiesValues[varKey] = varValue
    end
  })
end

local myClass<const> = class({
  name = "Lenix",
  height = {nil},
  age = 20,
  getHeight = {
    function(self)
      return self.height
    end
  },
  setHeight = {
    function(self, height)
      self.height = height
      return true, "set successful"
    end
  },
  --[[ reserved for later uses ]]
  -- get = {},
  -- set = {},
  -- accessor = {},
  -- override = {},
  constructor = function(self, super, name, age, height, blood)
    self.name = name
    self.age = age
    self.height = height
    self.blood = blood
  end
})

local Class<const> = myClass:new("Lenix", 20, 197, "O+")
-- print(Class.name)
-- local Class<const> = myClass:new("Lenix", 20, 197, "O+")
-- Class.setHeight = function(self, new)
--   self.height = new
-- end



-- print(Class.getHeight(198))





--virtual