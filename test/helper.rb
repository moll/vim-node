require "minitest/autorun"
require "vimrunner"
require "tempfile"

vimrc = File.expand_path("../vimrc", __FILE__)
$vim = Vimrunner::Server.new(:vimrc => vimrc).start
Minitest.after_run { $vim.kill }
