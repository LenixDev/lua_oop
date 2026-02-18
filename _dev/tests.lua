--[[ These are the tests that we have tried to get working with Lua-OOP, if you have any suggestions or improvements, please let us know. ]]

local User = class({
  name = {nil, false},
  age = {nil, false},
  constructor = function(self, super, name, age)
    self.name = name
    self.age = age
  end
})
local u = User:new("Alice", 25)
assert(u.name == "Alice" and u.age == 25, "Test 1 failed")
local User = class({
  password = {nil, true},  -- private
  constructor = function(self, super, pwd)
    self.password = pwd
  end
})
local u = User:new("secret")
local ok = pcall(function() print(u.password) end)
assert(not ok, "Test 2 failed: private property accessible")

-- Test 3: Private property accessible internally
local User = class({
  password = {nil, true},
  getPassword = {function(self) return self.password end, false},
  constructor = function(self, super, pwd)
    self.password = pwd
  end
})
local u = User:new("secret")
assert(u.getPassword() == "secret", "Test 3 failed")
local User = class({
  count = {0, false, true},  -- static
  name = {nil, false},
  constructor = function(self, super, name)
    self.name = name
  end
})
User.count = 5
local u = User:new("Alice")
local ok = pcall(function() print(u.count) end)
assert(not ok, "Test 4 failed: static accessible on instance")
assert(User.count == 5, "Test 4 failed: static not on class")

-- Test 5: Instance properties on instance, not class
local ok2 = pcall(function() print(User.name) end)
assert(not ok2, "Test 5 failed: instance accessible on class")
local User = class({
  id = {1, false, false, true},  -- immutable
  constructor = function(self, super, id)
    self.id = id
  end
})
local u = User:new(100)
local ok = pcall(function() u.id = 999 end)
assert(not ok, "Test 6 failed: immutable modified")
assert(u.id == 100, "Test 6 failed: immutable changed")

-- Test 7: Mutable property can be changed
local User = class({
  name = {nil, false, false, false},  -- mutable
  constructor = function(self, super, name)
    self.name = name
  end
})
local u = User:new("Alice")
u.name = "Bob"
assert(u.name == "Bob", "Test 7 failed")
local User = class({
  _value = {0, true},
  get = {
    value = function(self) return self._value * 2 end
  },
  constructor = function(self, super, val)
    self._value = val
  end
})
local u = User:new(5)
assert(u.value == 10, "Test 8 failed")

-- Test 9: Setter works
local User = class({
  _value = {0, true},
  getValue = {function(self) return self._value end, false},  -- Add getter
  set = {
    value = function(self, val) self._value = val * 2 end
  },
  constructor = function(self) self._value = 0 end
})
local u = User:new()
u.value = 5
assert(u.getValue() == 10, "Test 9 failed")

-- Test 10: Getter can't be modified (correct version)
local User = class({
  _value = {0, true},
  get = {
    value = function(self) return self._value end  -- Getter only, no setter
  },
  constructor = function(self) self._value = 10 end
})
local u = User:new()
local ok = pcall(function() u.value = 20 end)  -- Try to set getter-only property
assert(not ok, "Test 10 failed: getter modified")

local Parent = class({
  id = {1, false},
  constructor = function(self, super, id)
    self.id = id
  end
})
local Child = class({
  name = {nil, false},
  constructor = function(self, super, name, id)
    super(id)
    self.name = name
  end
}, Parent)
local c = Child:new("Alice", 100)
assert(c.id == 100 and c.name == "Alice", "Test 11 failed")

-- Test 12: Child inherits parent getters
local Parent = class({
  value = {10, false},
  get = {
    getValue = function(self) return self.value end
  },
  constructor = function(self, super, val)
    self.value = val
  end
})
local Child = class({
  name = {nil, false},
  constructor = function(self, super, name, val)
    super(val)
    self.name = name
  end
}, Parent)
local c = Child:new("Test", 42)
assert(c.getValue == 42, "Test 12 failed")

-- Test 13: Child inherits parent setters
local Parent = class({
  _value = {0, true},
  getValue = {function(self) return self._value end, false},
  set = {
    value = function(self, val) self._value = val * 2 end
  },
  constructor = function(self)
    self._value = 0
  end
})
local Child = class({
  name = {nil, false},
  constructor = function(self, super, name)
    super()
    self.name = name
  end
}, Parent)
local c = Child:new("Test")
c.value = 5
assert(c.getValue() == 10, "Test 13 failed")
local Parent = class({
  secret = {nil, true},  -- private
  constructor = function(self, super, sec)
    self.secret = sec
  end
})
local Child = class({
  name = {nil, false},
  constructor = function(self, super, name, sec)
    super(sec)
    self.name = name
  end
}, Parent)
local c = Child:new("Alice", "password")
local ok = pcall(function() print(c.secret) end)
assert(not ok, "Test 14 failed: parent private accessible")

-- Test 15: Parent immutable property blocked in child
local Parent = class({
  id = {1, false, false, true},  -- immutable
  constructor = function(self, super, id)
    self.id = id
  end
})
local Child = class({
  constructor = function(self, super, id)
    super(id)
  end
}, Parent)
local c = Child:new(100)
local ok = pcall(function() c.id = 999 end)
assert(not ok, "Test 15 failed: parent immutable modified")
local Parent = class({
  greet = {function(self) return "Hello from parent" end, false, false, false, true},
  constructor = function(self) end
})
local Child = class({
  greet = {function(self) return "Hello from child" end, false, false, true, false, true},
  constructor = function(self, super) super() end
}, Parent)
local c = Child:new()
print(c.greet())  -- Should print "Hello from child", probably prints "Hello from parent"
local Grandparent = class({
  id = {1, false},
  constructor = function(self, super, id)
    self.id = id
  end
})
local Parent = class({
  name = {nil, false},
  constructor = function(self, super, name, id)
    super(id)
    self.name = name
  end
}, Grandparent)
local Child = class({
  age = {nil, false},
  constructor = function(self, super, age, name, id)
    super(name, id)
    self.age = age
  end
}, Parent)
local c = Child:new(20, "Alice", 100)
assert(c.id == 100 and c.name == "Alice" and c.age == 20, "Test 17 failed")
local Parent = class({
  count = {0, false, true},  -- static
  constructor = function(self) end
})
local Child = class({
  constructor = function(self, super) super() end
}, Parent)
assert(Child.count == 0, "Test 18 failed")
-- This might fail - test it

local User = class({
  name = {nil, false},
  greet = {function(self) return "Hello " .. self.name end, false},
  constructor = function(self, super, name)
    self.name = name
  end
})
local u = User:new("Alice")
assert(u.greet() == "Hello Alice", "Test 19 failed")

-- Test 20: Static methods work
local User = class({
  create = {function(self, name) return "Created " .. name end, false, true}, -- 481
  constructor = function(self) end
})
assert(User.create("Alice") == "Created Alice", "Test 20 failed")
local User = class({
  name = {nil, false},
  constructor = function(self, super, name)
    self.name = name
  end
})
local u1 = User:new("Alice")
local u2 = User:new("Bob")
u1.name = "Charlie"
assert(u1.name == "Charlie" and u2.name == "Bob", "Test 21 failed")

-- Test 22: Metatable protection
local User = class({
  constructor = function(self) end
})
local u = User:new()
local mt = getmetatable(u)
assert(mt == "access denied", "Test 22 failed: metatable exposed")

-- Test 23: Constructor validation
local User = class({
  name = {nil, false},
  age = {nil, false},
  constructor = function(self, super, name)
    self.name = name
    -- Forgot to set age
  end
})
local ok = pcall(function() User:new("Alice") end)
assert(not ok, "Test 23 failed: validation missed unset property")


local Parent = class({
  greet = {function(self) return "Hello from parent" end, false, false, false, true}, 
  constructor = function(self) end
})

local Child = class({
  greet = {function(self) return "Hello from child" end, false, false, false, false, true},
  constructor = function(self, super) super() end
}, Parent)

local c = Child:new()
print(c.greet())  -- Should print "Hello from child"

