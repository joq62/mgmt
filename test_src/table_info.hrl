[db_computer,"c0","joq62","festum01","192.168.0.200",60200,not_available].
[db_computer,"c1","joq62","festum01","192.168.0.201",60201,not_available].
[db_computer,"c2","joq62","festum01","192.168.0.202",60202,not_available].

[db_service_def,"adder_service","1.0.0","joq62"].
[db_service_def,"multi_service","1.0.0","joq62"].
[db_service_def,"divi_service","1.0.0","joq62"].
[db_service_def,"common","1.0.0","joq62"].

[db_passwd,"joq62","20Qazxsw20"].

[db_deployment_spec,"math","1.0.0",no_restrictions,[{"adder_service","1.0.0"},{"divi_service","1.0.0"}]].
[db_deployment_spec,"control","1.0.0",{node,'10250@asus'},[{"control","1.0.0"},{"iaas","1.0.0"}]].

