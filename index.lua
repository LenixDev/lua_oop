assert(_VERSION == "Lua 5.4", "THIS MODULE REQUIRES Lua 5.4")

local class<const> = function (Members)
  local members<const> = {}
  local membersValues<const> = {}
  local function default(val, def)
    if val ~= nil then return val else return def end
  end

  -- initialize
  for memberKey in pairs(Members) do
    if memberKey ~= "constructor" then
      members[memberKey] = {}
      if type(Members[memberKey]) == 'table' then
        membersValues[memberKey] = Members[memberKey][1]
        members[memberKey] = {
          isPrivate = default(Members[memberKey][2], true),
          isStatic = default(Members[memberKey][3], false),
          isConst = default(Members[memberKey][4], false),
        }
      else
        membersValues[memberKey] = Members[memberKey]
        members[memberKey] = {
          isPrivate = true,
          isStatic = false,
          isConst = true,
        }
      end
    elseif type(Members[memberKey]) ~= "function" then error("syntax error: constructor is not a function") end
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
      else error('no constructor was provided') end

      for memberKey in pairs(members) do
        if not instance[memberKey] then
          print(('the `%s` was not instantiated in constructor'):format(memberKey))
        end
      end
      

      return setmetatable({}, {
        __index = function(_, memberKey)
          local member<const> = members[memberKey]
          assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
          assert(not member.isStatic, ("`%s` is static member"):format(memberKey))
          return instance[memberKey]
        end,
        __newindex = function(_, memberKey, memberKeyValue)
          local member<const> = members[memberKey]
          assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
          assert(not member.isStatic, ("`%s` is static member"):format(memberKey))
          assert(not member.isConst, ("`%s` is constant member"):format(memberKey))
          instance[memberKey] = memberKeyValue
        end
      })
    end
  }, {
    __metatable = false,
    __index = function(self, memberKey)
      local member<const> = members[memberKey]
      assert(not member.isPrivate, ("`%s` is a private member"):format(memberKey))
      assert(member.isStatic, ("`%s` is not static member"):format(memberKey))
      local value = membersValues[memberKey]

      if type(value) == "function" then
        return function(_, ...)
          return value(membersValues, ...)
        end
      end

      return value
    end,
    __newindex = function(_, memberKey, memberKeyValue)
      local member<const> = members[memberKey]
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
    end
  },
  setHeight = {
    function(self, height)
      self.height = height
      return true, "set successful"
    end
  },
  --[[ reserved for later uses ]]
  -- get = {},
  -- set = {},
  -- accessor = {},
  -- override = {},
  constructor = function(self, super, name, age, height, blood)
    self.name = name
    self.age = age
    self.height = height
    self.blood = blood
  end
})

local Class<const> = myClass:new("Lenix", 20, 197)
-- print(Class.name)
-- Class.name = "Dev"
-- print(Class.name)
-- local Class<const> = myClass:new("Lenix", 20, 197, "O+")
-- Class.setHeight = function(self, new)
--   self.height = new
-- end



-- print(Class.getHeight(198))





--virtual