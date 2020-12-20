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
 
    ?debugMsg("Start setup"),
    ?assertEqual(ok,setup()),
    ?debugMsg("Stop setup "), 

   ?debugMsg("Start init_test"),
    ?assertEqual(ok,init_dbase_test()),
    ?debugMsg("Stop init_test "),

    ?debugMsg("Start add_dbase_nodes"),
    ?assertEqual(ok,add_dbase_nodes()),
    ?debugMsg("Stop add_dbase_nodes "),

    ?debugMsg("Start deploy_application"),
    ?assertEqual(ok,deploy_test("calc","1.0.0","c1","abc")),
    ?debugMsg("Stop deploy_application "),

%    ?debugMsg("Start deploy_application"),
%    ?assertEqual(ok,deploy_application("calc","1.0.0")),
%    ?debugMsg("Stop deploy_application "),
   

   %% End application tests
    cleanup(),
    ok.

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
deploy_test(AppId,Vsn,HostId,Cookie)->

    % Start new Vm
    [{HostId,User,PassWd,Ip,Port,running}]=db_computer:read(HostId),
    ?assertEqual({"c1","joq62","festum01","192.168.0.201",22},{"c1",User,PassWd,Ip,Port}),
    
    VmId=AppId++misc_cmn:vsn_to_string(Vsn)++"_worker",
    VmDir=VmId,
    {ok,AppVm}=misc_cmn:create_vm(User,PassWd,Ip,Port,HostId,VmId,Cookie),

    ?assertEqual(pong,net_adm:ping(AppVm)),
    ?assertEqual(ok,misc_cmn:create_service(AppVm,VmDir,"common","1.0.0",{application,start,[common]},"https://github.com/joq62/common.git")),
    ?assertMatch({pong,_,common},rpc:call(AppVm,common,ping,[])), 
   

    % Start services
    [{AppId,Vsn,_Restrictions,Services}]=db_deployment_spec:read(AppId,Vsn),
    ?assertEqual([{"adder_service","1.0.0"},
		   {"multi_service","1.0.0"},
		   {"divi_service","1.0.0"}],
		 Services),
    
    ServiceDefs=lists:append([db_service_def:read(XServiceId,XVsn)||{XServiceId,XVsn}<-Services]),
    
    StartResult=[{YServiceId,YVsn,HostId,AppVm,VmDir,misc_cmn:create_service(AppVm,VmDir,YServiceId,YVsn,YStartMFA,YGitPath)}||{YServiceId,YVsn,YStartMFA,YGitPath}<-ServiceDefs],
    
    [db_sd:create(ZServiceId,ZVsn,HostId,VmId,AppVm)||{ZServiceId,ZVsn,_,_,ok}<-StartResult],

    io:format("StartResult = ~p~n",[StartResult]),
    
    % test loaded application 
    ?assertEqual(42,rpc:call(AppVm,adder_service,add,[20,22])),
    io:format("~p~n",[rpc:call('10250@c0',db_sd,read_all,[],2000)]),
    % stop unload application
    
    
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
add_dbase_nodes()->
    % Test All computers are running
  %  {pong,'10250@c0',dbase_application}=rpc:call('10250@c0',dbase_application,ping,[]), 
  %  {pong,'10250@c1',dbase_application}=rpc:call('10250@c1',dbase_application,ping,[]), 
  %  {pong,'10250@c2',dbase_application}=rpc:call('10250@c2',dbase_application,ping,[]), 

    % Algorithm
    AllComputersInfo=db_computer:read_all(),
    OtherDbaseVm=[list_to_atom(?DbaseVmId++"@"++XHostId)||{XHostId,_User,_Passwd,_Ip,_Port,_Status}<-AllComputersInfo],
    io:format("first add_node ~p~n",[[dbase:add_node(XDbaseVm)||XDbaseVm<-OtherDbaseVm]]),  
  % 
    
    io:format("OtherDbaseVm ~p~n",[OtherDbaseVm]),
  
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		 {"c1","joq62","festum01","192.168.0.201",22,running},
		 {"c0","joq62","festum01","192.168.0.200",22,running}],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),

    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		  {"c1","joq62","festum01","192.168.0.201",22,running},
		  {"c0","joq62","festum01","192.168.0.200",22,running}],
		 rpc:call('10250@c1',if_db,computer_read_all,[])),

    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		  {"c1","joq62","festum01","192.168.0.201",22,running},
		  {"c0","joq62","festum01","192.168.0.200",22,running}],
		 rpc:call('10250@c2',if_db,computer_read_all,[])),

    io:format("second add_node ~p~n",[[dbase:add_node(XDbaseVm)||XDbaseVm<-OtherDbaseVm]]),  
   ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		 {"c1","joq62","festum01","192.168.0.201",22,running},
		 {"c0","joq62","festum01","192.168.0.200",22,running}],
		 rpc:call('10250@c0',if_db,computer_read_all,[])),
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		  {"c1","joq62","festum01","192.168.0.201",22,running},
		  {"c0","joq62","festum01","192.168.0.200",22,running}],
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
    ?assertEqual([{"c2","joq62","festum01","192.168.0.202",22,running},
		 {"c1","joq62","festum01","192.168.0.201",22,running},
		 {"c0","joq62","festum01","192.168.0.200",22,running}],
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


