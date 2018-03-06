FROM debian:stretch-slim
MAINTAINER Kane Valentine <kane.valentine@opusvl.com>

ENV DEBIAN_FRONTEND noninteractive

RUN set -ex; \
	\
	apt-get update -qq; \
	apt-get install -y -qq --no-install-suggests --no-install-recommends \
		ca-certificates \
		curl \
		lua5.1 \
		liblua5.1 \
		libssl1.0.2 \
		libidn11 \
		lua-sec \
		lua-event \
		lua-zlib \
		lua-dbi-postgresql \
		lua-bitop \
		lua-socket \
		lua-expat \
		lua-filesystem

ENV PROSODY_VERSION 0.10.0
ENV PROSODY_SHA1 57c1c5a665e6453bdde06727ef398cd69accd9d7

RUN set -ex; \
	curl -o prosody.tar.gz -fSL "https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz"; \
	echo "$PROSODY_SHA1 *prosody.tar.gz" | sha1sum -c -; \
	tar -xzf prosody.tar.gz -C /usr/src/; \
	rm prosody.tar.gz

WORKDIR /usr/src/prosody-$PROSODY_VERSION

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get install -y -qq --no-install-suggests --no-install-recommends \
		build-essential \
		liblua5.1-dev \
		libidn11-dev \
		libssl-dev \
	; \
	\
	${PWD}/configure --ostype=debian --prefix=/usr --sysconfdir=/etc/prosody --datadir=/var/lib/prosody; \
	make && make install; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

ADD prosody.cfg.lua /etc/prosody/prosody.cfg.lua

RUN useradd -ms /bin/bash prosody \
    && chown -R prosody:prosody /etc/prosody/* \
    && chmod -R 760 /etc/prosody/*

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

USER prosody:prosody
CMD ["prosodyctl", "start"]
