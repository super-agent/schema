return {
  name = "super-agent/schema",
  version = "0.0.1",
  description = "This library allows you to decorate public API functions with strict runtime typechecking. You can declare the types using a clear declarative syntax using actual type object references (to enable extensibility).",
  luvi = {
    version = "2.6.1",
    flavor = "regular",
  },
  homepage = "https://github.com/super-agent/schema",
  files = {
    "**.lua",
    "platform.api",
  },
  dependencies = {
    "luvit/pretty-print",
  }
}
