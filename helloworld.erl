-module(helloworld). 
-export([start/0]). 

start() -> 
  Pid = spawn(io, format, ["hola mundo!"]),
  io:fwrite("~w", [Pid]),
  io:format("~n").
