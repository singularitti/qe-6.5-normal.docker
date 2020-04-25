# Referenced from https://github.com/rinnocente/qe-full-6.2.1/blob/master/Dockerfile
FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

ENV QE_HD="/home/qe" \
    QE_VER="-6.5"

RUN adduser qe \
    && usermod -aG sudo qe \
	&& echo export PATH=/home/qe/qe"${QE_VER}"/bin:"${PATH}" >>/home/qe/.bashrc

RUN \
    apt-get update -y  && \
    apt-get upgrade -y && \
    apt-get install -y cpio wget make git gcc g++ python ssh autotools-dev autoconf automake texinfo libtool patch flex && \
    apt-get -qq autoclean && apt-get -qq autoremove

RUN apt-get update && apt-get -qq upgrade -y && apt-get install -y -q \
    zsh openmpi-bin openmpi-doc libopenmpi-dev libblas-dev liblapack-dev libscalapack-openmpi-dev vim

WORKDIR "$QE_HD"

# we create the user 'qe' and add it to the list of sudoers
RUN \
    wget https://github.com/QEF/q-e/releases/download/qe"${QE_VER}"/qe"${QE_VER}"-ReleasePack.tgz \
    && tar xzf qe"${QE_VER}"-ReleasePack.tgz

RUN (cd qe"${QE_VER}" || exit; \
    ./configure -enable-openmp -with-internal-blas -with-internal-lapack -with-scalapack; \
    make all)

RUN	mkdir -p downloads \
    && mv qe"${QE_VER}"-ReleasePack.tgz downloads/

RUN chown -R qe:qe "${QE_HD}"

RUN	apt-get install -yq libxext-dev

USER qe

SHELL ["/usr/bin/zsh", "-c"]

RUN cd ~/ && zsh && \
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" && \
    setopt EXTENDED_GLOB && \
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"; done

RUN echo export PATH=/home/qe/qe"${QE_VER}"/bin:"${PATH}" >>/home/qe/.zshrc

CMD ["sudo","sshd","-D"]
