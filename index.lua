assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (Members)
  local members<const> = {}
  local membersValues<const> = {}
  local default<const> = function(existingValue, defaultValue)
    if existingValue ~= nil then return existingValue else return defaultValue end
  end
  local getters<const> = {}
  local setters<const> = {}

  -- initialize
  for memberKey, member in pairs(Members) do
    if memberKey == "constructor" then
      if type(member) ~= "function" then error(("syntax error: constructor expected `function`, got `%s`"):format(type(member))) end
    elseif memberKey == "get" then
      if type(member) ~= "table" then error(("syntax error: get expected `table`, got `%s`"):format(type(member))) end
      for getterKey, getter in pairs(member) do
        if type(getter) ~= "function" then error(("syntax error: the getters(`%s`) can be only a `function`, got `%s`"):format(getterKey, type(getter))) end
        local getterInfo = debug.getinfo(getter, "u")
        if getterInfo.nparams ~= 1 then error(("syntax error: the getters(`%s`) can not have parameters"):format(getterKey)) end
        getters[getterKey] = getter
      end
    elseif memberKey == "set" then
      if type(member) ~= "table" then error(("syntax error: set expected `table`, got `%s`"):format(type(member))) end
      for setterKey, setter in pairs(member) do
        if type(setter) ~= "function" then error(("syntax error: the setters(`%s`) can be only a `function`, got `%s`"):format(setterKey, type(setter))) end
        local getterInfo = debug.getinfo(setter, "u")
        if getterInfo.nparams ~= 2 then error(("syntax error: the setters(`%s`) must have exactly one parameter"):format(setterKey)) end
        setters[setterKey] = setter
      end
    else
      members[memberKey] = {}
      if type(member) == "table" then
        membersValues[memberKey] = member[1]
        members[memberKey] = {
          isPrivate = default(member[2], true),
          isStatic = default(member[3], false),
          isConst = default(member[4], false),
        }
      else
        membersValues[memberKey] = member
        members[memberKey] = {
          isPrivate = true,
          isStatic = false,
          isConst = true,
        }
      end
    end
  end

  return setmetatable({
    new = function(self, ...)
      local instance<const> = {}
      for memberKey, member in pairs(members) do
        if not member.isStatic then
          instance[memberKey] = membersValues[memberKey]
        end
      end

      if Members.constructor then
        Members.constructor(instance, nil, ...)
      else error("no constructor was provided") end

      for memberKey in pairs(members) do
        if not instance[memberKey] and not members[memberKey].isStatic then
          error(("the `%s` was not instantiated in constructor"):format(memberKey))
        end
      end

      return setmetatable({}, {
        __metatable = "access denied",
        __index = function(_, memberKey)
          if getters[memberKey] then
            return getters[memberKey](instance)
          end
          local member<const> = members[memberKey]
          if not member then error(("`%s` does not exist"):format(memberKey)) end
          assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
          assert(not member.isStatic, ("`%s` is static member"):format(memberKey))

          local value<const> = instance[memberKey]

          if type(value) == "function" then
            return function(_, ...)
              return value(instance, ...)
            end
          end

          return value
        end,
        __newindex = function(_, memberKey, memberKeyValue)
          if setters[memberKey] then
            setters[memberKey](instance, memberKeyValue)
            return
          end
          local member<const> = members[memberKey]
          if not member then error(("`%s` does not exist"):format(memberKey)) end
          assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
          assert(not member.isStatic, ("`%s` is static member"):format(memberKey))
          assert(not member.isConst, ("`%s` is constant member"):format(memberKey))
          instance[memberKey] = memberKeyValue
        end
      })
    end
  }, {
    __metatable = "access denied",
    __index = function(self, memberKey)
      local member<const> = members[memberKey]
      if not member then 
        if getters[memberKey] then
          return getters[memberKey](membersValues)
        elseif setters[memberKey] then
          error(("setters can not be accessed: at `%s`"):format(memberKey))
        end
        error(("`%s` does not exist"):format(memberKey))
      end
      assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
      assert(member.isStatic, ("`%s` is not static member"):format(memberKey))
      local value<const> = membersValues[memberKey]

      if type(value) == "function" then
        return function(_, ...)
          return value(membersValues, ...)
        end
      end

      return value
    end,
    __newindex = function(_, memberKey, memberKeyValue)
      if setters[memberKey] then
        setters[memberKey](membersValues, memberKeyValue)
        return
      end
      local member<const> = members[memberKey]
      if not member then
        if setters[memberKey] then
          setters[memberKey](membersValues, memberKeyValue)
        return
        elseif getters[memberKey] then
          error(("getters can not be modified: at `%s`"):format(memberKey))
        end
        error(("`%s` does not exist"):format(memberKey))
      end
      assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
      assert(member.isStatic, ("`%s` is not static member"):format(memberKey))
      assert(not member.isConst, ("`%s` is constant member"):format(memberKey))
      membersValues[memberKey] = memberKeyValue
    end
  })
end

local myClass<const> = class({
  name = {"Lenix", false, false, false},
  height = {nil},
  age = 20,
  getHeight = {
    function(self)
      return self.height
    end, false
  },
  setHeight = {
    function(self, height)
      self.height = height
      return true, "set successful"
    end, false, true
  },
  get = {
    getName = function(self)
      return self.name
    end,
  },
  set = {
    setName = function(self, name)
      self.name = name
      return true
    end
  },
  -- accessor = {
  --   getAge = function(self)
  --     return self.age
  --   end,
  --   setAge = function(self, age)
  --     self.age = age
  --     return true
  --   end
  -- },
  -- reserved for later uses
  -- override = {},
  constructor = function(self, super, name, age, height)
    self.name = name
    self.age = age
    self.height = height
  end
})

local Class<const> = myClass:new("Lenix", 20, 197)
print(myClass.getName)
myClass.setName = "Dev"
print(myClass.getName())

--virtual