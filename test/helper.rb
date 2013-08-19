require "minitest/autorun"
require "vimrunner"
require "fileutils"
require "tempfile"

MiniTest::Unit::TestCase.define_singleton_method(:test_order) do :alpha end

begin
  require "minitest/reporters"
  MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new
rescue LoadError
end

$vimrc = File.expand_path("../vimrc", __FILE__)
$vim = Vimrunner::Server.new(:vimrc => $vimrc).start
Minitest::Unit.after_tests { $vim.kill }

module WithTemporaryDirectory
  def self.included(base)
    require "tmpdir"
  end

  def setup
    super
    # Mac has the temporary directory symlinked, so need File.realpath to
    # match the paths that Vim returns.
    @dir = File.realpath(Dir.mktmpdir) 
  end

  def teardown
    FileUtils.remove_entry_secure @dir 
    super
  end
end

def touch(path, contents = nil)
  FileUtils.mkdir_p File.dirname(path)
  return FileUtils.touch(path) if contents.nil? || contents.empty?
  File.open(path, "w") {|f| f.write contents }
end
