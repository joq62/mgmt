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
%    ?assertEqual(ok,setup()),
%    ?assertEqual(ok,setup2()),
    ?assertEqual(ok,setup5()),

    %% Start application tests
    ?debugMsg("Start normal_test"),
    ?assertEqual(ok,normal_test:start()),
    ?debugMsg("Stop normal_test"),

%    ?debugMsg("Start cluster_test"),
%    ?assertEqual(ok,cluster_test:start()),
%     ?debugMsg("Stop cluster_test"),
    
    ?debugMsg("Start stop_test_system:start"),
    %% End application tests
    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

print_statistics(SleepTime)->

    io:format("*************************  ~p~n",[time()]),
    io:format("statistics(total_active_tasks) ~p~n",[statistics(total_active_tasks)]),
    io:format("statistics(run_queue_lengths) ~p~n",[statistics(run_queue_lengths)]),
    io:format("statistics(run_queue_lengths_all) ~p~n",[statistics(run_queue_lengths_all)]),
    io:format("statistics(total_run_queue_lengths) ~p~n",[statistics(total_run_queue_lengths)]),
    io:format("statistics(total_run_queue_lengths_all) ~p~n",[statistics(total_run_queue_lengths_all)]),
    timer:sleep(SleepTime),
    spawn(fun()->print_statistics(1000) end),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
%    spawn(fun()->print_statistics(1000) end),
    ok=application:start(mgmt),
    ?assertEqual([{"dbase","1.0.0"},
		  {"oam","1.0.0"},
		  {"common","1.0.0"},
		  {"mgmt","1.0.0"}],mgmt:services()),
    ?assertMatch({pong,_,dbase},dbase:ping()),
    ?assertMatch({pong,_,oam},oam:ping()),
    ?assertMatch({pong,_,common},common:ping()),
    ?assertMatch({pong,_,mgmt},mgmt:ping()),


    AppId="calc",
    Vsn="1.0.0",
    {"c1",User,Passwd,Ip,Port}={"c1","joq62","festum01","192.168.0.201",60201},
    
    DeployDir=string:concat(AppId,misc_common:vsn_to_string(Vsn)),
    VmId=DeployDir,
    HostId="c1",
    ?assertEqual("calc100",DeployDir),
    AppNode=list_to_atom(VmId++"@"++HostId),
    ?assertEqual('calc100@c1',AppNode),
    Cookies="abc",

    rpc:call(AppNode,init,stop,[]),
    ?assertEqual(false,misc_common:vm_started(AppNode)), 

    ssh:start(),
    {ok,AppNode}=slave:start(HostId,VmId),
    ?assertEqual(true,misc_common:vm_started(AppNode)),
 
  %  io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"erl -sname "++VmId++" -setcookies "++Cookies++" -detached",5000)]),
 %   io:format("~p~n",[my_ssh:ssh_send(Ip,Port,User,Passwd,"erl -sname calc100 -setcookies abc -detached",5000)]),
 
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup5()->
    % Where to start dbase, mgmt?
    ssh:start(),

    % Intial start of mgmt
    ok=application:start(dbase),
    ok=application:start(oam),
    ok=application:start(mgmt),
 

    User="joq62",
    PassWd="festum01",
    Ip="192.168.0.200",
    Port=22,
    HostId="c0",
    VmId="10250",
    Cookie="abc",
    VmDir="10250",
    CommonId="common",
    CommonVsn="1.0.0",
    CommonGitpath="https://github.com/joq62/common.git",
    CommonStart={application,start,[common]},


    {ok,Db0}=misc_cmn:create_vm(User,PassWd,"192.168.0.200",Port,"c0",VmId,Cookie),
    ?assertEqual(ok,misc_cmn:create_service(Db0,VmDir,"common","1.0.0",{application,start,[common]},"https://github.com/joq62/common.git")),
    ?assertEqual(ok,misc_cmn:create_service(Db0,VmDir,"dbase_service","1.0.0",{application,start,[dbase]},"https://github.com/joq62/dbase_service.git")),
    {pong,_,common}=rpc:call(Db0,common,ping,[],2000),
    {pong,_,dbase}=rpc:call(Db0,dbase,ping,[],2000),
    ?debugMsg("10250@c0 created"),
    {ok,Db1}=misc_cmn:create_vm(User,PassWd,"192.168.0.201",Port,"c1",VmId,Cookie),
    ?assertEqual(ok,misc_cmn:create_service(Db1,VmDir,"common","1.0.0",{application,start,[common]},"https://github.com/joq62/common.git")),
    ?assertEqual(ok,misc_cmn:create_service(Db1,VmDir,"dbase_service","1.0.0",{application,start,[dbase]},"https://github.com/joq62/dbase_service.git")),
    {pong,_,common}=rpc:call(Db1,common,ping,[],2000),
    {pong,_,dbase}=rpc:call(Db1,dbase,ping,[],2000),
    ?debugMsg("10250@c1 created"),
    {ok,Db2}=misc_cmn:create_vm(User,PassWd,"192.168.0.202",Port,"c2",VmId,Cookie),
    ?assertEqual(ok,misc_cmn:create_service(Db2,VmDir,"common","1.0.0",{application,start,[common]},"https://github.com/joq62/common.git")),
    ?assertEqual(ok,misc_cmn:create_service(Db2,VmDir,"dbase_service","1.0.0",{application,start,[dbase]},"https://github.com/joq62/dbase_service.git")),
    {pong,_,common}=rpc:call(Db2,common,ping,[],2000),
    {pong,_,dbase}=rpc:call(Db2,dbase,ping,[],2000),
    ?debugMsg("10250@c2 created"),

    ok=oam:preload_dbase(),
    computer:get_computer_status(running),
 %   ?assertEqual(ok,application:start(iaas)),
 %   timer:sleep(5000),
    ?assertEqual([{"c2",running},{"c1",running},{"c0",running}],db_computer:status(running)),

   ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup4()->
    ssh:start(),

    User="joq62",
    PassWd="festum01",
    Ip="192.168.0.200",
    Port=22,
    HostId="c0",
    VmId="10250",
    Cookie="abc",
    VmDir="10250",
    AppIdId="common",
    Vsn="1.0.0",
    StartFun=boot,
    Gitpath="https://github.com/joq62/common.git",
    {ok,Db0}=misc_cmn:create_worker(User,PassWd,Ip,Port,HostId,VmId,Cookie,VmDir,AppIdId,Vsn,{application,start,[common]},Gitpath),
    {pong,_,common}=rpc:call(Db0,common,ping,[],2000),
    io:format("~p~n",[rpc:call(Db0,common,ping,[],2000)]),

    ?assertEqual(ok,misc_cmn:create_service(Db0,VmDir,"calc","1.0.0",{calc,boot,[]},"https://github.com/joq62/calc.git")),
    {pong,Db0,calc}=rpc:call(Db0,calc,ping,[]),
    io:format("~p~n",[rpc:call(Db0,calc,ping,[],2000)]),

    ?assertEqual(42,rpc:call(Db0,adder_service,add,[20,22])),
 
    misc_cmn:delete_worker(Db0,VmDir),
    {badrpc,{'EXIT',{noproc,{gen_server,call,[common,{ping},infinity]}}}}=rpc:call(Db0,common,ping,[],2000),
    {badrpc,{'EXIT',{noproc,{gen_server,call,[calc,{ping},infinity]}}}}=rpc:call(Db0,calc,ping,[]),
    {badrpc,{'EXIT',{noproc,{gen_server,call,[adder_service,{add,20,22},infinity]}}}}=rpc:call(Db0,adder_service,add,[20,22]),
    
   ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup3()->
    ssh:start(),

    
    %Start computer node
  %  {ok,C0}=misc_cmn:create_vm("joq62","festum01","192.168.0.200",22,"c0","computer","abc"),
  %  {ok,C1}=misc_cmn:create_vm("joq62","festum01","192.168.0.201",22,"c1","computer","abc"),
  %  {ok,C2}=misc_cmn:create_vm("joq62","festum01","192.168.0.202",22,"c2","computer","abc"),

 %   D=date(),
 %   ?assertEqual(D,rpc:call(C0,erlang,date,[],5000)),
 %   ?assertEqual(D,rpc:call(C1,erlang,date,[],5000)),
 %   ?assertEqual(D,rpc:call(C2,erlang,date,[],5000)),

    {ok,Db0}=misc_cmn:create_vm("joq62","festum01","192.168.0.200",22,"c0","10250","abc"),
    ?assertEqual(ok,misc_cmn:create_service(Db0,"databases","dbase_application","1.0.0",boot,"https://github.com/joq62/dbase_application.git")),
    {pong,Db0,dbase_application}=rpc:call(Db0,dbase_application,ping,[]),

    ?assertEqual(ok,misc_cmn:create_service(Db0,"databases","calc","1.0.0",boot,"https://github.com/joq62/calc.git")),
    {pong,Db0,calc}=rpc:call(Db0,calc,ping,[]),
    
    ?assertEqual(42,rpc:call(Db0,adder_service,add,[20,22])),
  %  timer:sleep(500),
 %   ?assertEqual([{dbase_application,"dbase_application","1.0.0"},
%		  {dbase,"dbase","1.0.0"},
%		  {mnesia,"MNESIA  CXC 138 12","4.17"},
%		  {common,"common","1.0.0"},
%		  {stdlib,"ERTS  CXC 138 10","3.13"},
%		  {kernel,"ERTS  CXC 138 10","7.0"}],
%		 rpc:call(Db0,dbase_application,services,[])),

    
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup2()->
    ssh:start(),


    %Start computer node
    C0='computer@c0',
    C1='computer@c1',
    C2='computer@c2',
    rpc:call(C0,init,stop,[]),  
    rpc:call(C1,init,stop,[]), 
    rpc:call(C2,init,stop,[]),  

    timer:sleep(2000),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.200",22,"joq62","festum01","erl -sname computer -setcookie abc -detached",5000)]),
    ?assertEqual(true,misc_common:vm_started(C0)),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",22,"joq62","festum01","erl -sname computer -setcookie abc -detached",5000)]),
    ?assertEqual(true,misc_common:vm_started(C1)),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.202",22,"joq62","festum01","erl -sname computer -setcookie abc -detached",5000)]),
    ?assertEqual(true,misc_common:vm_started(C2)),
    
    % start dbase
    rpc:call('10250@c0',init,stop,[]),  
    rpc:call('10250@c1',init,stop,[]), 
    rpc:call('10250@c2',init,stop,[]),  
    timer:sleep(2000),
    pang=net_adm:ping('10250@c1'),
    DbaseApp="dbase_application",
    GitUser="joq62",
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",22,"joq62","festum01","rm -rf "++DbaseApp,5000)]),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",22,"joq62","festum01","git clone https://github.com/"++GitUser++"/"++DbaseApp++".git",5000)]),
    io:format("~p~n",[my_ssh:ssh_send("192.168.0.201",22,"joq62","festum01","make -C "++DbaseApp,5000)]),
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

    ok=oam:preload_dbase(),
    computer:get_computer_status(running),
 %   ?assertEqual(ok,application:start(iaas)),
 %   timer:sleep(5000),
    ?assertEqual([{"c2",running},{"c1",running},{"c0",running}],db_computer:status(running)),

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
