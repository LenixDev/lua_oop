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
    end
  end
  
  return setmetatable({}, {
    __metatable = false,
    __index = function(_, varKey)
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
  name = {"Lenix", false, true, false, true},
  height = {nil, true, true},
  age = 20,
  getHeight = {
    function(self)
      return self.height
    end, false, true
  },
  setHeight = {
    function(self, height)
      self.height = height
      return true, "set successful"
    end, false, true
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

myClass:setHeight(197)
print(myClass:getHeight())
-- local Class<const> = myClass:new("Lenix", 20, 197, "O+")
-- Class.setHeight = function(self, new)
--   self.height = new
-- end



-- print(Class.getHeight(198))





--virtual