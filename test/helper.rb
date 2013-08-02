require "minitest/autorun"
require "vimrunner"
require "tempfile"

vimrc = File.expand_path("../vimrc", __FILE__)
$vim = Vimrunner::Server.new(:vimrc => vimrc).start
$vim.source Vimrunner::Server::VIMRUNNER_RC

Minitest.after_run { $vim.kill }
