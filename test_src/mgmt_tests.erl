%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(mgmt_tests).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    ?debugMsg("Test system setup"),
    ?assertEqual(ok,setup()),

    %% Start application tests
    ?debugMsg("Start cluster_test"),
    ?assertEqual(ok,cluster_test:start()),
     ?debugMsg("Stop cluster_test"),
    
    ?debugMsg("Start stop_test_system:start"),
    %% End application tests
    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    ssh:start(),
    ?assertEqual(ok,application:start(common)),
    % start dbase
    rpc:call('10250@c0',init,stop,[]),  
    rpc:call('10250@c1',init,stop,[]), 
    rpc:call('10250@c2',init,stop,[]),  
    timer:sleep(2000),
    pang=net_adm:ping('10250@c1'),
    DbaseApp="dbase_application",
    GitUser="joq62",
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",60201,"joq62","festum01","rm -rf "++DbaseApp,5000)]),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",60201,"joq62","festum01","git clone https://github.com/"++GitUser++"/"++DbaseApp++".git",5000)]),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",60201,"joq62","festum01","make -C "++DbaseApp,5000)]),
    {pong,'10250@c1',dbase_application}=rpc:call('10250@c1',dbase_application,ping,[]), 
    io:format("~p~n",[rpc:call('10250@c1',dbase_application,services,[])]), 
   
    pang=net_adm:ping('10250@c2'), 
    my_ssh:ssh_send("192.168.0.202",60202,"joq62","festum01","rm -rf dbase_application",5000),
    my_ssh:ssh_send("192.168.0.202",60202,"joq62","festum01","git clone https://github.com/joq62/dbase_application.git",5000),
    my_ssh:ssh_send("192.168.0.202",60202,"joq62","festum01","make -C dbase_application",5000),
    {pong,'10250@c2',dbase_application}=rpc:call('10250@c2',dbase_application,ping,[]), 
    io:format("~p~n",[rpc:call('10250@c2',dbase_application,services,[])]),
 
    pang=net_adm:ping('10250@c0'),
    my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","rm -rf dbase_application",5000),
    my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","git clone https://github.com/joq62/dbase_application.git",5000),
    my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","make -C dbase_application",5000),
    {pong,'10250@c0',dbase_application}=rpc:call('10250@c0',dbase_application,ping,[]), 
    io:format("~p~n",[rpc:call('10250@c0',dbase_application,services,[])]), 

    ?assertEqual(ok,application:start(mgmt)),
    ok=mgmt:init_cluster(),
    ?assertEqual(ok,application:start(iaas)),
    timer:sleep(10000),

    ok.

cleanup()->
    init:stop().




start_restart_computer()->
 %   ?assertEqual([{"c0.local.sthlm","joq62","festum01","192.168.0.200",60200,available}],
%		 if_db:computer_read("c0.local.sthlm")),
%    R=my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","date ",5000),
    R=my_ssh:ssh_send("192.168.0.200",60200,"joq62","festum01","erl -name 10250 -detached -setcookie abc",5000),
    io:format("~p~n",[{?MODULE,?LINE,R}]),
    ?assertEqual(pong,s(100,1000,'10250@c0.local.sthlm',glurk)),
    timer:sleep(100*60*1000),
    
    ok.

s(0,_,_,R)->
    R;
s(N,I,Node,_R)->
    NewR=case net_adm:ping(Node) of
	     pong->
		 NewN=0,
		 pong;
	     pang ->
		 timer:sleep(I),
		 NewN=N-1,
		 pang
	 end,
    io:format("Check if node started NewN,NewR ~p~n",[{?MODULE,?LINE,Node,NewN,NewR}]),
    s(NewN,I,Node,NewR).
