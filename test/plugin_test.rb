require_relative "./helper"
require "json"

describe "Plugin" do
  before do
    # Mac has the temporary directory symlinked, so need File.realpath to
    # match the paths that Vim returns.
    @dir = File.realpath(Dir.mktmpdir)
  end

  after do
    FileUtils.remove_entry_secure @dir
  end

  def touch(path, contents = nil)
    FileUtils.mkdir_p File.dirname(path)
    return FileUtils.touch(path) if contents.nil? || contents.empty?
    File.open(path, "w") {|f| f.write contents }
  end

  describe "b:node_root" do
    it "must be set when in same directory with package.json" do
      FileUtils.touch File.join(@dir, "package.json")
      $vim.edit File.join(@dir, "index.js")
      $vim.echo("b:node_root").must_equal @dir
    end

    it "must be set when in same directory with node_modules" do
      Dir.mkdir File.join(@dir, "node_modules")
      $vim.edit File.join(@dir, "index.js")
      $vim.echo("b:node_root").must_equal @dir
    end

    it "must be set when ancestor directory has package.json" do
      FileUtils.touch File.join(@dir, "package.json")

      nested = File.join(@dir, "lib", "awesomeness")
      FileUtils.mkdir_p nested
      $vim.edit File.join(nested, "index.js")
      $vim.echo("b:node_root").must_equal @dir
    end

    it "must be set when ancestor directory has node_modules" do
      Dir.mkdir File.join(@dir, "node_modules")

      nested = File.join(@dir, "lib", "awesomeness")
      FileUtils.mkdir_p nested
      $vim.edit File.join(nested, "index.js")
      $vim.echo("b:node_root").must_equal @dir
    end

    it "must be set also for other filetypes" do
      FileUtils.touch File.join(@dir, "package.json")

      $vim.edit File.join(@dir, "README.txt")
      $vim.echo("b:node_root").must_equal @dir
    end

    it "must be set in nested Node projects" do
      nested = File.join(@dir, "node_modules", "require-guard")
      FileUtils.mkdir_p nested
      FileUtils.touch File.join(nested, "package.json")

      test = File.join(nested, "test")
      FileUtils.mkdir_p test
      $vim.edit File.join(test, "index_test.js")
      $vim.echo("b:node_root").must_equal nested
    end

    it "must not be set when no ancestor has one" do
      $vim.edit File.join(@dir, "index_test.js")
      $vim.echo(%(exists("b:node_root"))).must_equal "0"
    end

    it "must be set from file, not working directory" do
      $vim.command "cd #{@dir}"
      FileUtils.touch File.join(@dir, "package.json")

      nested = File.join(@dir, "node_modules", "require-guard")
      FileUtils.mkdir_p nested
      FileUtils.touch File.join(nested, "package.json")

      $vim.edit File.join(nested, "index_test.js")
      $vim.echo("b:node_root").must_equal nested
    end
  end

  describe "Goto file" do
    before do
      FileUtils.touch File.join(@dir, "package.json")
    end

    it "must open ./other.js given ./other" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.normal "f.gf"

      bufname = $vim.echo(%(bufname("%")))
      File.realpath(bufname).must_equal File.join(@dir, "other.js")
    end

    it "must open ./package.json given ./package" do
      touch File.join(@dir, "index.js"), %(require("./package")) 
      touch File.join(@dir, "package.json")

      $vim.edit File.join(@dir, "index.js")
      $vim.normal "f.gf"

      bufname = $vim.echo(%(bufname("%")))
      File.realpath(bufname).must_equal File.join(@dir, "package.json")
    end

    it "must open ./index.js given ../index" do
      touch File.join(@dir, "index.js")
      touch File.join(@dir, "lib/requires.js"), %(require("../index")) 

      $vim.edit File.join(@dir, "lib/requires.js")
      $vim.normal "f.gf"

      bufname = $vim.echo(%(bufname("%")))
      File.realpath(bufname).must_equal File.join(@dir, "index.js")
    end

    it "must open ./node_modules/foo/index.js given foo" do
      touch File.join(@dir, "requires.js"), %(require("foo")) 
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index

      $vim.edit File.join(@dir, "requires.js")
      $vim.normal "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal index
    end

    it "must open ./node_modules/foo/other.js given foo/other" do
      touch File.join(@dir, "requires.js"), %(require("foo/other")) 
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other

      $vim.edit File.join(@dir, "requires.js")
      $vim.normal "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal other
    end

    it "must open ./node_modules/foo/other.js given foo/other.js" do
      touch File.join(@dir, "requires.js"), %(require("foo/other.js")) 
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other

      $vim.edit File.join(@dir, "requires.js")
      $vim.normal "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal other
    end

    # When package.json refers to a regular file.
    it "must open ./node_modules/foo/other.js given main as other.js" do
      touch File.join(@dir, "requires.js"), %(require("foo")) 

      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./other.js")

      other = File.join(mod, "other.js")
      touch other

      $vim.edit File.join(@dir, "requires.js")
      $vim.normal "$hhgf"
      File.realpath($vim.echo(%(bufname("%")))).must_equal other
    end

    # When package.json refers to a directory.
    it "must open ./node_modules/foo/lib/index.js given main as lib" do
      touch File.join(@dir, "requires.js"), %(require("foo")) 

      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./lib")

      other = File.join(mod, "lib/index.js")
      touch other

      $vim.edit File.join(@dir, "requires.js")
      $vim.normal "$hhgf"
      File.realpath($vim.echo(%(bufname("%")))).must_equal other
    end
  end

  describe "Include file search pattern" do
    before do
      FileUtils.touch File.join(@dir, "package.json")
    end

    it "must find matches given a require" do
      definition = %(module.exports = function awesome() { return 1337 })

      touch File.join(@dir, "index.js"), <<-end.gsub(/^\s+/, "")
        var awesome = require("foo")
        awesome()
      end
      touch File.join(@dir, "node_modules", "foo", "index.js"), definition

      $vim.edit File.join(@dir, "index.js")
      $vim.command("normal G[i").must_equal definition
    end
  end
end
