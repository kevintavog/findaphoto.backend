BUILD_ID:=$(shell date +%s)

build:
	swift build

release-build:
	swift build -c release -Xswiftc -static-stdlib

update:
	swift package update

tojupiter: image push

base-image:
	cd baseImage && docker build -f Dockerfile.runtimeBase . -t docker.rangic:6000/findaphoto.base:${BUILD_ID} && cd ..

image:
	docker build . -t docker.rangic:6000/findaphoto.backend:${BUILD_ID}

push:
	docker push docker.rangic:6000/findaphoto.backend:${BUILD_ID}
