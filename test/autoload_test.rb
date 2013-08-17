require_relative "./helper"
require "json"

describe "Autoloaded" do
  include WithTemporaryDirectory

  before do
    FileUtils.touch File.join(@dir, "package.json")
  end

  describe "Autocommand" do
    it "must fire user autcommand \"Node\"" do
      $vim.command "au User Node let node_autocommand = 1337"
      $vim.edit File.join(@dir, "other.js")
      $vim.echo(%(g:node_autocommand)).must_equal "1337"
    end
  end

  describe "node#find" do
    def find(path)
      File.realpath($vim.echo(%(node#find("#{path}"))))
    end

    it "must return ./README before ./README.js" do
      touch File.join(@dir, "README")
      touch File.join(@dir, "README.js")

      $vim.edit File.join(@dir, "index.js")
      find("./README").must_equal File.join(@dir, "README")
    end

    it "must return ./README.txt relative to file" do
      touch File.join(@dir, "lib", "README.txt")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("./README.txt").must_equal File.join(@dir, "lib", "README.txt")
    end

    it "must return ../README.txt" do
      touch File.join(@dir, "README.txt")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("../README.txt").must_equal File.join(@dir, "README.txt")
    end

    it "must return /.../README.txt" do
      touch File.join(@dir, "README.txt")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/README.txt").must_equal File.join(@dir, "README.txt")
    end

    it "must return ./other.js given ./other" do
      touch File.join(@dir, "other.js")
      $vim.edit File.join(@dir, "index.js")
      find("./other").must_equal File.join(@dir, "other.js")
    end

    it "must return ./other.js given ./other relative to file" do
      touch File.join(@dir, "lib", "other.js")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("./other").must_equal File.join(@dir, "lib", "other.js")
    end

    it "must return ./other.js before ./other/index.js given ./other" do
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")
      $vim.edit File.join(@dir, "index.js")
      find("./other").must_equal File.join(@dir, "other.js")
    end

    it "must return ../other.js given ../other" do
      touch File.join(@dir, "other.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("../other").must_equal File.join(@dir, "other.js")
    end

    it "must return /.../other.js given /.../other" do
      touch File.join(@dir, "other.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/other").must_equal File.join(@dir, "other.js")
    end

    it "must return ./package.json given ./package" do
      touch File.join(@dir, "package.json")
      $vim.edit File.join(@dir, "index.js")
      find("./package").must_equal File.join(@dir, "package.json")
    end

    it "must return ./index.js given ." do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "other.js")
      find(".").must_equal File.join(@dir, "index.js")
    end

    it "must return ./index.js given ./" do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "other.js")
      find("./").must_equal File.join(@dir, "index.js")
    end

    it "must not find ./index/index.js given ./" do
      touch File.join(@dir, "index", "index.js")
      $vim.edit File.join(@dir, "other.js")
      $vim.echo(%(empty(node#find("./")))).must_equal "1"
    end

    it "must not find ./.js given ./" do
      touch File.join(@dir, ".js")
      $vim.edit File.join(@dir, "other.js")
      $vim.echo(%(empty(node#find("./")))).must_equal "1"
    end

    it "must return ../index.js given .." do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "other.js")
      find("..").must_equal File.join(@dir, "index.js")
    end

    it "must return ../index.js given ../" do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "other.js")
      find("../").must_equal File.join(@dir, "index.js")
    end

    it "must return /.../index.js given /..." do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir").must_equal File.join(@dir, "index.js")
    end

    it "must return /.../index.js given /.../" do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "index.js")
      find("#@dir/").must_equal File.join(@dir, "index.js")
    end

    it "must return ./lib/index.js given ./lib" do
      touch File.join(@dir, "lib", "index.js")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./lib/other.js given ./lib with main" do
      touch File.join(@dir, "lib", "other.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "other")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "other.js")
    end

    it "must return ./lib/index.js given ./lib with empty main" do
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./lib/index.js given ./lib with non-existent main" do
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "new")
      $vim.edit File.join(@dir, "index.js")
      find("./lib").must_equal File.join(@dir, "lib", "index.js")
    end

    it "must return ./other.js before ./other/index.js given . with main" do
      touch File.join(@dir, "package.json"), JSON.dump(:main => "other")
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")

      $vim.edit File.join(@dir, "index.js")
      find(".").must_equal File.join(@dir, "other.js")
    end

    it "must return node_modules/foo/index.js given foo" do
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index
      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal index
    end

    it "must return node_modules/foo/other.js given foo/other" do
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other
      $vim.edit File.join(@dir, "index.js")
      find("foo/other").must_equal other
    end

    it "must return node_modules/foo/other.js given foo/other.js" do
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other
      $vim.edit File.join(@dir, "index.js")
      find("foo/other.js").must_equal other
    end

    # When package.json refers to a regular file.
    it "must return node_modules/foo/other.js given foo with main" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./other.js")
      touch File.join(mod, "other.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "other.js")
    end

    # When package.json refers to a directory.
    it "must return node_modules/foo/lib/index.js given foo with main as ./lib" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "lib/index.js")
    end

    it "must return node_modules/foo/lib/index.js given foo with main as lib" do
      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      find("foo").must_equal File.join(mod, "lib/index.js")
    end

    it "must return empty when looking for nothing" do
      $vim.edit File.join(@dir, "index.js")
      $vim.echo(%(empty(node#find("")))).must_equal "1"
    end

    it "must return empty when nothing found" do
      $vim.edit File.join(@dir, "index.js")
      $vim.echo(%(empty(node#find("new")))).must_equal "1"
    end
  end

  describe "Goto file" do
    it "must not be available in non-JavaScript files" do
      $vim.edit File.join(@dir, "README")
      $vim.echo(%(hasmapto("<Plug>NodeGotoFile"))).must_equal "0"
    end

    it "must edit README.txt" do
      touch File.join(@dir, "index.js"), %(// Please read README.txt)
      touch File.join(@dir, "README.txt")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$gf"
      $vim.echo(%(bufname("%"))).must_equal File.join(@dir, "README.txt")
    end

    it "must edit ./README.txt relative to file" do
      touch File.join(@dir, "foo", "index.js"), %(// Please read ./README.txt)
      touch File.join(@dir, "foo", "README.txt")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "$gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "foo", "README.txt")
    end

    it "must edit README before README.js" do
      touch File.join(@dir, "index.js"), "// Please read README"
      touch File.join(@dir, "README")
      touch File.join(@dir, "README.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "README")
    end

    it "must open ./other.js relative to file" do
      touch File.join(@dir, "foo", "index.js"), %(require("./other")) 
      touch File.join(@dir, "foo", "other.js")
 
      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "f.gf"
 
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "foo", "other.js")
    end

    # This is the last failsafe to make sure our custom gf handler runs, because
    # default Vim opens the directory instead.
    it "must edit ./other.js before ./other/index.js given /other" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")
 
      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must edit ./index.js given ." do
      touch File.join(@dir, "other.js"), %(require(".")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit ./index.js given ./" do
      touch File.join(@dir, "other.js"), %(require("./")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit ../index.js given .." do
      touch File.join(@dir, "foo", "other.js"), %(require("..")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "foo", "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit ../index.js given ../" do
      touch File.join(@dir, "foo", "other.js"), %(require("../")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "foo", "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must open ./node_modules/foo/index.js given foo" do
      touch File.join(@dir, "index.js"), %(require("foo")) 
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index
 
      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal index
    end

    it "must not show an error when opening nothing" do
      touch File.join(@dir, "index.js"), %("")

      $vim.edit File.join(@dir, "index.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "gf"

      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal ""
    end

    it "must show error when opening a non-existent file" do
      touch File.join(@dir, "index.js"), %(require("new"))

      $vim.edit File.join(@dir, "index.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "$hhgf"

      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal %(E447: Can't find file "new" in path)
    end
  end

  describe "Goto file with split" do
    it "must edit file in a new split" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.\\<C-w>f"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
      $vim.echo(%(winnr("$"))).must_equal "2"
    end
  end

  describe "Goto file with tab" do
    it "must edit file in a new tab" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.\\<C-w>gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
      $vim.echo(%(tabpagenr("$"))).must_equal "2"
    end
  end

  describe "Include file search pattern" do
    it "must find matches given a require" do
      touch File.join(@dir, "index.js"), <<-end.gsub(/^\s+/, "")
        var awesome = require("foo")
        awesome()
      end

      definition = %(module.exports = function awesome() { return 1337 })
      touch File.join(@dir, "node_modules", "foo", "index.js"), definition

      $vim.edit File.join(@dir, "index.js")
      $vim.command("normal G[i").must_equal definition
    end

    it "must find matches given a relative require" do
      touch File.join(@dir, "index.js"), <<-end.gsub(/^\s+/, "")
        var awesome = require("./other")
        awesome()
      end

      definition = %(module.exports = function awesome() { return 1337 })
      touch File.join(@dir, "other.js"), definition

      $vim.edit File.join(@dir, "index.js")
      $vim.command("normal G[i").must_equal definition
    end

    it "must find matches given a relative require in another directory" do
      touch File.join(@dir, "foo", "index.js"), <<-end.gsub(/^\s+/, "")
        var awesome = require("./other")
        awesome()
      end

      definition = %(module.exports = function awesome() { return 1337 })
      touch File.join(@dir, "foo", "other.js"), definition

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.command("normal G[i").must_equal definition
    end
  end

  describe ":Nedit" do
    # NOTE: Test from a non-JavaScript file everywhere to make sure there are
    # no dependencies on JavaScript specific settings.
    FULL_COMMAND_MATCH = "2"

    it "must be available in non-JavaScript files" do
      $vim.edit File.join(@dir, "README.txt")
      $vim.echo("exists(':Nedit')").must_equal FULL_COMMAND_MATCH
    end

    it "must be available in JavaScript files" do
      $vim.edit File.join(@dir, "index.js")
      $vim.echo("exists(':Nedit')").must_equal FULL_COMMAND_MATCH
    end

    it "must edit /README.txt" do
      touch File.join(@dir, "README.txt")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit /README.txt"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "README.txt")
    end

    it "must edit /README.txt given ./README.txt" do
      touch File.join(@dir, "README.txt")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit ./README.txt"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "README.txt")
    end

    it "must edit /README.txt given ./README.txt relative to root" do
      touch File.join(@dir, "README.txt")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "CHANGELOG.txt")
      $vim.command "Nedit ./README.txt"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "README.txt")
    end

    it "must edit /other.js given /other" do
      touch File.join(@dir, "other.js")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit /other"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must edit /other.js given ./other relative to root" do
      touch File.join(@dir, "other.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "CHANGELOG.txt")
      $vim.command "Nedit ./other"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must edit /index.js given /" do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit /"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit /index.js given ." do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit ."
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit /index.js given . relative to root" do
      touch File.join(@dir, "index.js")
      Dir.mkdir File.join(@dir, "lib")
      $vim.edit File.join(@dir, "lib", "CHANGELOG.txt")
      $vim.command "Nedit ."
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit /index.js given ./" do
      touch File.join(@dir, "index.js")
      $vim.edit File.join(@dir, "CHANGELOG.txt")
      $vim.command "Nedit ./"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must edit /node_modules/foo/index.js given foo" do
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index

      $vim.edit File.join(@dir, "README.txt")
      $vim.command("Nedit foo")
      $vim.echo(%(bufname("%"))).must_equal index
    end
  end
end
