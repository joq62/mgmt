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

-define(Master,"c2").
-define(MnesiaNodes,['10250@c2']).



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

    ?debugMsg("Start cluster_1_test"),
    ?assertEqual(ok,cluster_1_test()),
    ?debugMsg("Stop cluster_1_test "),

   

   %% End application tests
    cleanup(),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
cluster_1_test()->
    % restart the other computers
    AllComputersInfo=if_db:computer_read_all(),
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


