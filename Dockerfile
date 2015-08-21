# Version 1.0
FROM ubuntu:14.04
MAINTAINER Florian GAUVIN "florian.gauvin@nl.thalesgroup.com"

ENV DEBIAN_FRONTEND noninteractive

#Download all the packages needed

RUN apt-get update && apt-get install -y \
	build-essential \
	cmake \
	git \
	python \
	wget \
	unzip \
	bc\
	uuid-dev \
	language-pack-en \
	curl \
    	libjansson-dev \
    	libxml2-dev \
    	libcurl4-openssl-dev \
        && apt-get clean 

#Download and install the latest version of Docker (You need to be the same version to use this Dockerfile)

RUN wget -qO- https://get.docker.com/ | sh

#Prepare the usr directory by downloading in it : Buildroot, the configuration file of Buildroot and Apache Celix

WORKDIR /usr

RUN cd

RUN wget http://git.buildroot.net/buildroot/snapshot/buildroot-2015.05.tar.gz && \
	tar -xf buildroot-2015.05.tar.gz && \
	git clone https://github.com/florian-gauvin/Buildroot-configure.git --branch celix buildroot-configure-celix && \
	cp buildroot-configure-celix/.config buildroot-2015.05/ && \
	wget https://github.com/apache/celix/archive/develop.tar.gz && \
	tar -xf develop.tar.gz && \
	mkdir celix-build

#Create a small base of the future image with buildroot and decompress it

WORkDIR /usr/buildroot-2015.05

RUN make

WORKDIR /usr/buildroot-2015.05/output/images

RUN tar -xf rootfs.tar &&\
	rm rootfs.tar

#Install etcd

RUN cd /tmp && curl -k -L https://github.com/coreos/etcd/releases/download/v2.0.12/etcd-v2.0.12-linux-amd64.tar.gz | tar xzf - && \
cp etcd-v2.0.12-linux-amd64/etcd /usr/buildroot-2015.05/output/images/bin/ && cp etcd-v2.0.12-linux-amd64/etcdctl /usr/buildroot-2015.05/output/images/bin/

#Add the resources

ADD resources /usr/buildroot-2015.05/output/images/tmp

#Build Celix and link against the libraries in the buildroot environment. It's not a real good way to do so but it's the only one that I have found : I remove the link.txt file and replace it by a one created manually and not during the configuration, otherwise I don't have all the libraries linked against the environment in buildroot

WORKDIR /usr/celix-build

RUN cmake ../celix-develop -DWITH_APR=OFF -DCURL_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libcurl.so.4 -DZLIB_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libz.so.1 -DUUID_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libuuid.so -DBUILD_REMOTE_SERVICE_ADMIN=ON -DBUILD_RSA_DISCOVERY_ETCD=ON -DBUILD_RSA_TOPOLOGY_MANAGER=ON -DBUILD_RSA_REMOTE_SERVICE_HTTP=ON -DBUILD_SHELL=TRUE -DBUILD_SHELL_TUI=TRUE -DBUILD_REMOTE_SHELL=TRUE -DBUILD_DEPLOYMENT_ADMIN=ON -DCMAKE_INSTALL_PREFIX=/usr/buildroot-2015.05/output/images/usr && \
	rm -f /usr/celix-build/launcher/CMakeFiles/celix.dir/link.txt && \
	echo "/usr/bin/cc  -D_GNU_SOURCE -std=gnu99 -Wall  -g CMakeFiles/celix.dir/private/src/launcher.c.o  -o celix -rdynamic ../framework/libcelix_framework.so /usr/buildroot-2015.05/output/images/lib/libpthread.so.0 /usr/buildroot-2015.05/output/images/lib/libdl.so.2 /usr/buildroot-2015.05/output/images/lib/libc.so.6 /usr/buildroot-2015.05/output/images/usr/lib/libcurl.so.4 ../utils/libcelix_utils.so -lm /usr/buildroot-2015.05/output/images/usr/lib/libuuid.so /usr/buildroot-2015.05/output/images/usr/lib/libz.so.1" > /usr/celix-build/launcher/CMakeFiles/celix.dir/link.txt && \
	make all && \
	make install-all 

WORKDIR /usr

RUN git clone https://github.com/INAETICS/node-wiring-c && \
	mkdir node-wiring-c-build && \
	mkdir inaetics-install 
	 

WORKDIR node-wiring-c-build 

RUN cmake ../node-wiring-c -DCURL_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libcurl.so.4 -DZLIB_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libz.so.1 -DUUID_LIBRARY=/usr/buildroot-2015.05/output/images/usr/lib/libuuid.so -DJANSSON_INCLUDE_DIR=/usr/buildroot-2015.05/output/host/usr/x86_64-buildroot-linux-gnu/sysroot/usr/include/ -DCELIX_DIR=/usr/buildroot-2015.05/output/images/usr



