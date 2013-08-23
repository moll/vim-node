NAME := node
TITLE := Node.vim
VERSION := 0.6.0
ID := 4674

love:
	@echo "Feel like makin' love."

test: $(shell find . -name "*_test.rb")
	@ruby -rbundler/setup $(addprefix -r./,$^) -e "" -- $(TEST_OPTS)

autotest:
	@bundle exec guard start --no-interactions

pack:
	rm -rf "$(NAME)-$(VERSION).zip" 
	zip -r "$(NAME)-$(VERSION).zip" * -x @.packignore

publish:
	open "http://www.vim.org/scripts/add_script_version.php?script_id=$(ID)"

tag:
	git tag "v$(VERSION)"
	
.PHONY: love test autotest pack publish tag
