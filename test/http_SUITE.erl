%% Copyright (c) 2018, Loïc Hoguin <essen@ninenines.eu>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(http_SUITE).
-compile(export_all).
-compile(nowarn_export_all).

-import(ct_helper, [config/2]).
-import(ct_helper, [doc/1]).
-import(cowboy_test, [gun_open/1]).

all() -> [{group, clear}].

groups() -> [{clear, [parallel], ct_helper:all(?MODULE)}].

init_routes(_) -> [
	{"localhost", [
		{"/", hello_h, []}
	]}
].

switch_protocol_flush(Config) ->
	doc("Confirm that switch_protocol does not flush unrelated messages."),
	ProtoOpts = #{
		env => #{dispatch => cowboy_router:compile(init_routes(Config))},
		stream_handlers => [switch_protocol_flush_h]
	},
	{ok, _} = cowboy:start_clear(switch_protocol_flush, [{port, 0}], ProtoOpts),
	Port = ranch:get_port(switch_protocol_flush),
	Self = self(),
	ConnPid = gun_open([{port, Port}, {type, tcp}, {protocol, http}|Config]),
	_ = gun:get(ConnPid, "/", [
		{<<"x-test-pid">>, pid_to_list(Self)}
	]),
	receive
		{Self, Events} ->
			switch_protocol_flush_h:validate(Events)
	end.
