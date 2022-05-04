-module(lock2).
-export([init/2]).
%%			ID
%start(MyId) ->
%    spawn(fun() -> init(MyId) end).

init(Id, Nodes) ->
    %receive
     %   {peers, Nodes} ->
      %      open(Nodes);
       % stop ->
        %    ok
    %end.
    open(Id, Nodes).

open(Id, Nodes) ->
    receive
        {take, Master} ->	%   {take, Master, Ref}
            Refs = requests(Id, Nodes),
            wait(Id, Nodes, Master, Refs, []); %wait(Nodes, Master, Refs, [], Ref);
        {request, From, _, Ref} ->
            From ! {ok, Ref},
            open(Id, Nodes);
        stop ->
            ok
    end.

requests(Id, Nodes) ->
    lists:map(
      fun(P) -> 
        R = make_ref(), 
        P ! {request, self(), Id, R}, 
        R 
      end, 
      Nodes).

wait(Id, Nodes, Master, [], Waiting, TakeRef) ->
    Master ! {taken, TakeRef},
    held(Id, Nodes, Waiting);
    
wait(Id, Nodes, Master, Refs, Waiting, TakeRef) ->
    receive
        {request, From, Ref} ->
            if
            	FromId < Id ->
            		From ! {ok, Ref},
            		Refs2 = requests(Id, [From]),
          		wait(Id, Nodes, Master, lists:merge(Refs, Refs2), Waiting);
          	true ->	
          		wait(Id, Nodes, Master, Refs, [{From, Ref}|Waiting])	% wait(Nodes, Master, Refs, [{From, Ref}|Waiting], TakeRef);
            end.
        {ok, Ref} ->
            Refs2 = lists:delete(Ref, Refs),
            wait(Id, Nodes, Master, Refs2, Waiting);	% wait(Nodes, Master, NewRefs, Waiting, TakeRef);
        release ->
            ok(Waiting),            
            open(Id, Nodes)
    end.

ok(Waiting) ->
    lists:map(
      fun({F,R}) -> 
        F ! {ok, R} 
      end, 
      Waiting).

held(Id, Nodes, Waiting) ->
    receive
        {request, From, _, Ref} ->
            held(Id, Nodes, [{From, Ref}|Waiting]);
        release ->
            ok(Waiting),
            open(Id, Nodes)
    end.
