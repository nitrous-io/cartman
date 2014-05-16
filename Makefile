prepare:
	@docker build -t nitrousio/cartman-test - < Dockerfile.test

build-release:
	@docker build -t registry.nitrous.io/cartman-release .
.PHONY: build-release

release-openresty: build-release
	@docker run -v $(CURDIR):/opt/cartman registry.nitrous.io/cartman-release \
		/opt/cartman/script/release-openresty 
.PHONY: release-openresty

release-cartman: build-release
	@docker run -v $(CURDIR):/opt/cartman registry.nitrous.io/cartman-release \
		 /opt/cartman/script/release-cartman
.PHONY: release-cartman

test:
	@./script/run_test

.PHONY: test prepare
