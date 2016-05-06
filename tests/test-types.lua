if not _G.process then
  require 'luacov'
  require 'lit-loader'
end
local schema = require('../schema')
local p = require('pretty-print').prettyPrint

local Any = schema.Any
local Truthy = schema.Truthy
local Int = schema.Int
local Number = schema.Number
local String = schema.String
local Bool = schema.Bool
local Function = schema.Function
local Array = schema.Array
local Record = schema.Record
local Tuple = schema.Tuple
local Type = schema.Type
local NamedTuple = schema.NamedTuple
local checkType = schema.checkType
local addSchema = schema.addSchema

local function test(shouldPass, typ, value)
  typ = checkType(typ)
  local name, expected, actual = typ("arg", value)
  p(unpack{name, expected, value, actual})
  if shouldPass then
    if actual then
      error("Should validate, but did not: " .. tostring(typ))
    else
      print("Should validate and did: " .. tostring(typ))
    end
  else
    if not actual then
      error("Should not validate, but did: " .. tostring(typ))
    else
      print("Should not validate and did not: " .. tostring(typ))
    end
  end
end


-- Inline unit tests
test(true, Any, "wow")
test(true, Any, false)
test(false, Any)
test(true, Truthy, "wow")
test(true, Truthy, "0")
test(false, Truthy, false)
test(false, Truthy)
test(true, Int, 4)
test(false, Int, 4.5)
test(true, Number, 4.5)
test(false, Number, false)
test(true, String, "Hello")
test(false, String, 100)
test(true, Bool, true)
test(false, Bool, 0)
test(true, Array(Int), {})
test(true, Array(Int), {1,2})
test(false, Array(Int), {1, false})
test(false, Array(Int), {name="Tim"})
test(false, Array(Int), 42)
test(true, {String,Int}, {"Hello",42})
test(true, Tuple{String,Int}, {"Hello",42})
test(false, {String,Int}, {"Hello",false})
test(false, {String,Int}, {"Hello",100,true})
test(true, {}, {})
test(true, {name=String,age=Int}, {name="Tim",age=33,isProgrammer=true})
test(true, Record{name=String,age=Int}, {name="Tim",age=33})
test(true, Array({name=String}), {{name="Tim",age=33}})
test(false, Array({name=String}), {{name="Tim",age=33}, 10})
test(false, {name=String,age=Int}, {name="Tim",age="old"})
test(false, {name=String,age=Int}, {1,2,3})
test(false, {name=String,age=Int}, 757)
test(true, Function, print)
test(true, Function, Function)
test(false, Function, "Bye")
test(true, Type, Array(Bool))
test(true, Type, Int)
test(false, Type, "Cake")
test(false, Type, true)
local IntBool = NamedTuple {
  {"a", Int},
  {"b", Bool}
}
test(true, IntBool, {1, false})
test(false, IntBool, {1, 2})
test(false, IntBool, {1})
test(false, IntBool, {1, false, true})
test(false, IntBool, {true, false})

p(tostring(addSchema))
p(addSchema("bad", {false}, 2, 3))

local add = assert(addSchema("add", {{"a",Int},{"b",Int}}, {{"c",Int}}, function (a, b)
  if a == 42 then return true end
  return a + b
end))
print("Testing - " .. tostring(add))
p(assert(add(2, 3)))
p(add(false, 3))
p(add(42))
p(add(1, 2, 3))
p(add(42, 0))
