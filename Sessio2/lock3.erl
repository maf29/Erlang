-module(lock2).
-export([init/2]).
%%			Time
%start(MyId) ->
%    spawn(fun() -> init(MyId) end).

init(_, Nodes) ->
    %receive
     %   {peers, Nodes} ->
      %      open(Nodes);
       % stop ->
        %    ok
    %end.
    open(Nodes, 0).

open(Nodes, Time) ->
    receive
        {take, Master} ->	%   {take, Master, Ref}
            Refs = requests(Nodes, Time),
            wait(Nodes, Master, Refs, [], Time, Time); %wait(Nodes, Master, Refs, [], Ref);
        {request, From, Ref, SenderTime} ->
            CurrentTime = calculate_time(Time, SenderTime),
            From ! {ok, Ref, CurrentTime},
            open(Nodes, CurrentTime);
        stop ->
            ok
    end.

requests(Nodes, Time) ->
    lists:map(
      fun(P) -> 
        R = make_ref(), 
        P ! {request, self(), R, Time}, 
        R 
      end, 
      Nodes).

wait(Id, Nodes, Master, [], Waiting, TakeRef) ->
    Master ! {taken, TakeRef},
    held(Id, Nodes, Waiting);
    
wait(Nodes, Master, Refs, Waiting, Time, RequestSentTime) ->
    receive
        {request, From, Ref, SenderTime} ->
            CurrentTime = calculate_time(Time, SenderTime),
            if
            	SenderTime < RequestSentTime ->
            		From ! {ok, Ref, CurrentTime},
            		Refs2 = requests([From], CurrentTime),
          		wait(Nodes, Master, lists:merge(Refs, Refs2), Waiting, CurrentTime, RequestSentTime);
          	true ->	
          		wait(Nodes, Master, Refs, [{From, Ref}|Waiting], CurrentTime, RequestSentTime)	% wait(Nodes, Master, Refs, [{From, Ref}|Waiting], TakeRef);
             end.
        {ok, Ref} ->
            CurrentTime = calculate_time(Time, SenderTime),
            Refs2 = lists:delete(Ref, Refs),
            wait(Nodes, Master, Refs2, Waiting, CurrentTime, RequestSentTime);	% wait(Nodes, Master, NewRefs, Waiting, TakeRef);
        release ->
            ok(Waiting, Time),            
            open(Nodes, Time)
    end.

ok(Waiting, Time) ->
    lists:map(
      fun({F,R}) -> 
        F ! {ok, R, Time} 
      end, 
      Waiting).

held(Nodes, Waiting, Time) ->
    receive
        {request, From, Ref, SenderTime} ->
            CurrentTime = calculate_time(Time, SenderTime),
            held(Nodes, [{From, Ref}|Waiting], CurrentTime);
        release ->
            ok(Waiting, Time),
            open(Nodes, Time)
    end.
    
calculate_time(Time, SenderTime) -> lists:max([Time, SenderTime]) + 1.
