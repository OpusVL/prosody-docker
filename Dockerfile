FROM debian:stretch-slim

LABEL vendor="The Prosody Team"
LABEL maintainer="Kane Valentine <kane@cute.im>"

ENV DEBIAN_FRONTEND noninteractive

ARG lua_version=5.2
ENV LUA_VERSION $lua_version

RUN set -ex; \
	\
	apt-get update -qq; \
	apt-get install -y -qq --no-install-suggests --no-install-recommends \
		ca-certificates \
	        mercurial \
		curl \
		lua$LUA_VERSION \
		liblua$LUA_VERSION \
		libssl1.0.2 \
		libidn11 \
		lua-sec \
		lua-event \
		lua-zlib \
		lua-dbi-postgresql \
		lua-dbi-mysql \
		lua-dbi-sqlite3 \
		lua-bitop \
		lua-socket \
		lua-expat \
		lua-filesystem

ARG prosody_version=0.11.1
ARG prosody_sha1=dacce98fda317f5ba3c05842e2d97018d050b435

ENV PROSODY_VERSION $prosody_version
ENV PROSODY_SHA1 $prosody_sha1

RUN if [ "$PROSODY_VERSION" = "trunk" ]; then \
        hg clone https://hg.prosody.im/trunk/ /usr/src/prosody-$PROSODY_VERSION; \
    else \
        set -ex; \
        curl -o prosody.tar.gz -fSL "https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz"; \
        echo "$PROSODY_SHA1 *prosody.tar.gz" | sha1sum -c -; \
        tar -xzf prosody.tar.gz -C /usr/src/; \
        rm prosody.tar.gz; \
    fi

WORKDIR /usr/src/prosody-$PROSODY_VERSION

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get install -y -qq --no-install-suggests --no-install-recommends \
		build-essential \
		bsdmainutils \
		liblua5.1-dev \
		libidn11-dev \
		libssl-dev \
	; \
	\
	${PWD}/configure --lua-version=$LUA_VERSION --prefix=/usr --sysconfdir=/etc/prosody --datadir=/var/lib/prosody; \
	make && make install; \
	\
	hg clone https://hg.prosody.im/prosody-modules/ /opt/prosody-modules-available/ \
	&& mkdir /opt/prosody-modules-enabled; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

ADD configuration/prosody.cfg.lua /etc/prosody/prosody.cfg.lua
ADD configuration/conf.d/ /etc/prosody/conf.d/

RUN set -ex; \
	\
	useradd -rs /bin/false prosody \
		&& mkdir /etc/prosody/cmpt.d/ /etc/prosody/vhost.d/ \
		&& chown -R prosody:prosody /etc/prosody/ /var/lib/prosody/ /opt/prosody-modules-* \
		&& chmod -R 760 /etc/prosody/ /var/lib/prosody/ /opt/prosody-modules-*

COPY entrypoint.pl /usr/local/bin/
ENTRYPOINT ["entrypoint.pl"]

USER prosody:prosody
CMD ["/usr/bin/prosody"]
