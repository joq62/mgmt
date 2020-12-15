%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(cluster_test).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

-define(DbaseVmId,"10250").

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
 
    ?debugMsg("Start init_test"),
    ?assertEqual(ok,init_dbase_test()),
    ?debugMsg("Stop init_test "),

    ?debugMsg("Start add_dbase_nodes"),
    ?assertEqual(ok,add_dbase_nodes()),
    ?debugMsg("Stop add_dbase_nodes "),

   

   %% End application tests
    cleanup(),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
add_dbase_nodes()->
    % Test All computers are running
    {pong,'10250@c0',dbase_application}=rpc:call('10250@c0',dbase_application,ping,[]), 
    {pong,'10250@c1',dbase_application}=rpc:call('10250@c1',dbase_application,ping,[]), 
    {pong,'10250@c2',dbase_application}=rpc:call('10250@c2',dbase_application,ping,[]), 

    % Algorithm
    {ok,LocalHostId}=net:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++LocalHostId),
    AllComputersInfo=rpc:call(DbaseVm,if_db,computer_read_all,[],5000),
    OtherDbaseVm=[list_to_atom(?DbaseVmId++"@"++XHostId)||{XHostId,_User,_Passwd,_Ip,_Port,_Status}<-AllComputersInfo,
							 XHostId/=LocalHostId],
    io:format("first add_node ~p~n",[[rpc:call(DbaseVm,dbase,add_node,[XDbaseVm])||XDbaseVm<-OtherDbaseVm]]),  
  % 
    
    io:format("OtherDbaseVm ~p~n",[OtherDbaseVm]),
  
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		 {"c1","joq62","festum01","192.168.0.201",60201,running},
		 {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		  {"c1","joq62","festum01","192.168.0.201",60201,running},
		  {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c1',if_db,computer_read_all,[])),

    io:format("second add_node ~p~n",[[rpc:call(DbaseVm,dbase,add_node,[XDbaseVm])||XDbaseVm<-OtherDbaseVm]]), 

   ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		 {"c1","joq62","festum01","192.168.0.201",60201,running},
		 {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		  {"c1","joq62","festum01","192.168.0.201",60201,running},
		  {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c1',if_db,computer_read_all,[])), 
    % Ensure that local computer running mgmt restarts
%    OtherComputers=[{XHostId,User,Passwd,Ip,Port,Status}||{XHostId,User,Passwd,Ip,Port,Status}<-AllComputersInfo,
%			  LocalHostId/=XHostId],
    
    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_dbase_test()->
    %
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		 {"c1","joq62","festum01","192.168.0.201",60201,running},
		 {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 if_db:computer_read_all()),

    ?assertEqual([],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),
    ?assertEqual([],
		 rpc:call('10250@c1',if_db,computer_read_all,[])),
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		  {"c1","joq62","festum01","192.168.0.201",60201,running},
		  {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c2',if_db,computer_read_all,[])),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    
    ok.

cleanup()->


    ok.


