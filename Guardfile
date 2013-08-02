guard :minitest, :all_on_start => false do
  watch(%r(^(.*)\.vim)) {|m| [
    "test/#{m[1]}_test.rb",
    "test/#{m[1].sub(/\/\w+$/, "")}_test.rb"
  ]}

  watch(%r(^test/(.*)\/?_test\.rb))
  watch(%r(^test/helper\.rb)) { "test" }
end
