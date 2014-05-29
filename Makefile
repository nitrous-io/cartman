prepare:
	@docker build -t nitrousio/cartman-test - < Dockerfile.test

build-release:
	@docker build -t registry.nitrous.io/cartman-release .
.PHONY: build-release

release-openresty: build-release
	@if [ ! -d $(HOME)/build ]; then mkdir $(HOME)/build; fi
	@docker run -v $(CURDIR):/opt/cartman -v $(HOME)/build:/opt/cartman/build registry.nitrous.io/cartman-release \
		/opt/cartman/script/release-openresty 
.PHONY: release-openresty

release-cartman: build-release
	@if [ ! -d $(HOME)/build ]; then mkdir $(HOME)/build; fi
	@docker run -v $(CURDIR):/opt/cartman -v $(HOME)/build:/opt/cartman/build registry.nitrous.io/cartman-release \
		 /opt/cartman/script/release-cartman
.PHONY: release-cartman

release-all: build-release release-openresty release-cartman
.PHONY: release-all

test:
	@./script/run_test

.PHONY: test prepare
