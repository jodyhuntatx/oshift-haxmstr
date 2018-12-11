FROM conjur-app-baseimage

COPY secrets.yml webapp*.sh uid_entrypoint.sh /

# setup entrypoint for default user
RUN chmod g=u /etc/passwd /*.sh /*.yml
ENTRYPOINT [ "/uid_entrypoint.sh" ]
USER 1001
