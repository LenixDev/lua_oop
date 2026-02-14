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
      local value<const> = values[1]
      local valueType<const> = values[3] or "any"
      if isVariableEligible(variable, valueType, value) then
        target[variable] = value
      end
    end
  end

  local set<const> = function(variableValue, variableType, variableKey, field)
    if type(variableValue) ~= variableType and variableType ~= "any" then
      print(("cannot assign `%s` to `%s` on `%s`"):format(type(variableValue), variableType, variableKey))
      return
    end
    field[variableKey] = variableValue
    getProperties[variableKey] = variableValue
  end

  -- local constructor = fields.constructor or function() end
  return setmetatable({}, {
    __index = function(_, key)
      if getter[key] ~= nil and getter[key][2] then
        return getProperties[key]
      elseif accessor[key] ~= nil then
        return accessorProperties[key]
      elseif private[key] ~= nil then
        error("cannot read a private property")
      elseif setter[key] ~= nil then
        print("setter only property can not be accessed")
      else
        print(("property `%s` not found"):format(key))
      end
    end,
    __newindex = function (t, variableKey, variableValue)
      if setter[variableKey] ~= nil then
        set(variableValue, setter[variableKey][3] or "any", variableKey, setProperties)
      elseif accessor[variableKey] ~= nil then
        set(variableValue, accessor[variableKey][3] or "any", variableKey, accessorProperties)
      elseif getter[variableKey] ~= nil then
        print("getter only property can not be set")
      else
        print(("property `%s` not found"):format(variableKey))
      end
    end
  })
end

local myClass<const> = class({
  private = {
    height = {197, true},
  },
  get = {
    blood = {"O+", true, "string"},
  },
  set = {
    date = {2005, true},
  },
  accessor = {
    age = {20, true},
    name = {"Dev", true},
  },
  constructor = function(name, age)
    self.name = name
    self.age = age
  end
})

print(myClass.age)
print(myClass.name)
myClass.age = "21"
myClass.name = "Lenix"
myClass.date = "today"
print(myClass.age)
print(myClass.name)