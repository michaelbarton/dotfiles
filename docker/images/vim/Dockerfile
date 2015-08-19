FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive
ENV PACKAGES python vim git locales language-pack-en
RUN apt-get update --yes && apt-get install --yes ${PACKAGES}

RUN dpkg-reconfigure locales
RUN locale-gen en_GB.UTF-8
RUN /usr/sbin/update-locale LANG=en_GB.UTF-8

ENV USER vim_user
RUN groupadd -r ${USER} && useradd --system --create-home --gid ${USER} ${USER}
ADD config /home/vim_user/.vim
ADD vimrc /home/vim_user/.vimrc
RUN chown -R ${USER}:${USER} /home/vim_user
USER ${USER}

ENV LC_ALL en_GB.UTF-8
WORKDIR /home/vim_user

RUN mkdir -p ${HOME}/.vim/bundle ${HOME}/.ssh
RUN ssh-keyscan -t rsa,dsa github.com >> ${HOME}/.ssh/known_hosts
RUN git clone https://github.com/VundleVim/Vundle.vim.git ${HOME}/.vim/bundle/vundle
RUN vim -u ~/.vim/bundles.vim +PluginInstall +qall

#ENTRYPOINT ["vim"]
#CMD []
