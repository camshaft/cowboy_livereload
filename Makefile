PROJECT = cowboy_livereload

# dependencies

DEPS = privdir fast_key jsxn jsx

dep_privdir = git https://github.com/camshaft/privdir
dep_fast_key = git https://github.com/camshaft/fast_key
dep_jsx = git https://github.com/talentdeficit/jsx
dep_jsxn = git https://github.com/talentdeficit/jsxn

include erlang.mk

repl: all bin/start
	@bin/start cowboy_livereload

bin/start:
	@mkdir -p bin
	@curl https://gist.githubusercontent.com/camshaft/372cc332241ac95ae335/raw/start -o $@
	@chmod a+x $@

.PHONY: repl
