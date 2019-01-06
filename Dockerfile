FROM geerlingguy/docker-debian9-ansible:latest
LABEL maintainer="Dan Kempster"

ENV DEBIAN_FRONTEND noninteractive

ENV pip_packages "ansible"

# Install dependencies.
RUN mkdir -p /usr/lib/jvm/java-8-openjdk-armhf/jre/lib/arm \
	&& ln -s /usr/lib/jvm/java-8-openjdk-armhf/jre/lib/arm/client /usr/lib/jvm/java-8-openjdk-armhf/jre/lib/arm/server \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       software-properties-common \
       curl \
       dirmngr \
       gnupg \
       apt-transport-https \
       openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

# Install Jenkins
RUN apt-key adv --fetch-keys https://pkg.jenkins.io/debian/jenkins.io.apt-key \
    && add-apt-repository -y 'deb https://pkg.jenkins.io/debian binary/' \
    && apt-get update \
    && apt-get install -y --allow-unauthenticated --no-install-recommends jenkins \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
