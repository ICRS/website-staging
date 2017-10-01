all:
	jbuilder build

update_config:
	scp -r -i ../icrs.pem config.sexp  ubuntu@35.177.234.162:~/calendar/config.sexp

deploy:
	scp -r -i ../icrs.pem _build/install/default/bin/main  ubuntu@35.177.234.162:~/calendar/main
