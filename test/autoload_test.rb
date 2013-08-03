require_relative "./helper"
require "json"

describe "Autoloaded" do
  include WithTemporaryDirectory

  before do
    FileUtils.touch File.join(@dir, "package.json")
  end

  describe "Goto file" do
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

    it "must open non-JavaScript files as is" do
      touch File.join(@dir, "index.js"), %(// Please read README.txt)
      touch File.join(@dir, "README.txt")

      $vim.edit File.join(@dir, "index.js")
      $vim.normal "$gf"
      $vim.echo(%(bufname("%"))).must_equal File.join(@dir, "README.txt")
    end
  end

  describe "Include file search pattern" do
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
