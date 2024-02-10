PKG_VERSION=3.0.12.20240210
PKG_REL_PREFIX=1hn1
ifdef NO_CACHE
DOCKER_NO_CACHE=--no-cache
endif

LOGUNLIMITED_BUILDER=logunlimited
LUAJIT_DEB_VERSION=v2.1-20231117

# Ubuntu 22.04
deb-ubuntu2204: build-ubuntu2204
	docker run --rm -v ./dist-ubuntu2204:/dist modsecurity-ubuntu2204 bash -c \
	"cp /src/modsecurity*${PKG_VERSION}* /dist/"

build-ubuntu2204: buildkit-logunlimited
	mkdir -p dist-ubuntu2204
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--build-arg OS_TYPE=ubuntu --build-arg OS_VERSION=22.04 \
		--build-arg PKG_REL_DISTRIB=ubuntu22.04 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=ubuntu2204 \
		-t modsecurity-ubuntu2204 . \
	) 2>&1 | tee dist-ubuntu2204/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log
	xz --best --force dist-ubuntu2204/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}ubuntu22.04.build.log

run-ubuntu2204:
	docker run --rm -it modsecurity-ubuntu2204 bash

# Debian 12
deb-debian12: build-debian12
	docker run --rm -v ./dist-debian12:/dist modsecurity-debian12 bash -c \
	"cp /src/modsecurity*${PKG_VERSION}* /dist/"

build-debian12: buildkit-logunlimited
	mkdir -p dist-debian12
	(set -x; \
	git submodule foreach --recursive git remote -v; \
	git submodule status --recursive; \
	docker buildx build --progress plain --builder ${LOGUNLIMITED_BUILDER} --load \
		${DOCKER_NO_CACHE} \
		--build-arg OS_TYPE=debian --build-arg OS_VERSION=12 \
		--build-arg PKG_REL_DISTRIB=debian12 \
		--build-arg PKG_VERSION=${PKG_VERSION} \
		--build-arg LUAJIT_DEB_VERSION=${LUAJIT_DEB_VERSION} \
		--build-arg LUAJIT_DEB_OS_ID=debian12 \
		-t modsecurity-debian12 . \
	) 2>&1 | tee dist-debian12/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log
	xz --best --force dist-debian12/modsecurity_${PKG_VERSION}-${PKG_REL_PREFIX}debian12.build.log

run-debian12:
	docker run --rm -it modsecurity-debian12 bash

buildkit-logunlimited:
	if ! docker buildx inspect logunlimited 2>/dev/null; then \
		docker buildx create --bootstrap --name ${LOGUNLIMITED_BUILDER} \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
			--driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1; \
	fi

exec:
	docker exec -it $$(docker ps -q) bash

.PHONY: deb-debian12 run-debian12 build-debian12 deb-ubuntu2204 run-ubuntu2204 build-ubuntu2204 buildkit-logunlimited exec
