local class<const> = function (fields)
  local defined<const> = {}
  local private<const> = fields.private or {}
  local getter<const> = fields.get or {}
  local setter<const> = fields.set or {}
  local accessor<const> = fields.accessor or {}
  local privates<const> = {}
  local setProperties<const> = { static = {} }
  local getProperties<const> = { static = {} }
  local accessorProperties<const> = { static = {} }

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
    {accessor, accessorProperties}
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
        if staticValue then
          target["static"][variable] = value
        else
          target[variable] = value
        end
      end
    end
  end

  local isStatic<const> = function(field, variableKey, accessorType)
    if not field[variableKey][3] then
      print(("property `%s` is not a `static` %s property"):format(variableKey, accessorType))
      return false
    else return true end
  end

  local set<const> = function(variableValue, variableType, variableKey, field)
    if type(variableValue) ~= variableType and variableType ~= "any" then
      print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), variableType, variableKey))
      return
    end
    field[variableKey] = variableValue
    getProperties[variableKey] = variableValue
  end

  return setmetatable({
    new = function (self, ...)
      local constructor = fields.constructor
      local instances = {}
      return self
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
          return accessorProperties["static"][variableKey]
        end
      elseif private[variableKey] ~= nil then
        error("cannot read a private property")
      elseif setter[variableKey] ~= nil then
        print(("the setter only property `%s` can not be accessed"):format(variableKey))
      else print(("something went wrong when trying to access `%s`"):format(variableKey)) end
    end,
    __newindex = function (t, variableKey, variableValue)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      if setter[variableKey] ~= nil then
        if setProperties["static"][variableKey] then
          set(variableValue, setter[variableKey][2] or "any", variableKey, setProperties)
        else isStatic(setter, variableKey, "set") return end
      elseif accessor[variableKey] ~= nil then
        if accessorProperties["static"][variableKey] then
          set(variableValue, accessor[variableKey][2] or "any", variableKey, accessorProperties)
        else isStatic(accessor, variableKey, "accessor") return end
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
    blood = {false, "any"},
  },
  set = {
    date = {2026, "number"},
  },
  accessor = {
    age = {20, "number", true},
    name = {"Dev", "string"},
  },
  constructor = function(self, super, name, age)
    self.name = name
    myClass.age = age
  end
})

print(myClass.age)

-- local Person = myClass:new()
-- print(Person.blood)
-- Person.date = 2005
-- print(Person.date)
-- print(Person.age)
-- Person.age = 21



