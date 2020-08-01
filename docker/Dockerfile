# bluster-slim doesn't have libtcnativ-1, which we need to run CF
# So, even if we have the huge image, I would like to reduce the
# running docker image size. So, introduce the multi-stage builder pattern.
#
#

# ## BuildEnv docker image size ~ 1.3 GB
# FROM debian:buster AS builder
# ENV WorkPath /home/ChannelFinder-env
# ARG RS_SERVER_PORT=5075
# ARG RS_PORT_BROADCAST=5076
# ARG CF_PORT_HTTP=8080
# ARG CF_PORT_HTTPS=8443

# RUN apt update
# RUN apt install -y \
#         make \
# 	maven \
# 	git \
# 	openjdk-11-jdk

# WORKDIR $WorkPath
# COPY . .
# RUN echo "CF_PORT:=${CF_PORT_HTTP}" > configure/CONFIG_COMMON.local
# RUN make distclean && \
#     make init && \
#     make conf && \
#     make build && \
#     make install.docker
#     #   make build MVN_OPTS=dependency:go-offline


# ## Multi-Stages build
# ## Running docker image size ~ 0.7 GB
# FROM debian:buster
# LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"

# ARG BUILD_DATE
# ARG BUILD_VERSION
# ARG RS_SERVER_PORT=5075
# ARG RS_PORT_BROADCAST=5076
# ARG CF_PORT_HTTP=8080
# ARG CF_PORT_HTTPS=8443
# ARG TZ=America/Los_Angeles

# # Labels.
# LABEL org.label-schema.schema-version="1.0"
# LABEL org.label-schema.build-date=$BUILD_DATE
# LABEL org.label-schema.name="jeonghanlee/channelfinder"
# LABEL org.label-schema.description="EPICS ChannelFinder Docker Image"
# LABEL org.label-schema.url="https://github.com/ChannelFinder/ChannelFinder-env/"
# LABEL org.label-schema.version=$BUILD_VERSION
# LABEL org.label-schema.docker.cmd="docker run --network=host --detach --rm --name=channelfinder jeonghanlee/channelfinder:latest"


# ### RecCeiver PORT configuration.
# ### DO NOT CHANGE them
# ENV RS_SERVER_PORT ${RS_SERVER_PORT}
# ENV RS_PORT_BROADCAST ${RS_PORT_BROADCAST}
# #
# ### ChannelFinder HTTP PORT  through Tomcat <<<<---- Most likely you would like to change this
# ENV CF_PORT_HTTP ${CF_PORT_HTTP}
# #
# ### DO NOT CHANGE IT
# ENV LDAP_SERVER_PORT 8389
# #
# ### ChannelFinder HTTPS PORT through Tomcat
# ENV CF_PORT_HTTPS ${CF_PORT_HTTPS}
# #
# ### YOUR TIME ZONE
# ENV TZ ${TZ}

# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# RUN dpkg-reconfigure -f noninteractive tzdata
# RUN apt update && apt install -y openjdk-11-jre libtcnative-1

# COPY ./docker/scripts/entrypoint.sh /entrypoint.sh
# WORKDIR /opt/channelfinder
# COPY --from=builder /opt/channelfinder .
# ##
# # CF Port : http
# EXPOSE ${CF_PORT_HTTP}/tcp
# EXPOSE ${CF_PORT_HTTP}/udp
# # CF PORT : https
# EXPOSE ${CF_PORT_HTTPS}/tcp
# EXPOSE ${CF_PORT_HTTPS}/udp
# # RecCeiver Broadcast Port
# EXPOSE ${RS_PORT_BROADCAST}/udp
# # RecCeiver Server Port
# EXPOSE ${RS_SERVER_PORT}/udp
# # Embedded LDAP Port
# EXPOSE ${LDAP_SERVER_PORT}/tcp
# EXPOSE ${LDAP_SERVER_PORT}/udp
# #
# ENTRYPOINT ["/entrypoint.sh"]
