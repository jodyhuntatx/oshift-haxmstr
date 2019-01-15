FROM jenkins/jenkins:lts

USER root

RUN	apt-get update &&\
	apt-get install -qy git apt-utils curl dpkg jq libexpat1-dev libpython2.7-dev python2.7-dev vim &&\
	apt-get install -f -qy &&\
	rm -rf /var/lib/apt/lists/* &&\
        curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash && \
        curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash

RUN	apt-get update && \
	apt-get install -qy ruby-dev rubygems build-essential && \
	gem install conjur-cli -v 6.1.0 && \
	curl -fsSL get.docker.com -o get-docker.sh && \
	sh get-docker.sh && \
	rm get-docker.sh && \
	usermod -aG docker jenkins && \
	apt-get clean && \
	rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

USER jenkins

EXPOSE 8080 50000
