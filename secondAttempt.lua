assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (fields)
  local definedProperties<const> = {}
  local promisedToBeConstructed<const> = {}
  local private<const> = fields.private or {}
  local getter<const> = fields.get or {}
  local setter<const> = fields.set or {}
  local accessor<const> = fields.accessor or {}
  local privates<const> = {}
  local setProperties<const> = {}
  local getProperties<const> = {}

  local isVariableEligible<const> = function (propertyKey, propertyType, propertyValue)
    if definedProperties[propertyKey] then
      print(("`%s` is already defined"):format(propertyKey))
      return
    elseif type(propertyValue) ~= propertyType and propertyType ~= "any" and propertyValue ~= nil then
      error(("type mismatch for `%s`, defined `%s`, appointed `%s`"):format(propertyKey, propertyType, type(propertyValue)))
      return
    end
    definedProperties[propertyKey] = true
    if propertyType == "any" then
      print(("variable `%s` implicitly has type `%s`"):format(propertyKey, propertyType, type(propertyValue)))
    end
    if propertyValue == nil and propertyType ~= "nil" then
      promisedToBeConstructed[propertyKey] = true
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
    for propertyKey, propertyValues in pairs(field) do
      -- getPropertyValue
      local propertyValue<const> = type(propertyValues) == "table" and propertyValues[1]
      -- getPropertyType
      assert(type(propertyValues) == 'table', ("syntax error at `%s`, expected `%s`, got `%s`"):format(propertyKey, "table", type(propertyValues)))
      local propertyType<const> = propertyValues[2]
      if isVariableEligible(propertyKey, propertyType, propertyValue) then
        -- fill table with keys and values
        if properties then
          properties[propertyKey] = propertyValue
        else
          -- for the accessor, filling the get and set permission
          getProperties[propertyKey], setProperties[propertyKey] = propertyValue, propertyValue
          setter[propertyKey], getter[propertyKey] = accessor[propertyKey], accessor[propertyKey]
        end
      end
    end
  end

  local get<const> = function (self, propertyKey)
    if definedProperties[propertyKey] then
      if getter[propertyKey] then
        if type(self[propertyKey]) == 'function' then
          return function(...) return self[propertyKey](self, ...) end
        end
        return self[propertyKey]
      elseif private[propertyKey] then
        print(("private property `%s` is not allowed to be accessed"):format(propertyKey))
      else print(("tried to get the `%s` set-only property"):format(propertyKey)) end
    else
      print(("`%s` property does not exist"):format(propertyKey))
    end
  end
  local set<const> = function (self, propertyKey, propertyValue)
    if definedProperties[propertyKey] then
      if setter[propertyKey] then
        if type(propertyValue) == setter[propertyKey][2] or setter[propertyKey][2] == "any" then
          self[propertyKey] = propertyValue
        else print(("`%s` is not assignable to `%s`: on `%s`"):format(type(propertyValue), setter[propertyKey][2], propertyKey)) end
      elseif private[propertyKey] then
        print(("private property `%s` is not allowed to be assigned"):format(propertyKey))
      else print(("tried to set the `%s` get-only property"):format(propertyKey)) end
    else
      print(("`%s` property does not exist"):format(propertyKey))
    end
  end

  return setmetatable({
    new = function(self, ...)
      local instance<const> = {}

      for _, pair in pairs(fieldPairs) do
        for propertyKey, propertyValue in pairs(pair[2] or {}) do
          instance[propertyKey] = propertyValue
        end
      end

      setmetatable(instance, getmetatable(self))

      if fields.constructor then
        fields.constructor(instance, nil, ...)
      else error('no constructor was provided') end

      -- Constructor has finished, now validate
      for propertyKey in pairs(promisedToBeConstructed) do
        if instance[propertyKey] == nil then
          error(('the `%s` was not instantiated in constructor as promised'):format(propertyKey))
        end
      end

      return setmetatable({}, {
        __index = function(_, propertyKey)
          return get(instance, propertyKey)
        end,
        __newindex = function(_, propertyKey, varValue)
          set(instance, propertyKey, varValue)
        end
      })
    end
  }, { })
end

local myClass<const> = class({
  private = {
    height = {nil, "number"},
  },
  get = {
    blood = {nil, "string"},
    getHeight = {function(self, new)
      self.setHeight(self, new)
      return self.height
    end, "function"}
  },
  set = {
    setHeight = {
      function(self, new)
        self.height = new
      end, "function"
    },
  },
  accessor = {
    name = {nil, "string"},
    age = {nil, "number"},
  },
  constructor = function(self, super, name, age, height, blood)
    self.name = name
    self.age = age
    self.height = height
    self.blood = blood
  end
})


local Class<const> = myClass:new("Lenix", 20, 197, "O+")
Class.setHeight = function(self, new)
  self.height = new
end



print(Class.getHeight(198))





