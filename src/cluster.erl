%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%%  c
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(cluster). 

-export([init/0	
	]).


-define(DbaseVmId,"10250").
-define(ControlVmId,"10250").
-define(TimeOut,3000).
-define(InitFile,"./test_src/table_info.hrl").

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init()->
    ok=init_dbase(),
    ok.

% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_dbase()->
    {ok,LocalHostId}=net:gethostname(),
    DbaseVm=list_to_atom(?DbaseVmId++"@"++LocalHostId),
    {ok,Info}=file:consult(?InitFile),
    rpc:call(DbaseVm,dbase,init_table_info,[Info],5000),
    ok.
% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
