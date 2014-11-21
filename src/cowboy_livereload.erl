-module(cowboy_livereload).

-export([start_link/0]).
-export([reload/0]).
-export([reload/1]).
-export([alert/1]).

%% cowboy_handler
-export([init/3]).
%% Websocket
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).
%% HTTP
-export([handle/2]).
-export([terminate/3]).

%% gen_event
-export([init/1]).
-export([handle_event/2]).
-export([handle_call/2]).
-export([handle_info/2]).
-export([terminate/2]).

start_link() ->
  gen_event:start_link({local, ?MODULE}).

reload() ->
  gen_event:notify(?MODULE, {reload, <<>>}).
reload(File) ->
  gen_event:notify(?MODULE, {reload, File}).

alert(Message) ->
  gen_event:notify(?MODULE, {alert, Message}).

init(_TransportName, Req, Opts) ->
  case cowboy_req:header(<<"upgrade">>, Req) of
    {<<"websocket">>, _} ->
      {upgrade, protocol, cowboy_websocket};
    _ ->
      {ok, Req, Opts}
  end.

%% Websocket

-define(HELLO_RESPONSE, jsxn:encode(#{
  command => hello,
  serverName => cowboy_livereload,
  protocols => [
    <<"http://livereload.com/protocols/official-7">>
  ]
})).

-define(RELOAD(File), jsxn:encode(#{
  command => reload,
  path => File,
  liveCSS => true
})).

-define(ALERT(Message), jsxn:encode(#{
  command => alert,
  message => Message
})).

websocket_init(_TransportName, Req, Opts) ->
  {ok, Req, Opts}.

websocket_handle({text, <<"{", _/binary>> = Msg}, Req, Opts) ->
  websocket_handle(jsxn:decode(Msg), Req, Opts);
websocket_handle(#{<<"command">> := <<"hello">>}, Req, Opts) ->
  ok = gen_event:add_handler(?MODULE, {?MODULE, self()}, [self()]),
  io:format("LiveReload client connected~n"),
  {reply, {text, ?HELLO_RESPONSE}, Req, Opts};
websocket_handle(_Data, Req, Opts) ->
  {ok, Req, Opts}.

websocket_info({reload, File}, Req, Opts) ->
  {reply, {text, ?RELOAD(File)}, Req, Opts};
websocket_info({alert, Message}, Req, Opts) ->
  {reply, {text, ?ALERT(Message)}, Req, Opts};
websocket_info(_Info, Req, Opts) ->
  {ok, Req, Opts}.

websocket_terminate(_Reason, _Req, _Opts) ->
  gen_event:delete_handler(?MODULE, {?MODULE, self()}, [self()]),
  ok.

%% HTTP
handle(Req, Opts) ->
  Dir = fast_key:get(client, Opts, privdir:get(?MODULE) ++ "/client.js"),
  {ok, Client} = file:read_file(Dir),
  cowboy_req:reply(200, [{<<"content-type">>, <<"text/javascript">>}], Client, Req),
  {ok, Req, Opts}.

terminate(_Reason, _Req, _Opts) ->
  ok.

%% gen_event
init([Pid]) ->
  {ok, Pid}.

handle_event(Event, Pid) ->
  Pid ! Event,
  {ok, Pid}.

handle_call(_, Pid) ->
  {ok, undefined, Pid}.

handle_info(_, Pid) ->
  {ok, Pid}.

terminate(_, _) ->
  stop.
