all:
	rm -rf *.beam *~ */*~ */*/*~ src/*.beam test_src/*.beam ebin/* test_ebin/* erl_crash.dump;
	cp src/*app ebin

doc_gen:
	rm -rf  node_config logfiles doc/*;
	erlc ../doc_gen.erl;
	erl -s doc_gen start -sname doc

test:
	rm -rf *.beam src/*.beam test_src/*.beam ebin/* test_ebin/* erl_crash.dump;
#	common
	cp ../common/src/*app ebin;
	erlc -o ebin ../common/src/*.erl;
#	dbase
	cp test_src/*.hrl ebin;
	cp ../dbase_service/src/*app ebin;
	erlc -o ebin ../dbase_service/src/*.erl;
#	iaas
	cp ../iaas/src/*app ebin;
	erlc -o ebin ../iaas/src/*.erl;
	cp src/*app ebin;
	erlc -o ebin src/*.erl;
	erlc -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin -s mgmt_tests start -sname mgmt -setcookie abc
