prepare:
	@sudo docker build -t nitrousio/cartman-test .

test:
	@./script/run_test

.PHONY: test prepare
