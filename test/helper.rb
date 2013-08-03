require "minitest/autorun"
require "minitest/reporters"
require "vimrunner"
require "tempfile"

MiniTest::Unit::TestCase.define_singleton_method(:test_order) do :alpha end
MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

vimrc = File.expand_path("../vimrc", __FILE__)
$vim = Vimrunner::Server.new(:vimrc => vimrc).start
Minitest::Unit.after_tests { $vim.kill }
