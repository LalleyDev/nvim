return {

}
--local netbeans_path = "/YOUR/PATH/TO/netbeans/java/nbcode/bin/nbcode"

--vim.api.nvim_create_autocmd('FileType', {
--    pattern = 'java',
--    callback = function()
--        vim.lsp.start({
--            name = 'netbeans-binary-lsp',
--            cmd = { netbeans_path, "--start-java-language-server" },
--            root_dir = vim.fs.dirname(vim.fs.find({'pom.xml', 'build.gradle', '.git'}, { upward = true })[1]),
--            -- NetBeans often works better with stdio for Neovim
--            -- No extra arguments usually needed, but --listen:port is an option if stdio fails
--        })
--    end,
--})
