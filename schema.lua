--[[lit-meta
  name = "creationix/schema"
  version = "1.0.2"
  homepage = "https://github.com/creationix/lua-schema"
  description = "A runtime type-checking system to validate API functions."
  tags = {"schema", "type", "api"}
  license = "MIT"
  contributors = {
    "Tim Caswell",
  }
]]

local concat = table.concat
local pack = table.pack or function (...)
  local packed = {...}
  packed.n = select("#", ...)
  return packed
end

local function capitalize(name)
  return (name:gsub("^%l", string.upper))
end


local function guessType(value)
  local isRecord = true
  local isTuple = true
  local i = 1
  for k in pairs(value) do
    if k ~= i then
      isTuple = false
    end
    if type(k) ~= "string" then
      isRecord = false
    end
    i = i + 1
  end
  return isRecord, isTuple
end
--------------------------------------

local Any = setmetatable({}, {
  __tostring = function (self)
    return self.alias or "Any"
  end,
  __call = function (_, name, value)
    if value == nil then
      return name, "Any", "Nil"
    end
    return name, "Any"
  end
})

local Truthy = setmetatable({}, {
  __tostring = function (self)
    return self.alias or "Truthy"
  end,
  __call = function (_, name, value)
    if not value then
      return name, "Truthy", capitalize(type(value))
    end
    return name, "Truthy"
  end
})

-- Ensure a value is an integer
local Int = setmetatable({}, {
  __tostring = function (self)
    return self.alias or "Int"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t ~= "number" then
      return name, "Int", capitalize(t)
    end
    if value % 1 ~= 0 then
      return name, "Int", "Float"
    end
    return name, "Int"
  end
})

local Number = setmetatable({}, {
  __tostring = function(self)
    return self.alias or "Number"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t ~= "number" then
      return name, "Number", capitalize(t)
    end
    return name, "Number"
  end
})

local String = setmetatable({}, {
  __tostring = function(self)
    return self.alias or "String"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t ~= "string" then
      return name, "String", capitalize(t)
    end
    return name, "String"
  end
})

local Bool = setmetatable({}, {
  __tostring = function(self)
    return self.alias or "Bool"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t ~= "boolean" then
      return name, "Bool", capitalize(t)
    end
    return name, "Bool"
  end
})

local Function = setmetatable({}, {
  __tostring = function(self)
    return self.alias or "Function"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t ~= "function" then
      local meta = getmetatable(value)
      if not (meta and meta.__call) then
        return name, "Function", capitalize(t)
      end
    end
    return name, "Function"
  end
})

local checkType

local recordMeta = {
  __tostring = function (self)
    if self.alias then return self.alias end
    local parts = {}
    local i = 1
    for k, v in pairs(self.struct) do
      parts[i] = k .. ": " .. tostring(v)
      i = i + 1
    end
    return "{" .. concat(parts, ", ") .. "}"
  end,
  __call = function (self, name, value)
    local t = type(value)
    if t ~= "table" then
      return name, tostring(self), capitalize(t)
    end
    for k, subType in pairs(self.struct) do
      local v = value[k]
      local subName, expected, actual = subType(name .. "." .. k, v)
      if actual then
        return subName, expected, actual
      end
    end
    return name, tostring(self)
  end
}
local function Record(struct)
  for k, v in pairs(struct) do
    struct[k] = checkType(v)
  end
  return setmetatable({struct = struct}, recordMeta)
end

local tupleMeta = {
  __tostring = function (self)
    if self.alias then return self.alias end
    local parts = {}
    for i = 1, #self.list do
      parts[i] = tostring(self.list[i])
    end
    return "(" .. concat(parts, ", ") .. ")"
  end,
  __call = function (self, name, value)
    local t = type(value)
    if t ~= "table" then
      return name, tostring(self), capitalize(t)
    end
    if #value ~= #self.list then
      local parts = {}
      for i = 1, #value do
        parts[i] = capitalize(type(value[i]))
      end
      return name, tostring(self), "[" .. concat(parts, ", ") .. "]"
    end
    for i = 1, #self.list do
      local subType = self.list[i]
      local v = value[i]
      local subName, expected, actual = subType(name .. "[" .. i .. "]", v)
      if actual then
        return subName, expected, actual
      end
    end
    return name, tostring(self)
  end
}
local function Tuple(list)
  for i = 1, #list do
    list[i] = checkType(list[i])
  end
  return setmetatable({list = list}, tupleMeta)
end

local namedTupleMeta = {
  __tostring = function (self)
    if self.alias then return self.alias end
    local parts = {}
    for i = 1, #self.list do
      local name, type = unpack(self.list[i])
      parts[i] = name .. ": " .. tostring(type)
    end
    return "(" .. concat(parts, ", ") .. ")"
  end,
  __call = function (self, name, value)
    local t = type(value)
    if t ~= "table" then
      return name, tostring(self), capitalize(t)
    end
    if #value ~= #self.list then
      local parts = {}
      for i = 1, #value do
        parts[i] = capitalize(type(value[i]))
      end
      return name, tostring(self), "[" .. concat(parts, ", ") .. "]"
    end
    for i = 1, #self.list do
      local slotName, subType = unpack(self.list[i])
      local v = value[i]
      local subName, expected, actual = subType(name .. "." .. slotName, v)
      if actual then
        return subName, expected, actual
      end
    end
    return name, tostring(self)
  end
}
local function NamedTuple(list)
  assert(type(list) == "table", "NamedTuple needs list of name/type pairs")
  for i = 1, #list do
    local pair = list[i]
    assert(type(pair) == "table" and #pair == 2, "NamedTuple needs name/type pairs")
    local name, typ = unpack(pair)
    assert(type(name) == "string", "Keys in named tuple must be string")
    list[i] = {name, checkType(typ)}
  end
  return setmetatable({list = list}, namedTupleMeta)
end

function checkType(value)
  if getmetatable(value) then
    return value
  elseif type(value) == "table" then
    local isRecord, isTuple = guessType(value)
    if isRecord then
      return Record(value)
    elseif isTuple then
      return Tuple(value)
    end
  end
  error("Invalid schema type, record, or tuple: ", type(value))
end

local arrayMeta = {
  __tostring = function (self)
    return self.alias or "Array<" .. tostring(self.subType) .. ">"
  end,
  __call = function (self, name, value)
    local t = type(value)
    if t ~= "table" then
      return name, tostring(self), capitalize(t)
    end
    local i = 1
    for k, v in pairs(value) do
      if k ~= i then
        return name, tostring(self), "Table"
      end
      local subName, expected, actual = self.subType(name .. "[" .. i .. "]", v)
      if actual then
        return subName, expected, actual
      end
      i = i + 1
    end
    return name, tostring(self)
  end
}
local function Array(subType)
  return setmetatable({subType = checkType(subType)}, arrayMeta)
end

local optionalMeta = {
  __tostring = function (self)
    return self.alias or tostring(self.subType) .. "?"
  end,
  __call = function (self, name, value)
    if value == nil then
      return name, tostring(self)
    end
    return self.subType(name, value)
  end
}
local function Optional(subType)
  return setmetatable({subType = checkType(subType)}, optionalMeta)
end

local Type = setmetatable({}, {
  __tostring = function (_)
    return "Type"
  end,
  __call = function (_, name, value)
    -- Ensure it's a table
    local t = type(value)
    if t ~= "table" then
      return name, "Type", capitalize(t)
    end
    -- Check for pre-compiled types
    local meta = getmetatable(value)
    if meta and meta.__tostring and meta.__call then
      return name, "Type"
    end
    -- Check for record or tuple shaped tables
    local isRecord, isTuple = guessType(value)
    if isRecord or isTuple then
      return name, "Type"
    end
    return name, "Type", capitalize(t)
  end
})

local schemaMeta = {
  __tostring = function (self)
    local parts = {}
    for i = 1, #self.inputs do
      local name, typ = unpack(self.inputs[i])
      parts[i] = name .. ": " .. tostring(typ)
    end
    local parts2 = {}
    for i = 1, #self.outputs do
      local name, typ = unpack(self.outputs[i])
      parts2[i] = name .. ": " .. tostring(typ)
    end
    return string.format("%s (%s) -> (%s)",
      self.name,
      concat(parts, ", "),
      concat(parts2, ", ")
    )
  end,
  __call = function (self, ...)
    local args = pack(...)
    local argc = args.n
    if argc ~= #self.inputs then
      return nil,
        string.format("%s - expects %d arguments, but %d %s sent.",
          tostring(self),
          #self.inputs,
          argc,
          argc == 1 and "was" or "were")
    end
    for i = 1, argc do
      local arg, typ = unpack(self.inputs[i])
      local name, expected, actual = typ(arg, args[i])
      if actual then
        return nil,
          string.format("%s - expects %s to be %s, but it was %s.",
            tostring(self),
            name, expected, actual)
      end
    end
    local rets = pack(self.fn(...))
    local retc = rets.n
    if retc ~= #self.outputs then
      return nil,
        string.format("%s - expects %d return %s, but %d %s returned.",
          tostring(self),
          #self.outputs,
          #self.outputs == 1 and "value" or "values",
          retc,
          retc == 1 and "was" or "were")
    end
    for i = 1, retc do
      local ret, typ = unpack(self.outputs[i])
      local name, expected, actual = typ(ret, rets[i])
      if actual then
        return nil,
          string.format("%s - expects %s to be %s, but it was %s.",
            tostring(self),
            name, expected, actual)
      end
    end
    return unpack(rets)
  end
}
local function addSchema(name, inputs, outputs, fn)
  local newInputs = {}
  for i = 1, #inputs do
    newInputs[i] = {
      inputs[i][1],
      checkType(inputs[i][2])
    }
  end
  local newOutputs = {}
  for i = 1, #outputs do
    newOutputs[i] = {
      outputs[i][1],
      checkType(outputs[i][2])
    }
  end
  return setmetatable({
    name = name,
    inputs = newInputs,
    outputs = newOutputs,
    fn = fn,
  }, schemaMeta)
end

-- Make addSchema typecheck itself.
addSchema = assert(addSchema("addSchema", {
  {"name",String},
  {"inputs", Array({String,Type})},
  {"outputs", Array({String,Type})},
  {"fn",Function}
}, {
  {"fn",Function}
}, addSchema))

local function makeAlias(name, typ)
  typ = checkType(typ)
  local copy = {}
  for k, v in pairs(typ) do
    copy[k] = v
  end
  setmetatable(copy, getmetatable(typ))
  copy.alias = name
  return copy
end

return {
  Any = Any,
  Truthy = Truthy,
  Int = Int,
  Number = Number,
  String = String,
  Bool = Bool,
  Function = Function,
  Array = Array,
  Optional = Optional,
  Record = Record,
  Tuple = Tuple,
  NamedTuple = NamedTuple,
  Type = Type,
  checkType = checkType,
  addSchema = addSchema,
  makeAlias = makeAlias,
}
