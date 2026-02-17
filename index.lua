assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (Members, Parent)
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
        if getterInfo.nparams ~= 1 then error(("syntax error: the getters(`%s`) can not have parameters (excluding `self`)"):format(getterKey)) end
        getters[getterKey] = getter
      end
    elseif memberKey == "set" then
      if type(member) ~= "table" then error(("syntax error: set expected `table`, got `%s`"):format(type(member))) end
      for setterKey, setter in pairs(member) do
        if type(setter) ~= "function" then error(("syntax error: the setters(`%s`) can be only a `function`, got `%s`"):format(setterKey, type(setter))) end
        local getterInfo = debug.getinfo(setter, "u")
        if getterInfo.nparams ~= 2 then error(("syntax error: the setters(`%s`) must have exactly one parameter (excluding `self`)"):format(setterKey)) end
        setters[setterKey] = setter
      end
    else
      members[memberKey] = {}
      if type(member) == "table" then
        membersValues[memberKey] = member[1]
        members[memberKey] = {
          private = default(member[2], true),
          static = default(member[3], false),
          immutable = default(member[4], false),
        }
      else
        membersValues[memberKey] = member
        members[memberKey] = {
          private = true,
          static = false,
          immutable = true,
        }
      end
    end
  end

  if Parent and Parent.__extended then
    for getterKey, getter in pairs(Parent.__extended.getters) do
      if not getters[getterKey] then
        getters[getterKey] = getter
      end
    end

    for setterKey, setter in pairs(Parent.__extended.setters) do
      if not setters[setterKey] then
        setters[setterKey] = setter
      end
    end
  end

  return setmetatable({
    __extended = {
      members = members,
      membersValues = membersValues,
      getters = getters,
      setters = setters
    },
    new = function(self, ...)
      local instance<const> = {}
      for memberKey, member in pairs(members) do
        if not member.static then
          instance[memberKey] = membersValues[memberKey]
        end
      end

      if Members.constructor and not Parent then
        Members.constructor(instance, nil, ...)
      elseif Members.constructor and Parent then
        local super = function(...)
          local parentInstance = Parent:new(...)

          local parentMetatable = debug.getmetatable(parentInstance)
          if parentMetatable and parentMetatable.__instance then
            for memberKey, memberValue in pairs(parentMetatable.__instance) do
              instance[memberKey] = memberValue
            end
          end

          return parentInstance
        end
        Members.constructor(instance, super, ...)
      else error("no constructor was provided") end

      for memberKey, member in pairs(members) do
        if not instance[memberKey] and not member.static then
          error(("the `%s` was not instantiated in constructor"):format(memberKey))
        end
      end

      if Parent and Parent.__extended then
        for memberKey, member in pairs(Parent.__extended.members) do
          if not instance[memberKey] and not member.static then
            error(("derived member `%s` was not instantiated"):format(memberKey))
          end
        end
      end

      return setmetatable({}, {
        __metatable = "access denied",
        __instance = instance,
        __index = function(_, memberKey)
          local member<const> = members[memberKey]
          if not member then 
            if getters[memberKey] then
              return getters[memberKey](instance)
            elseif Parent then
              return instance[memberKey]
            elseif setters[memberKey] then
              error(("`%s` setter can not be accessed"):format(memberKey))
            end
            error(("`%s` does not exist"):format(memberKey))  
          end
          assert(not member.private, ("`%s` is not a public member"):format(memberKey))
          assert(not member.static, ("`%s` is a static member"):format(memberKey))

          local value<const> = instance[memberKey]
          if type(value) == "function" then
            return function(_, ...)
              return value(instance, ...)
            end
          end

          return value
        end,
        __newindex = function(_, memberKey, memberValue)
          if setters[memberKey] then
            setters[memberKey](instance, memberValue)
            return
          end

          local member = members[memberKey]

          if not member and Parent and Parent.__extended then
            member = Parent.__extended.members[memberKey]
          end

          if not member then 
            if getters[memberKey] then
              error(("getters can not be modified: at `%s`"):format(memberKey))
            end
            error(("`%s` does not exist"):format(memberKey))
          end

          assert(not member.private, ("`%s` is not a public member"):format(memberKey))
          assert(not member.static, ("`%s` is a static member"):format(memberKey))
          assert(not member.immutable, ("`%s` is not a mutable member"):format(memberKey))

          instance[memberKey] = memberValue
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
        elseif Parent then
          return Parent[memberKey]
        elseif setters[memberKey] then
          error(("setters can not be accessed: at `%s`"):format(memberKey))
        end
        error(("`%s` does not exist"):format(memberKey))
      end
      assert(not member.private, ("`%s` is not a public member"):format(memberKey))
      assert(member.static, ("`%s` is not a static member"):format(memberKey))
      local value<const> = membersValues[memberKey]

      if type(value) == "function" then
        return function(_, ...)
          return value(membersValues, ...)
        end
      end

      return value
    end,
    __newindex = function(self, memberKey, memberValue)
      local member<const> = members[memberKey]
      if not member then
        if setters[memberKey] then
          setters[memberKey](membersValues, memberValue)
          return
        elseif Parent then
          Parent[memberKey] = memberValue
          return
        elseif getters[memberKey] then
          error(("getters can not be modified: at `%s`"):format(memberKey))
        end
        error(("`%s` does not exist"):format(memberKey))
      end
      assert(not member.private, ("`%s` is not a public member"):format(memberKey))
      assert(member.static, ("`%s` is not a static member"):format(memberKey))
      assert(not member.immutable, ("`%s` is not a mutable member"):format(memberKey))
      membersValues[memberKey] = memberValue
    end
  })
end





--virtual



