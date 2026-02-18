assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")


---@alias MemberKey string | "get" | "set" | "constructor"
---@alias Member ShorthandedMemberValue | MemberEntries | Getter | Setter | Constructor
---@alias ShorthandedMemberValue number | string | boolean | fun(self: unknown, ...: unknown): unknown?
---@alias MemberEntries {[1]: MemberValue, [2]?: MemberFlag, [3]?: MemberFlag, [4]?: MemberFlag, [5]?: MemberFlag, [6]?: MemberFlag}
---@alias MemberValue number | string | boolean | table | nil | fun(self: unknown, ...: unknown): unknown
---@alias MemberFlag boolean | nil
---@alias Getter fun(self: unknown): unknown
---@alias Setter fun(self: unknown, value: unknown): nil
---@alias Constructor fun(self: unknown, super: fun(...: any): unknown, ...: unknown): unknown
---@alias Members table<string, PropertyFlags>
---@alias MembersValues table<string, MemberValue>
---@alias RawMembers table<MemberKey, Member>

---@class PropertyFlags
---@field private MemberFlag
---@field static MemberFlag
---@field final MemberFlag
---@field virtual MemberFlag
---@field override MemberFlag

---@param Members RawMembers
---@param Parent? unknown
local class<const> = function (Members, Parent)
  ---@type Members
  local members<const> = {}
  ---@type MembersValues
  local membersValues<const> = {}
  local default<const> = function(existingValue, defaultValue)
    if existingValue ~= nil then
      return existingValue
    else return defaultValue end
  end
  ---@type table<string, Getter>
  local getters<const> = {}
  ---@type table<string, Setter>
  local setters<const> = {}

  for memberKey, member in pairs(Members) do
    assert(member ~= nil, ("syntax error: expected member, got `%s`"):format(type(member)))
    if memberKey == "constructor" then
      if type(member) ~= "function" then error(("syntax error: constructor expected `function`, got `%s`"):format(type(member))) end
    elseif memberKey == "get" then
      if type(member) ~= "table" then error(("syntax error: get expected `table`, got `%s`"):format(type(member))) end
      ---@cast member table<string, Getter>
      for getterKey, getter in pairs(member) do
        if type(getter) ~= "function" then error(("syntax error: the getters(`%s`) can be only a `function`, got `%s`"):format(getterKey, type(getter))) end
        local getterInfo = debug.getinfo(getter, "u")
        if getterInfo.nparams ~= 1 then error(("syntax error: the getters(`%s`) can not have parameters (excluding `self`)"):format(getterKey)) end
        getters[getterKey] = getter
      end
    elseif memberKey == "set" then
      if type(member) ~= "table" then error(("syntax error: set expected `table`, got `%s`"):format(type(member))) end
      ---@cast member table<string, Setter>
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
          final = default(member[4], false),
          virtual = default(member[5], false),
          override = default(member[6], true),
        }
      else
        membersValues[memberKey] = member
        members[memberKey] = {
          private = true,
          static = false,
          final = true,
          virtual = false,
          override = false,
        }
      end
    end
  end

  for memberKey, member in pairs(members) do
    if member.override then
      if not Parent or not Parent.__extended then
        error(("cannot override `%s`: no parent class was derived"):format(memberKey))
      end

      local parentMember = Parent.__extended.members[memberKey]
      if not parentMember then
        error(("override failed: no such `%s` parent method"):format(memberKey))
      end

      if not parentMember.virtual then
        error(("override denied: the parent method `%s` is not virtual"):format(memberKey))
      end
    end
  end

  if Parent and Parent.__extended then
    for memberKey, member in pairs(Parent.__extended.members) do
      if not members[memberKey] then
        members[memberKey] = member
        membersValues[memberKey] = Parent.__extended.membersValues[memberKey]
      else
        if not members[memberKey].override then
          error(("method `%s` already exists in parent, did you mean to use the override flag"):format(memberKey))
        end
      end
    end

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
      ---@type MembersValues
      local instance<const> = {}
      for memberKey, member in pairs(members) do
        if not member.static then
          instance[memberKey] = membersValues[memberKey]
        end
      end

      if Members.constructor and not Parent then
        Members.constructor(instance, nil, ...)
      elseif Members.constructor and Parent then
        local super<const> = function(...)
          local parentInstance<const> = Parent:new(...)

          local parentMetatable<const> = debug.getmetatable(parentInstance)
          if parentMetatable and parentMetatable.__instance then
            for memberKey, memberValue in pairs(parentMetatable.__instance) do
              local parentMember = Parent.__extended.members[memberKey]
              if members[memberKey] and members[memberKey].override then
              elseif parentMember and not parentMember.private then
                instance[memberKey] = memberValue
              end
            end
          end

          return parentInstance
        end
        Members.constructor(instance, super, ...)
      else error("no constructor was provided") end

      for memberKey, member in pairs(members) do
        if not instance[memberKey] and not member.static and not member.private then
          error(("the `%s` was not instantiated in constructor"):format(memberKey))
        end
      end

      if Parent and Parent.__extended then
        for memberKey, member in pairs(Parent.__extended.members) do
          if not instance[memberKey] and not member.static and not member.private then
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
            elseif Parent and Parent.__extended then
              local parentMember = Parent.__extended.members[memberKey]
              if parentMember then
                if parentMember.private then
                  error(("`%s` is not a public member"):format(memberKey))
                end
                return instance[memberKey]
              end
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
          assert(not member.final, ("`%s` is a readonly member"):format(memberKey))

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
        return function(...)
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
      assert(not member.final, ("`%s` is a readonly member"):format(memberKey))
      membersValues[memberKey] = memberValue
    end
  })
end


-- annotation tests section
class({
  data1 = 10,
  data2 = "hello",
  data3 = true,
  data4 = function(self) end,
  data5 = {10},
  data6 = {"hello"},
  data7 = {true},
  data8 = {function(self) end},
  data9 = {10, true, false, true, false, true},
  data10 = {"hello", true, false, true, false, true},
  data11 = {true, true, false, true, false, true},
  data12 = {function(self) end, true, false, true, false, true},
  get = {
    data1 = function(self)
      return self.data1 --10
    end,
  },
  set = {
    data1 = function(self, value)
      self.data1 = value --10
    end,
  },
  constructor = function(self, super, value)
    super(value)
    self.data1 = value
  end
})