NAME := node
VERSION := 0.1.1
ID := 4674

love:
	@echo "Feel like makin' love."

pack:
	rm -rf "$(NAME)-$(VERSION).zip" 
	zip -r "$(NAME)-$(VERSION).zip" * -x Makefile -x "*.zip" -x "./test/*"

publish:
	open "http://www.vim.org/scripts/add_script_version.php?script_id=$(ID)"

tag:
	git tag "v$(VERSION)"
	
.PHONY: love pack publish tag
