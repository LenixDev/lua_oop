local class<const> = function (fields)
  local defined<const> = {}
  local private<const> = fields.private or {}
  local getter<const> = fields.get or {}
  local setter<const> = fields.set or {}
  local accessor<const> = fields.accessor or {}
  local privates<const> = {}
  local setProperties<const> = {}
  local getProperties<const> = {}
  local accessorProperties<const> = {}

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
      if isVariableEligible(variable, valueType, value) then
      -- fill table with keys and values
        target[variable] = value
      end
    end
  end

  local set<const> = function(variableValue, isStatic, variableType, variableKey, field)
    if not isStatic then
      print(("property `%s` is not a `static` set or accessor property"):format(variableKey))
      return
    end
    if type(variableValue) ~= variableType and variableType ~= "any" then
      print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), variableType, variableKey))
      return
    end
    field[variableKey] = variableValue
    getProperties[variableKey] = variableValue
  end

  local isStatic<const> = function(field, variableKey)
    if not field[variableKey][3] then
      print(("property `%s` is not a `static` get or accessor property"):format(variableKey))
      return false
    else return true end
  end

  local instances = {}
  local constructor = fields.constructor
  return setmetatable({
    new = function (self, ...)
      return self
    end
  }, {
    __index = function(_, variableKey)
      assert(defined[variableKey], ("property `%s` not found"):format(variableKey))
      -- isPropertyExist
      if getter[variableKey] ~= nil then
        if isStatic(getter, variableKey) then
          -- returnPropertyValue
          return getProperties[variableKey]
        end
      elseif accessor[variableKey] ~= nil then
        if isStatic(accessor, variableKey) then
          return accessorProperties[variableKey]
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
        set(variableValue, setter[variableKey] and setter[variableKey][3], setter[variableKey][2] or "any", variableKey, setProperties)
      elseif accessor[variableKey] ~= nil then
        set(variableValue, accessor[variableKey] and accessor[variableKey][3], accessor[variableKey][2] or "any", variableKey, accessorProperties)
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

local Person = myClass:new("Lenix")
print(Person.blood)
Person.date = 2005
print(Person.date)
print(Person.age)
Person.age = 21


