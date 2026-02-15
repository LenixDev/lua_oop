assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local log<const> = function(...)
  local args = {...}
  for i, v in pairs(args) do
    if type(v) == 'table' then
      for k, j in pairs(v) do
        print(("[%s]: [%s]: %s"):format(i, k, j))
      end
    end
  end
end

local class<const> = function (fields)
  local defined<const> = {}
  local promisedToBeConstructed<const> = {}
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
    elseif type(value) ~= valueType and valueType ~= "any" and value ~= nil then
      error(("type mismatch for `%s`, defined `%s`, appointed `%s`"):format(variable, valueType, type(value)))
      return
    end
    defined[variable] = true
    if valueType == "any" then
      print(("variable `%s` implicitly has type `%s`"):format(variable, valueType, type(value)))
    end
    if value == nil and valueType ~= "nil" then
      promisedToBeConstructed[variable] = true
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
    local field<const>, properties<const> = pair[1], pair[2]
    for variable, values in pairs(field) do
      -- getPropertyValue
      local value<const> = type(values) == "table" and values[1]
      -- getPropertyType
      local valueType<const> = values[2]
      if isVariableEligible(variable, valueType, value) then
        -- fill table with keys and values
        if properties then
          properties[variable] = value
        else
          -- for the accessor, filling the get and set permission
          getProperties[variable] = value
          setProperties[variable] = value
          setter[variable] = accessor[variable]
          getter[variable] = accessor[variable]
        end
      end
    end
  end

  local get<const> = function (self, varKey)
    if defined[varKey] then
      if getter[varKey] then
        return self[varKey]
      elseif private[varKey] then
        print(("private property `%s` is not allowed to be accessed"):format(varKey))
      else print(("tried to get the `%s` set-only property"):format(varKey)) end
    else
      print(("`%s` property does not exist"):format(varKey))
    end
  end
  local set<const> = function (self, varKey, varValue)
    if defined[varKey] then
      if setter[varKey] then
        if type(varValue) == setter[varKey][2] or setter[varKey][2] == "any" then
          self[varKey] = varValue
        else print(("`%s` is not assignable to `%s`: on `%s`"):format(type(varValue), setter[varKey][2], varKey)) end
      elseif private[varKey] then
        print(("private property `%s` is not allowed to be assigned"):format(varKey))
      else print(("tried to set the `%s` get-only property"):format(varKey)) end
    else
      print(("`%s` property does not exist"):format(varKey))
    end
  end

  return setmetatable({
    new = function(self, ...)
      local instance<const> = {}

      for _, pair in pairs(fieldPairs) do
        for varKey, varValue in pairs(pair[2] or {}) do
          instance[varKey] = varValue
        end
      end

      setmetatable(instance, getmetatable(self))

      if fields.constructor then
        fields.constructor(instance, nil, ...)
      else error('no constructor was provided') end

      -- Constructor has finished, now validate
      for varKey in pairs(promisedToBeConstructed) do
        if instance[varKey] == nil then
          error(('the `%s` was not instantiated in constructor as promised'):format(varKey))
        end
      end
      
      return setmetatable({}, {
        __index = function(_, varKey)
          return get(instance, varKey)
        end,
        __newindex = function(_, varKey, varValue)
          set(instance, varKey, varValue)
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
    blood = {function(self) return self end, "function"},
  },
  set = {
    date = {function(self) print(self) end, "function"},
  },
  accessor = {
    name = {nil, "string"},
    age = {nil, "number"},
    getBlood = {function(self) return self end, "function"}
  },
  constructor = function(self, super, name, age)
    self.name = name
    self.age = age
  end
})




