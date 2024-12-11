-module(erlbook).

-export([module/1]).
-ifdef(EUNIT).
-include_lib("eunit/include/eunit.hrl").
-endif.

module(String) ->
    Forms = scan(String ++ eof, []),
    case compile(Forms) of
        {ok, Module, Bin} ->
            case load(Module, Bin) of
                {module, Module} ->
                    {module, Module, Bin, {}};
                {error, Error} ->
                    erlang:error({badarg, Error})
            end;
        {error, Error} ->
            erlang:error({badarg, Error})
    end.

scan(eof, Acc) ->
    lists:reverse(Acc);
scan({done, Result, LeftOverChars}, Acc) ->
    scan_done(Result, LeftOverChars, Acc);
scan({more, Continuation}, Acc) ->
    scan(erl_scan:tokens(Continuation, [], 1), Acc);
scan(String, Acc) when is_list(String) ->
    scan(erl_scan:tokens([], String, 1), Acc).

scan_done({error, ErrorMsg, _Location}, _LeftOverChars, _Acc) ->
    erlang:error({badarg, ErrorMsg});
scan_done({eof, _Location}, _LeftOverChars, Acc) ->
    Acc;
scan_done({ok, Tokens, _Location}, LeftOverChars, Acc) ->
    case erl_parse:parse_form(Tokens) of
        {ok, Form} ->
            scan(LeftOverChars, [Form|Acc]);
        {error, R} ->
            scan(LeftOverChars, R)
    end.

compile(Forms) ->
    compile:forms(Forms, [return_errors, debug_info]).

load(Module, Bin) ->
    code:load_binary(Module, "nofile", Bin).

-ifdef(EUNIT).
module_test() ->
    {module, demo, _, _} = module("-module(demo).\n-export([go/0]).\ngo() -> 42.\n"),
    42 = demo:go().
-endif.

