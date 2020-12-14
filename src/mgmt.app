%% This is the application resource file (.app file) for the 'base'
%% application.
{application, mgmt,
[{description, "mgmt" },
{vsn, "1.0.0" },
{modules, 
	  [mgmt_app,mgmt_sup,mgmt,db_mgmt]},
{registered,[mgmt]},
{applications, [kernel,stdlib]},
{mod, {mgmt_app,[]}},
{start_phases, []}
]}.
