PROJECT = cowboy_livereload

# dependencies

DEPS = privdir fast_key jsxn jsx

dep_privdir = git https://github.com/camshaft/privdir
dep_fast_key = git https://github.com/camshaft/fast_key
dep_jsx = git https://github.com/camshaft/jsx develop
dep_jsxn = git https://github.com/talentdeficit/jsxn

include erlang.mk
