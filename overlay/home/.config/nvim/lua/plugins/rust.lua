-- LazyVim extras.lang.rust already loads rustaceanvim + crates.nvim.
-- Match neuronvim: rust-analyzer must ignore devenv/.direnv and target.
return {
  {
    "mrcjkb/rustaceanvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.server = opts.server or {}
      opts.server.default_settings = opts.server.default_settings or {}
      local ra = opts.server.default_settings["rust-analyzer"] or {}
      ra.files = ra.files or {}
      local dirs = ra.files.excludeDirs or {}
      for _, dir in ipairs({ "./target", "./.direnv", "target", ".direnv" }) do
        if not vim.tbl_contains(dirs, dir) then
          table.insert(dirs, dir)
        end
      end
      ra.files.excludeDirs = dirs
      opts.server.default_settings["rust-analyzer"] = ra
      return opts
    end,
  },
}
