FROM debian:stable-slim
LABEL maintainer "Benoit Joly <benoit@benoitj.ca>"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
	openssh-server \
	git \
	git-annex \
	&& rm -rf /var/lib/apt/lists/* \
	&& sed -i "s/#?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config \
	&& sed -i "s/#?PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config \
	&& printf "AllowUsers git\n" >> /etc/ssh/sshd_config \
	&& printf "Port 22\n" >> /etc/ssh/sshd_config

COPY ./start.sh /
COPY ./git-shell-commands/* /home/git/git-shell-commands/

VOLUME /etc/ssh
VOLUME /home/git

ENV UID 1100
ENV GID 1100
ENV HOME /home/git
ENV PUBKEY_FILE ""
ENV EXT_PORT 2222
ENV TZ America/Montreal
WORKDIR $HOME

EXPOSE 22

ENTRYPOINT ["/start.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config"]

