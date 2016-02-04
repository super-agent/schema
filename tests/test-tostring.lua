local Schema = require('../schema')
local p = require('pretty-print').prettyPrint

local Any = Schema.Any
local Truthy = Schema.Truthy
local Int = Schema.Int
local Number = Schema.Number
local String = Schema.String
local Bool = Schema.Bool
local Function = Schema.Function
local Array = Schema.Array
local Type = Schema.Type
local checkType = Schema.checkType
local addSchema = Schema.addSchema

local function test(typ, expected)
  local actual = tostring(checkType(typ))
  if expected == actual then
    p(expected)
  else
    p(typ)
    error(string.format("Expected %s, but got %s", expected, actual))
  end
end

test(Any, "Any")
test(Truthy, "Truthy")
test(Int, "Int")
test(Number, "Number")
test(String, "String")
test(Bool, "Bool")
test(Function, "Function")
test(Array(Int), "Array<Int>")
test({name=String,age=Int}, "{name: String, age: Int}")
test({Bool,Int,Type}, "(Bool, Int, Type)")
test(addSchema("add", {{"a",Int},{"b",Int}}, Int, print),
  "add(a: Int, b: Int): Int")
test(addSchema("addSchema",
  { {"name",String},
    {"inputs", Array({String,Type})},
    {"output",Type},
    {"fn",Function} },
  Function, print),
  "addSchema(name: String, inputs: Array<(String, Type)>, output: Type, fn: Function): Function"
)
