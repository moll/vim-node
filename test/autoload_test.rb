require_relative "./helper"
require "json"

describe "Autoloaded" do
  include WithTemporaryDirectory

  before do
    FileUtils.touch File.join(@dir, "package.json")
  end

  describe "Goto file" do
    it "must open README.txt as is" do
      touch File.join(@dir, "index.js"), %(// Please read README.txt)
      touch File.join(@dir, "README.txt")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$gf"
      $vim.echo(%(bufname("%"))).must_equal File.join(@dir, "README.txt")
    end

    it "must open ./README.txt relative to file" do
      touch File.join(@dir, "foo", "index.js"), %(// Please read ./README.txt)
      touch File.join(@dir, "foo", "README.txt")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "$gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "foo", "README.txt")
    end

    it "must open ../README.txt" do
      touch File.join(@dir, "foo", "index.js"), %(// Please read ../README.txt)
      touch File.join(@dir, "README.txt")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "$gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "README.txt")
    end

    it "must open /.../README.txt" do
      touch File.join(@dir, "foo", "index.js"), %(// Read #{@dir}/README.txt)
      touch File.join(@dir, "README.txt")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "$gf"
      $vim.echo(%(bufname("%"))).must_equal File.join(@dir, "README.txt")
    end

    it "must open ./other.js given ./other" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must open ./other.js relative to file" do
      touch File.join(@dir, "foo", "index.js"), %(require("./other")) 
      touch File.join(@dir, "foo", "other.js")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "foo", "other.js")
    end

    it "must open ./package.json given ./package" do
      touch File.join(@dir, "index.js"), %(require("./package")) 
      touch File.join(@dir, "package.json")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "package.json")
    end

    it "must open ../other.js given ../other" do
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "lib/index.js"), %(require("../other")) 

      $vim.edit File.join(@dir, "lib/index.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must open /.../other.js given /.../other" do
      touch File.join(@dir, "foo", "index.js"), %(require("#{@dir}/other")) 
      touch File.join(@dir, "other.js")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "f/gf"
      $vim.echo(%(bufname("%"))).must_equal File.join(@dir, "other.js")
    end

    it "must open ./index.js given ./" do
      touch File.join(@dir, "other.js"), %(require("./")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must open ./index.js given ." do
      touch File.join(@dir, "other.js"), %(require(".")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must open ../index.js given ../" do
      touch File.join(@dir, "foo", "other.js"), %(require("../")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "foo", "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must open ../index.js given .." do
      touch File.join(@dir, "foo", "other.js"), %(require("..")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "foo", "other.js")
      $vim.feedkeys "f.gf"

      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must open /.../index.js given /.../" do
      touch File.join(@dir, "foo", "index.js"), %(require("#{@dir}/")) 
      touch File.join(@dir, "index.js")

      $vim.edit File.join(@dir, "foo", "index.js")
      $vim.feedkeys "f/gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "index.js")
    end

    it "must not open ./index/index.js given ." do
      touch File.join(@dir, "other.js"), %(require(".")) 
      touch File.join(@dir, "index", "index.js")

      $vim.edit File.join(@dir, "other.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "f.gf"

      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal %(E447: Can't find file "." in path)
    end

    it "must open ./lib/index.js given ./lib" do
      touch File.join(@dir, "index.js"), %(require("./lib")) 
      touch File.join(@dir, "lib", "index.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "lib", "index.js")
    end

    it "must open ./lib/other.js given ./lib with package.json" do
      touch File.join(@dir, "index.js"), %(require("./lib")) 
      touch File.join(@dir, "lib", "other.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "other")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "lib", "other.js")
    end

    it "must not open ./.js given ./" do
      touch File.join(@dir, "other.js"), %(require("./")) 
      touch File.join(@dir, ".js")

      $vim.edit File.join(@dir, "other.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "f.gf"
      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal %(E447: Can't find file "./" in path)
    end

    it "must open ./lib/index.js if package.json's main is empty" do
      touch File.join(@dir, "index.js"), %(require("./lib")) 
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "lib", "index.js")
    end

    it "must open ./lib/index.js if package.json's main file does not exist" do
      touch File.join(@dir, "index.js"), %(require("./lib")) 
      touch File.join(@dir, "lib", "index.js")
      touch File.join(@dir, "lib", "package.json"), JSON.dump(:main => "new")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "lib", "index.js")
    end

    it "must open ./other.js when as file & directory" do
      touch File.join(@dir, "index.js"), %(require("./other")) 
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must open ./lib/other.js when as file & directory given package.json" do
      touch File.join(@dir, "index.js"), %(require(".")) 
      touch File.join(@dir, "package.json"), JSON.dump(:main => "other")
      touch File.join(@dir, "other.js")
      touch File.join(@dir, "other", "index.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "f.gf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(@dir, "other.js")
    end

    it "must open ./node_modules/foo/index.js given foo" do
      touch File.join(@dir, "index.js"), %(require("foo")) 
      index = File.join(@dir, "node_modules", "foo", "index.js")
      touch index

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal index
    end

    it "must open ./node_modules/foo/other.js given foo/other" do
      touch File.join(@dir, "index.js"), %(require("foo/other")) 
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal other
    end

    it "must open ./node_modules/foo/other.js given foo/other.js" do
      touch File.join(@dir, "index.js"), %(require("foo/other.js")) 
      other = File.join(@dir, "node_modules", "foo", "other.js")
      touch other

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      $vim.echo(%(bufname("%"))).must_equal other
    end

    # When package.json refers to a regular file.
    it "must open ./node_modules/foo/other.js given main as other.js" do
      touch File.join(@dir, "index.js"), %(require("foo")) 

      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./other.js")
      touch File.join(mod, "other.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(mod, "other.js")
    end

    # When package.json refers to a directory.
    it "must open ./node_modules/foo/lib/index.js given main as ./lib" do
      touch File.join(@dir, "index.js"), %(require("foo")) 

      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "./lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(mod, "lib/index.js")
    end

    it "must open ./node_modules/foo/lib/index.js given main as lib" do
      touch File.join(@dir, "index.js"), %(require("foo")) 

      mod = File.join(@dir, "node_modules", "foo")
      touch File.join(mod, "package.json"), JSON.dump(:main => "lib")
      touch File.join(mod, "lib/index.js")

      $vim.edit File.join(@dir, "index.js")
      $vim.feedkeys "$hhgf"
      bufname = File.realpath($vim.echo(%(bufname("%"))))
      bufname.must_equal File.join(mod, "lib/index.js")
    end

    it "must show error when opening a non-existent file" do
      touch File.join(@dir, "index.js"), %(require("new"))

      $vim.edit File.join(@dir, "index.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "$hhgf"

      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal %(E447: Can't find file "new" in path)
    end

    it "must not show an error when opening nothing" do
      touch File.join(@dir, "index.js"), %("")

      $vim.edit File.join(@dir, "index.js")
      $vim.command(%(let v:errmsg = ""))
      $vim.feedkeys "gf"

      error = $vim.command("let v:errmsg").sub(/^\S+\s*/, "")
      error.must_equal ""
    end
  end

  describe "Goto file with split" do
    it "must open file in a new split" do
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
    it "must open file in a new tab" do
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
end
