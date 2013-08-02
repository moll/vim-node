require_relative "./helper"

describe "Plugin" do
  describe "b:node_root" do
    it "must be set when in same directory with package.json" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")
        $vim.edit File.join(dir, "index.js")
        $vim.echo("b:node_root").must_equal dir
      end
    end

    it "must be set when in same directory with node_modules" do
      Dir.mktmpdir do |dir|
        Dir.mkdir File.join(dir, "node_modules")
        $vim.edit File.join(dir, "index.js")
        $vim.echo("b:node_root").must_equal dir
      end
    end

    it "must be set when ancestor directory has package.json" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")

        nested = File.join(dir, "lib", "awesomeness")
        FileUtils.mkdir_p nested
        $vim.edit File.join(nested, "index.js")
        $vim.echo("b:node_root").must_equal dir
      end
    end

    it "must be set when ancestor directory has node_modules" do
      Dir.mktmpdir do |dir|
        Dir.mkdir File.join(dir, "node_modules")

        nested = File.join(dir, "lib", "awesomeness")
        FileUtils.mkdir_p nested
        $vim.edit File.join(nested, "index.js")
        $vim.echo("b:node_root").must_equal dir
      end
    end

    it "must be set also for other filetypes" do
      Dir.mktmpdir do |dir|
        FileUtils.touch File.join(dir, "package.json")

        $vim.edit File.join(dir, "README.txt")
        $vim.echo("b:node_root").must_equal dir
      end
    end

    it "must be set in nested Node projects" do
      Dir.mktmpdir do |dir|
        nested = File.join(dir, "node_modules", "require-guard")
        FileUtils.mkdir_p nested
        FileUtils.touch File.join(nested, "package.json")

        test = File.join(nested, "test")
        FileUtils.mkdir_p test
        $vim.edit File.join(test, "index_test.js")
        $vim.echo("b:node_root").must_equal nested
      end
    end

    it "must not be set when no ancestor has one" do
      Dir.mktmpdir do |dir|
        $vim.edit File.join(dir, "index_test.js")
        $vim.echo(%(exists("b:node_root"))).must_equal "0"
      end
    end

    it "must be set from file, not working directory" do
      Dir.mktmpdir do |dir|
        $vim.command "cd #{dir}"
        FileUtils.touch File.join(dir, "package.json")

        nested = File.join(dir, "node_modules", "require-guard")
        FileUtils.mkdir_p nested
        FileUtils.touch File.join(nested, "package.json")

        # Mac has the temporary directory symlinked, so need File.realpath.
        $vim.edit File.join(nested, "index_test.js")
        $vim.echo("b:node_root").must_equal nested
      end
    end
  end
end
