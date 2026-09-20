-- Java support through nvim-jdtls and the Eclipse JDT language server.
-- The server itself is installed by Mason; this plugin provides the Java-specific
-- start/attach workflow and the extra refactoring commands.

vim.pack.add { 'https://codeberg.org/mfussenegger/nvim-jdtls.git' }

local jdtls = require 'jdtls'
local jdtls_setup = require 'jdtls.setup'

local root_markers = {
  'gradlew',
  'mvnw',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
  'settings.gradle',
  'settings.gradle.kts',
  '.git',
}

local function start_jdtls(bufnr)
  local root_dir = jdtls_setup.find_root(root_markers, vim.api.nvim_buf_get_name(bufnr)) or vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(root_dir, ':t')
  local workspace_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'jdtls', project_name)
  local jdtls_cmd = vim.fn.exepath 'jdtls'

  if jdtls_cmd == '' then
    jdtls_cmd = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'bin', 'jdtls')
  end

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'Java: ' .. desc })
  end

  local config = {
    cmd = { jdtls_cmd, '-data', workspace_dir },
    root_dir = root_dir,
    capabilities = require('blink.cmp').get_lsp_capabilities(),
    settings = {
      java = {
        eclipse = { downloadSources = true },
        maven = { downloadSources = true },
        references = { includeDecompiledSources = true },
        implementationsCodeLens = { enabled = true },
        referencesCodeLens = { enabled = true },
        signatureHelp = { enabled = true },
        configuration = { updateBuildConfiguration = 'interactive' },
        completion = {
          favoriteStaticMembers = {
            'org.junit.Assert.*',
            'org.junit.Assume.*',
            'org.junit.jupiter.api.Assertions.*',
            'org.mockito.Mockito.*',
          },
          importOrder = { 'java', 'javax', 'org', 'com' },
        },
      },
    },
    init_options = { bundles = {} },
    on_attach = function()
      map('n', '<leader>jo', jdtls.organize_imports, 'Organize imports')
      map('n', '<leader>jc', function() jdtls.compile 'full' end, 'Compile project')
      map('n', 'crv', jdtls.extract_variable, 'Extract variable')
      map('v', 'crv', function() jdtls.extract_variable(true) end, 'Extract variable')
      map('n', 'crc', jdtls.extract_constant, 'Extract constant')
      map('v', 'crc', function() jdtls.extract_constant(true) end, 'Extract constant')
      map('v', 'crm', function() jdtls.extract_method(true) end, 'Extract method')
    end,
  }

  jdtls.start_or_attach(config, nil, { bufnr = bufnr })
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-jdtls', { clear = true }),
  pattern = 'java',
  callback = function(args) start_jdtls(args.buf) end,
})
