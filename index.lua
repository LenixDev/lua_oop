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
    local source, target = pair[1], pair[2]
    for variable, values in pairs(source) do
      -- getPropertyValue
      local value<const> = type(values) == "table" and values[1]
      -- getPropertyType
      local valueType<const> = type(values) == "table" and values[2] or "any"
      if isVariableEligible(variable, valueType, value) then
        -- fill table with keys and values
        if target then
          target[variable] = value
        else
          -- for the accessor, get and set permission
          getProperties[variable] = value
          setProperties[variable] = value
        end
      end
    end
  end

  return setmetatable({
    new = function(self, ...)
      local instance = {}

      for _, fields in pairs(fieldPairs) do
        for _, field in pairs(fields) do
          for varKey, varValue in pairs(field) do
            instance[varKey] = varValue
          end
        end
      end

      setmetatable(instance, getmetatable(self))

      fields.constructor(instance, nil, ...)

      return instance
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
print(Person.name, Person.blood)
local Person1 = myClass:new("Lenix", 44)
print(Person1.name, Person.name)
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




