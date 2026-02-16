local class<const> = function (fields)
  local defined<const> = {}
  local private<const> = fields.private or {}
  local getter<const> = fields.get or {}
  local setter<const> = fields.set or {}
  local accessor<const> = fields.accessor or {}
  local privates<const> = { static = {}, instance = {} }
  local setProperties<const> = { static = {}, instance = {} }
  local getProperties<const> = { static = {}, instance = {} }

  local isVariableEligible<const> = function (variable, valueType, value)
    if defined[variable] then
      print(("`%s` is already defined"):format(variable))
      return
    elseif type(value) ~= valueType and valueType ~= "any" then
      print(("type mismatch for `%s`, expected `%s`, got `%s`"):format(variable, valueType, type(value)))
      return
    end
    defined[variable] = true
    if valueType == "any" then
      print(("variable `%s` implicitly has type `%s`"):format(variable, valueType, type(value)))
    end
    return true
  end

  local fieldPairs<const> = {
    {private, privates},
    {getter, getProperties},
    {setter, setProperties},
    {accessor, nil}
  }

  for _, pair in ipairs(fieldPairs) do
    local source, target = pair[1], pair[2]
    for variable, values in pairs(source) do
      -- getPropertyValue
      local value<const> = type(values) == "table" and values[1]
      -- getPropertyType
      local valueType<const> = type(values) == "table" and values[2] or "any"
      local staticValue<const> = values and values[3] or false
      if isVariableEligible(variable, valueType, value) then
        -- fill table with keys and values
        if target then
          if staticValue then
            target["static"][variable] = value
          else
            target["instance"][variable] = value
          end
        else
          if staticValue then
            getProperties["static"][variable] = value
            setProperties["static"][variable] = value
          else
            getProperties["instance"][variable] = value
            setProperties["instance"][variable] = value
          end
        end
      end
    end
  end

  return setmetatable({
    new = function (self, ...)
      local newInstanceArgs = {...}
      print(self)
      local constructor<const> = fields.constructor
      constructor(self, nil, ...)
      return setmetatable({}, {
        __index = function (_, variableKey)
          if getter["instance"][variableKey] then
            return getProperties["instance"][variableKey]
          elseif accessor["instance"][variableKey] then
            return getProperties["instance"][variableKey]
          end
        end,
      })
    end
  }, {
    __index = function(_, variableKey)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      -- isPropertyExist
      if getter[variableKey] ~= nil then
        if isStatic(getter, variableKey, "get") then
          -- returnPropertyValue
          return getProperties["static"][variableKey]
        end
      elseif accessor[variableKey] ~= nil then
        if isStatic(accessor, variableKey, "accessor") then
          return getProperties["static"][variableKey]
        end
      elseif private[variableKey] ~= nil then
        print(("cannot read the private property `%s`"):format(variableKey))
      elseif setter[variableKey] ~= nil then
        print(("the setter only property `%s` can not be accessed"):format(variableKey))
      else print(("something went wrong when trying to access `%s`"):format(variableKey)) end
    end,
    __newindex = function (_, variableKey, variableValue)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      if setter[variableKey] ~= nil then
        if not isStatic(setter, variableKey, "set") then
          local valueType = setter[variableKey][2] or "any"
          if type(variableValue) ~= valueType and valueType ~= "any" then
            print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), valueType, variableKey))
            return
          end
        end
        getProperties["static"][variableKey] = variableValue
      elseif accessor[variableKey] ~= nil then
        if not isStatic(accessor, variableKey, "accessor") then
          local valueType = accessor[variableKey][2] or "any"
          if type(variableValue) ~= valueType and valueType ~= "any" then
            print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), valueType, variableKey))
            return
          end
        end
        getProperties["static"][variableKey] = variableValue
      elseif getter[variableKey] ~= nil then
        print(("the getter only property `%s `can not be set"):format(variableKey))
      else print(("something went wrong when trying to access `%s`"):format(variableKey)) end
    end
  })
end

myClass = class({
  private = {
    height = {197, "number"},
  },
  get = {
    blood = {"O+", "any"},
  },
  set = {
    date = {2005, "number"},
  },
  accessor = {
    age = {20, "number"},
    name = {"Lenix", "string"},
    getBlood = {function(self) return self end, "function"}
  },
  constructor = function(self, super, name, age)
    self.name = name
    self.age = age
  end
})


local Person = myClass:new("Dev", 21)
print(Person.name, Person.age)
-- Person.date = 2005
-- print(Person.date)
-- print(Person.age)
-- Person.age = 21

-- print(myClass.height)
-- print(myClass.blood)
-- myClass.date = 2026
-- print(myClass.age)
-- myClass.age = 21
-- print(myClass.age)
-- print(myClass.name)
-- myClass.name = "Dev"
-- print(myClass.name)
-- print(myClass.getBlood())
-- myClass.getBlood = function() return true end
-- print(myClass.getBlood())




__index = function(_, variableKey)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      -- isPropertyExist
      if getter[variableKey] ~= nil then
        -- returnPropertyValue
        return getProperties[variableKey]
      elseif accessor[variableKey] ~= nil then
        return getProperties[variableKey]
      elseif private[variableKey] ~= nil then
        print(("cannot read the private property `%s`"):format(variableKey))
      elseif setter[variableKey] ~= nil then
        print(("the setter only property `%s` are forbidden to be accessed"):format(variableKey))
      else print(("something went wrong when trying to access `%s`"):format(variableKey)) end
    end,
    __newindex = function (_, variableKey, variableValue)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      if setter[variableKey] ~= nil then
        local valueType = setter[variableKey][2] or "any"
        if type(variableValue) ~= valueType and valueType ~= "any" then
          print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), valueType, variableKey))
          return
        end
        getProperties[variableKey] = variableValue
      elseif accessor[variableKey] ~= nil then
        local valueType = accessor[variableKey][2] or "any"
        if type(variableValue) ~= valueType and valueType ~= "any" then
          print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), valueType, variableKey))
          return
        end
        getProperties[variableKey] = variableValue
      elseif getter[variableKey] ~= nil then
        print(("the getter only property `%s `can not be set"):format(variableKey))
      else print(("something went wrong when trying to access `%s`"):format(variableKey)) end
    end