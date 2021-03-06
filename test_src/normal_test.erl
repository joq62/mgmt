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
    ?assertEqual(ok,deploy_test("test_1","1.0.0","c1","abc")),
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
deploy_test(DepSpecId,DepSpecVsn,HostId,Cookie)->

  

    % Start New Vm
    VmId="glurk",
    VmDir="glurk_1_dir",
    PreLoadedServices=[{"common","1.0.0"}], 
    {ok,TestVm}=vm:create(HostId,VmId,VmDir,Cookie,PreLoadedServices),
   
  %  ?assertEqual(pong,net_adm:ping(TestVm)),
  %  ?assertMatch({pong,_,common},rpc:call(TestVm,common,ping,[])), 
   

    % Start services
    
    % check appl
    ?assertEqual({ok,1},appl:instances(DepSpecId,DepSpecVsn)),
    ?assertEqual({ok,no_restrictions},appl:restrictions(DepSpecId,DepSpecVsn)),
  
    ?assertEqual({ok,
		  [{"adder_service","1.0.0",{application,start,[adder_service]},"https://github.com/joq62/adder_service.git"},
		   {"multi_service","1.0.0",{application,start,[multi_service]},"https://github.com/joq62/multi_service.git"},
		   {"divi_service","1.0.0",{application,start,[divi_service]},"https://github.com/joq62/divi_service.git"}]},
		 appl:service_info(DepSpecId,DepSpecVsn)),

    ?assertEqual({error,[eexists,glurk,"1.0.0"]},appl:instances(glurk,DepSpecVsn)),
    ?assertEqual({error,[eexists,"test_1",glurk]},appl:restrictions(DepSpecId,glurk)),
    ?assertEqual({error,[eexists,glurk,glurk]},appl:service_info(glurk,glurk)),


    
  % 1. Get deployment spec 
    
    [{DepSpecId,DepSpecVsn,NumInstances,Restrictions,AppList}]=if_db:deployment_spec_read(DepSpecId,DepSpecVsn),
    io:format("DepSpecId,DepSpecVsn = ~p~n",[{DepSpecId,DepSpecVsn,NumInstances,Restrictions,AppList}]),
    ?assertEqual({"test_1","1.0.0",1,no_restrictions,[{"calc","1.0.0"}]},{DepSpecId,DepSpecVsn,NumInstances,Restrictions,AppList}),

    % 2. Get Appspec onely one app per deployment spec

    [{AppId,AppVsn}]=AppList,
    AppInfo=if_db:app_spec_read(AppId,AppVsn),
    io:format("AppInfo = ~p~n",[AppInfo]),

    % Get Service infoAppList
    [{AppId,AppVsn,ZServiceList}]=AppInfo,
    
    
    ServiceInfo=lists:append([if_db:service_def_read(ZServiceId,ZServiceVsn)||{ZServiceId,ZServiceVsn}<-ZServiceList]),
    io:format("ServiceInfo = ~p~n",[ServiceInfo]),
    
  
    StartResult=[{YServiceId,YServiceVsn,HostId,TestVm,VmDir,service:create(TestVm,VmDir,YServiceId,YServiceVsn,YStartCmd,YGitPath)}||{YServiceId,YServiceVsn,YStartCmd,YGitPath}<-ServiceInfo],
    
    % Check if started ok , add to service discovery
    [if_db:sd_create(ZServiceId,ZVsn,HostId,VmId,TestVm)||{ZServiceId,ZVsn,_HostId,_TestVm,_VmDir,ok}<-StartResult],
    
    % Store deployment
    
    io:format("StartResult = ~p~n",[StartResult]),
    io:format("deployment [] = ~p~n",[if_db:deployment_read(DepSpecId,DepSpecVsn)]),
    case if_db:deployment_read(DepSpecId,DepSpecVsn) of
	[]->
	    if_db:deployment_create(DepSpecId,DepSpecVsn,date(),time(),StartResult);
	_ ->
	    if_db:deployment_update(DepSpecId,DepSpecVsn,date(),time(),StartResult)
    end,
    io:format("deployment StartResult  = ~p~n",[if_db:deployment_read(DepSpecId,DepSpecVsn)]),
    
    % test loaded application 
    ?assertEqual(42,rpc:call(TestVm,adder_service,add,[20,22])),
    io:format("~p~n",[rpc:call('10250@c0',db_sd,read_all,[],2000)]),

    % stop unload application
    [{DepSpecId,DepSpecVsn,_Date,_Time,
      StartResult}]=if_db:deployment_read(DepSpecId,DepSpecVsn),
    [{_ServiceId,_ServiceVsn,HostId,Vm,VmDir,ok}|_]=StartResult,

    vm:delete(Vm,VmDir),
    ?assertEqual({badrpc,{'EXIT',{noproc,{gen_server,call,[adder_service,{add,20,22},infinity]}}}},rpc:call(Vm,adder_service,add,[20,22])),
    
    if_db:deployment_delete(DepSpecId,DepSpecVsn),
    []=if_db:deployment_read(DepSpecId,DepSpecVsn),
    
    [if_db:sd_delete(ZServiceId,ZVsn,ZTestVm)||{ZServiceId,ZVsn,_HostId,ZTestVm,_VmDir,ok}<-StartResult],
    []=if_db:sd_read_all(),
    
    
    
    
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


