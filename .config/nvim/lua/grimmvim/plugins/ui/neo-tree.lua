return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- アイコンのため
    "MunifTanjim/nui.nvim",
  },
  config = function()
    -- 特に設定がなければ、デフォルトのまま使う
    -- もしデフォルトのファイラー(NvimTree)を無効にしたい場合は、下のコメントを外してください
    -- vim.g.loaded_netrw = 1
    -- vim.g.loaded_netrwPlugin = 1

    require("neo-tree").setup({
      -- ウィンドウの右側に表示したい場合は 'right' に変更
      window = {
        position = "left",
        width = 30,
      },
      -- ディレクトリを開いたときの挙動など
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = true,
        },
      },
    })

    -- キーマップを設定
    vim.keymap.set("n", "<C-n>", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
  end,
}