
## gem tasks ##

NAME = \
  $(shell ruby -e "s = eval(File.read(Dir['*.gemspec'][0])); puts s.name")
VERSION = \
  $(shell ruby -e "s = eval(File.read(Dir['*.gemspec'][0])); puts s.version")

count_lines:
	find lib -name "*.rb" | xargs cat | ruby -e "p STDIN.readlines.count { |l| l = l.strip; l[0, 1] != '#' && l != '' }"
cl: count_lines

gemspec_validate:
	@echo "---"
	ruby -e "s = eval(File.read(Dir['*.gemspec'].first)); s.validate"
	@echo "---"

name: gemspec_validate
	@echo "$(NAME) $(VERSION)"

build: gemspec_validate
	gem build $(NAME).gemspec
	mkdir -p pkg
	mv $(NAME)-$(VERSION).gem pkg/

push: build
	gem push pkg/$(NAME)-$(VERSION).gem


## flor tasks ##

RUBY=bundle exec ruby
FLOR_ENV?=dev
TO?=nil
FROM?=nil

migrate:
	$(RUBY) -Ilib -e "require 'flor/unit'; Flor::Unit.new('envs/$(FLOR_ENV)/etc/conf.json').storage.migrate($(TO), $(FROM))"

start:
	$(RUBY) -Ilib -e "require 'flor/unit'; Flor::Unit.new('envs/$(FLOR_ENV)/etc/conf.json').start.join"
s: start


## misc tasks ##

backup_notes_and_todos:
	tar czvf flor_notes_$(shell date "+%Y%m%d_%H%M").tgz .notes.md .todo.md && mv flor_notes_*.tgz ~/Dropbox/backup/
ba: backup_notes_and_todos

t:
	tree spec/unit/loader

mk:
	# testing lib/flor/tools/env.rb
	$(RUBY) -Ilib -e "require 'flor/tools/env'; Flor::Tools::Env.make('tmp', '$(FLOR_ENV)', gitkeep: true)"

doc:
	$(RUBY) -Imak -r 'doc' -e "make_procedures_doc()"

repl:
	$(RUBY) -Ilib -r 'flor/tools/repl' -e 'Flor::Tools::Repl.new("$(FLOR_ENV)")'
r: repl

.PHONY: doc repl

