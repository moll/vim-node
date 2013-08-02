require_relative "./helper"

describe "Plugin" do
  describe "b:node_root" do
    must_set_node_root = lambda do |dir|
      $vim.edit "index.js"
      # Mac has the temporary directory symlinked, so need File.realpath.
      $vim.echo("b:node_root").must_equal File.realpath(dir)
    end

    it "must be set when in same directory with package.json" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")
        $vim.command("cd #{dir}")
        must_set_node_root.call dir
      end
    end

    it "must be set when in same directory with node_modules" do
      Dir.mktmpdir do |dir|
        Dir.mkdir File.join(dir, "node_modules")
        $vim.command("cd #{dir}")
        must_set_node_root.call dir
      end
    end

    it "must be set when ancestor directory has package.json" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")

        nested = File.join(dir, "lib", "awesomeness")
        FileUtils.mkdir_p nested
        $vim.command("cd #{nested}")
        must_set_node_root.call dir
      end
    end

    it "must be set when ancestor directory has node_modules" do
      Dir.mktmpdir do |dir|
        Dir.mkdir File.join(dir, "node_modules")

        nested = File.join(dir, "lib", "awesomeness")
        FileUtils.mkdir_p nested
        $vim.command("cd #{nested}")
        must_set_node_root.call dir
      end
    end

    it "must detect Node root also for other filetypes" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")

        $vim.command("cd #{dir}")
        $vim.edit "README.txt"
        $vim.echo("b:node_root").must_equal File.realpath(dir)
      end
    end
  end
end
