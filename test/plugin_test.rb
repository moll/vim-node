require_relative "./helper"
require "json"

describe "Plugin" do
  def touch(path, contents = nil)
    FileUtils.mkdir_p File.dirname(path)
    return FileUtils.touch(path) if contents.nil? || contents.empty?
    File.open(path, "w") {|f| f.write contents }
  end

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

        $vim.edit File.join(nested, "index_test.js")
        $vim.echo("b:node_root").must_equal nested
      end
    end
  end

  def project(&block)
    Dir.mktmpdir do |dir|
      FileUtils.touch File.join(dir, "package.json")
      # Mac has the temporary directory symlinked, so need File.realpath to
      # match the paths that Vim gives.
      Dir.chdir File.realpath(dir), &block
    end
  end

  describe "Goto file" do
    it "must open ./other.js given ./other" do
      project do |dir|
        touch "index.js", %(require("./other")) 
        other = File.join(dir, "other.js")
        touch other

        $vim.edit File.join(dir, "index.js")
        $vim.normal "f.gf"

        bufname = $vim.echo(%(bufname("%")))
        File.realpath(bufname).must_equal other
      end
    end

    it "must open ./package.json given ./package" do
      project do |dir|
        touch "index.js", %(require("./package")) 
        package = File.join(dir, "package.json")
        touch package

        $vim.edit File.join(dir, "index.js")
        $vim.normal "f.gf"

        bufname = $vim.echo(%(bufname("%")))
        File.realpath(bufname).must_equal package
      end
    end

    it "must open ./node_modules/foo/index.js given foo" do
      project do |dir|
        touch "requires.js", %(require("foo")) 
        index = File.join(dir, "node_modules", "foo", "index.js")
        touch index

        $vim.edit File.join(dir, "requires.js")
        $vim.normal "$hhgf"
        $vim.echo(%(bufname("%"))).must_equal index
      end
    end

    it "must open ./node_modules/foo/other.js given foo's package.json" do
      project do |dir|
        touch "requires.js", %(require("foo")) 

        mod = File.join(dir, "node_modules", "foo")
        other = File.join(mod, "other.js")
        touch other
        touch File.join(mod, "package.json"), JSON.dump(:main => "other.js")

        $vim.edit File.join(dir, "requires.js")
        $vim.normal "$hhgf"
        $vim.echo(%(bufname("%"))).must_equal other
      end
    end
  end
end
