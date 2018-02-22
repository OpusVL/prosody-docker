FROM debian:stretch-slim
MAINTAINER Kane Valentine <kane.valentine@opusvl.com>

ENV DEBIAN_FRONTEND noninteractive

RUN set -ex; \
	\
	apt-get update -qq; \
	apt-get install -y -qq --no-install-suggests --no-install-recommends \
		build-essential \
		ca-certificates \
		curl \
		lua5.2 \
		liblua5.2 \
		liblua5.2-dev \
		libssl1.0.2 \
		libssl-dev \
		libidn11 \
		libidn11-dev \
		lua-sec \
		lua-event \
		lua-zlib \
		lua-dbi-postgresql \
		lua-bitop \
		lua-socket \
		lua-expat \
		lua-filesystem \
	; \
        apt-get clean; \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PROSODY_VERSION 0.10.0
ENV PROSODY_SHA1 57c1c5a665e6453bdde06727ef398cd69accd9d7

RUN set -ex; \
	curl -o prosody.tar.gz -fSL "https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz"; \
	echo "$PROSODY_SHA1 *prosody.tar.gz" | sha1sum -c -; \
	tar -xzf prosody.tar.gz -C /usr/src/; \
	rm prosody.tar.gz

WORKDIR /usr/src/prosody-$PROSODY_VERSION

RUN ${PWD}/configure	--lua-version=5.2 \
			--sysconfdir=/etc/prosody \
			--libdir=/lib \
			--datadir=/var/lib/prosody

RUN make \
    && make install

RUN useradd -ms /bin/bash prosody

USER prosody:prosody
CMD ["prosodyctl", "start"]
