assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (fields)
  local defined<const> = {}
  local private<const> = fields.private or {}
  local getter<const> = fields.get or {}
  local setter<const> = fields.set or {}
  local accessor<const> = fields.accessor or {}
  local privates<const> = {}
  local setProperties<const> = {}
  local getProperties<const> = {}

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
    local field, properties = pair[1], pair[2]
    for variable, values in pairs(field) do
      -- getPropertyValue
      local value<const> = type(values) == "table" and values[1]
      -- getPropertyType
      local valueType<const> = type(values) == "table" and values[2] or "any"
      if isVariableEligible(variable, valueType, value) then
        -- fill table with keys and values
        if properties then
          properties[variable] = value
        else
          -- for the accessor, filling the get and set permission
          getProperties[variable] = value
          setProperties[variable] = value
        end
      end
    end
  end

  return setmetatable({
    new = function(self, ...)
      local instance = {}

      for _, pair in pairs(fieldPairs) do
        for varKey, varValue in pairs(pair[2] or {}) do
          instance[varKey] = varValue
        end
      end

      setmetatable(instance, getmetatable(self))

      fields.constructor(instance, nil, ...)

      return setmetatable({}, {
        __index = function(_, varKey)
          return instance[varKey]
        end,
        __newindex = function(_, varKey, varValue)
          
        end
      })
    end
  }, {})
end

local myClass<const> = class({
  private = {
    height = {197, "number"},
  },
  get = {
    blood = {"O+", "string"},
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


local Person<const> = myClass:new("Dev", 21)
print('------------------')
print(Person.blood)
print(Person.age)
Person.blood = "O-"
Person.age = 20
print(Person.blood)
print(Person.age)
