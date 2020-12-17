%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(normal_test).  
   
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

    ?debugMsg("Start deploy_application"),
    ?assertEqual(ok,deploy_application("calc","1.0.0")),
    ?debugMsg("Stop deploy_application "),
   

   %% End application tests
    cleanup(),
    ok.



deploy_application(AppId,Vsn)->
 %   ?assertEqual(glurk,db_deployment_spec:read_all()),
    % DeploymentInfo
    [{AppId,Vsn,Restrictions,Commands}]=db_deployment_spec:read(AppId,Vsn),
    ?assertEqual({"calc","1.0.0",no_restrictions,
		  ["rm -rf calc",
		   "git clone https://github.com/joq62/calc.git",
		   "make -C calc"]},
		  {AppId,Vsn,Restrictions,Commands}),
    
    [{HostId,User,Passwd,Ip,Port,running}]=db_computer:read("c1"),
    ?assertEqual({"c1","joq62","festum01","192.168.0.201",60201},{"c1",User,Passwd,Ip,Port}),
    
   
   % io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"rm -rf "++AppId,5000)]),
    
  %  io:format("~p~n",[rpc:call('computer@c1',os,cmd,["rm -rf "++AppId])]),  
  %  {ok,AppNode}=rpc:call('computer@c1',slave,start,[HostId,
%						  list_to_atom(AppId),
%						  "-pa "++AppId++"/ebin -setcookie abc -detached"
%						 ]),
  %  ?assertEqual(pong,net_adm:ping(AppNode)),
  %  io:format("~p~n",[rpc:call('computer@c1',os,cmd,["git clone "++GitPath])]),
  %  ok=rpc:call(AppNode,application,start,[list_to_atom(AppId)],5000),

    rpc:call(list_to_atom(AppId++"@"++HostId),init,stop,[]),
  %  io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"rm -rf "++AppId,5000)]),
  %  io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"git clone "++GitPath,5000)]),
  %  io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"make -C "++AppId,5000)]),
    [io:format("~p~n",[{Cmd,my_ssh:ssh_send(Ip,Port,User,Passwd,Cmd,5000)}])||Cmd<-Commands],
    AppNode=list_to_atom(AppId++"@"++HostId),
    Module=list_to_atom(AppId),
    ?assertMatch({pong,_,Module},rpc:call(AppNode,calc,ping,[])), 
    ?assertEqual([{"adder_service"},{"divi_service"},{"multi_service"},{"common"},{"calc"}],rpc:call(AppNode,calc,services,[])), 
    ?assertEqual(42,rpc:call(AppNode,adder_service,add,[20,22])),
    

    
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
    AllComputersInfo=db_computer:read_all(),
    OtherDbaseVm=[list_to_atom(?DbaseVmId++"@"++XHostId)||{XHostId,_User,_Passwd,_Ip,_Port,_Status}<-AllComputersInfo],
    io:format("first add_node ~p~n",[[dbase:add_node(XDbaseVm)||XDbaseVm<-OtherDbaseVm]]),  
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

    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",60202,running},
		  {"c1","joq62","festum01","192.168.0.201",60201,running},
		  {"c0","joq62","festum01","192.168.0.200",60200,running}],
		 rpc:call('10250@c2',if_db,computer_read_all,[])),

    io:format("second add_node ~p~n",[[dbase:add_node(XDbaseVm)||XDbaseVm<-OtherDbaseVm]]),  
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
		 db_computer:read_all()),

    ?assertEqual([],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),
    ?assertEqual([],
		 rpc:call('10250@c1',if_db,computer_read_all,[])),
    ?assertEqual([],
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


