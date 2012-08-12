-module(msgpack_rpc_test).

-include_lib("eunit/include/eunit.hrl").

-export([hello/1, add/2]).

hello(_Argv)->
    <<"hello">>.

add(A, B)-> A+B.
    

start_stop_test()->
    ok = application:start(cowboy),
    {ok, _} = cowboy:start_listener(testlistener, 3,
				    cowboy_tcp_transport, [{port, 9199}],
				    msgpack_rpc_protocol, [{module, msgpack_rpc_test}]),

    {ok, Pid} = msgpack_rpc_client:connect(tcp, "localhost", 9199, []),
    Reply = msgpack_rpc_client:call(Pid, hello, [<<"hello">>]),
    ?assertEqual({ok, <<"hello">>}, Reply),

    R = msgpack_rpc_client:call(Pid, add, [12, 23]),
    ?assertEqual({ok, 35}, R),

    ok = msgpack_rpc_client:notify(Pid, hello, [23]),

    {ok, CallID0} = msgpack_rpc_client:call_async(Pid, add, [-23, 23]),
    ?assertEqual({ok, 0}, msgpack_rpc_client:join(Pid, CallID0)),

    {ok, CallID1} = msgpack_rpc_client:call_async(Pid, add, [-23, 46]),
    ?assertEqual({ok, 23}, msgpack_rpc_client:join(Pid, CallID1)),

    % wrong arity, wrong function
    {error, undef} = msgpack_rpc_client:call(Pid, add, [-23]),
    {error, undef} = msgpack_rpc_client:call(Pid, imaginary, []),

    ok = msgpack_rpc_client:close(Pid),

    ok = cowboy:stop_listener(testlistener),
    ok = application:stop(cowboy).
