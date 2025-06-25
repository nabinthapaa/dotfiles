return {
  "folke/noice.nvim",
  opts = {
    routes = {
      {
        filter = {
          any = {
            { event = "notify", kind = "warn",     find = "didOrganizeImports" },
            { event = "notify", kind = "msg_show", find = "%dL, %dB" }
          }
        },
        opts = { skip = true }
      }
    }
  }
}
