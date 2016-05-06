# Luvit Schema Tool

[![Build Status](https://travis-ci.org/super-agent/schema.svg?branch=master)](https://travis-ci.org/super-agent/schema)

This library allows you to decorate public API functions with strict runtime
typechecking.  You can declare the types using a clear declarative syntax
using actual type object references (to enable extensibility).

## Installing

The easiest way to install for use in a project is using `lit` from
 [luvit.io](https://luvit.io/).

```sh
lit install creationix/schema
```

## Example

For example, suppose you had a function that added two integers and returned a
new integer.  This could be defined using:

```lua
-- Load the wrapper function and the Int type
local schema = require 'schema'
local addSchema = schema.addSchema
local Int = schema.Int

-- Simple untyped function
local function add(a, b)
  return a + b
end

-- Add runtime type checking and error reporting.
add = assert(addSchema(
  "add", {
    {"a",Int},
    {"b",Int}
  }, {
    {"c",Int}
  },
  add
))
```

The `add` function has now been replaced with a schema checked function.  This
is actually a table with custom `__tostring` and `__call` metamethods.  But you
can think of it as a function.

Running `tostring(add)` will render a nice annotated type signature for the
function as seen in this luvit repl session:

```lua
> add = function(a,b) return a + b end
> add
function: 0x05f31020
> add = addSchema("add",{{"a",Int},{"b",Int}},{{"c",Int}},add)
> tostring(add)
'add (a: Int, b: Int) -> (c: Int)'
```

The new function works just like the old one, except it checks types and returns
`nil, error` in case of problems.  Make sure to use `assert` if you want this
to raise an error.

```lua
> add(1, 2)
3
> add("one", "two")
nil	'add (a: Int, b: Int) -> (c: Int) - expects a to be Int, but it was String.'
> assert(add(1, "two"))
add (a: Int, b: Int) -> (c: Int) - expects b to be Int, but it was String.
stack traceback:
	[builtin#2]: at 0x01030b64c0
	[C]: in function 'xpcall'
	[string "bundle:deps/repl.lua"]:92: in function 'evaluateLine'
	[string "bundle:deps/repl.lua"]:176: in function <[string "bundle:deps/repl.lua"]:174>
```

The `__tostring` is used internally to generate the nice error messages, but it
can also be used to generate API docs for your service when using
`creationix/schema` to typecheck your public interfaces.

## Built-in Types

- `Any` - Will match any non-nil value.

- `Truthy` - Will match any value except nil and false. false)

- `Int` - Will match whole numbers.

- `Number` - Will match any numbers.

- `String` - Will match only strings

- `Bool` - Will match only booleans.

- `Function` - Will match functions or tables with a `__call` metamethod.

- `Array(T)` - Will match tables who's indexes are only `1..n`.  Also it will
  match the values to make sure they match type T.  You can pass in any value.

- `Record` - Match using structural typing, for example `{name=String,age=Int}`.
  This will match tables that contain at least the given string keys with
  matching types.  Extra fields will be ignored.

- `Tuple` - Match a table being used as a tuple.  For example `{String, Int}`
  will match only tables with length 2 who's have matching typed values.

- `NamedTuple` - Match a table being used as a tuple, but with named positions.
  This is the same format as argument and return values in schema definitions.
  For example `{{"name",String},{"age",Int}}`

- `Type` - Matches a type.  This means it could be a record or tuple literal or
  a special table with the `__typeName` metamethod.

## API Wrapper

There is a utility function `addSchema` that has the following schema signature which can be obtained by simply using `tostring(addSchema)`:

```ts
addSchema (
  name: String,
  inputs: Array<(String, Type)>,
  outputs: Array<(String, Type)>,
  fn: Function
): (
  fn: Function
)
```

The `addSchema` function typechecks itself using the following lua code.

```lua
addSchema = assert(addSchema(
  "addSchema",
  {
    {"name", String},
    {"inputs", Array({String,Type})},
    {"outputs", Array({String,Type})},
    {"fn", Function}
  },
  Function,
  addSchema
))
```

## Custom Types

This system is designed to allow for custom types to be implemented outside
itself.  All you have to do is follow the same interface as the built-in types
and they will interoperate.

The types themselves are tables with `__tostring` and `__call` metamethods (much
like the schema checked functions returned by `addSchema`.)  This internal
interface is still under design and may change.  You can create custom types,
but you'll likely have to update them in the near future.  Once the type
interface is solid, it will be documented here with examples of creating custom
types.
