FROM fabric8/java-centos-openjdk8-jre

MAINTAINER liupeng

# user
USER root

# Overridable defaults
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_SITE ${GERRIT_HOME}/review_site
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_VERSION 2.15.5
ENV GERRIT_USER gerrit2
ENV GERRIT_INIT_ARGS ""

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser "${GERRIT_USER}"  -d  "${GERRIT_HOME}" -c "Gerrit User" -s /sbin/nologin
RUN yum install -y git openssh-clients openssl bash perl perl-CGI gitweb curl  procmail

# su-exec
ARG SU_EXEC_VERSION=0.2
ARG SU_EXEC_URL="https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz"

RUN yum install -y -q gcc make \
    && curl -sL "${SU_EXEC_URL}" | tar -C /tmp -zxf - \ 
    && make -C "/tmp/su-exec-${SU_EXEC_VERSION}" \
    && cp "/tmp/su-exec-${SU_EXEC_VERSION}/su-exec" /usr/bin \
    && rm -fr "/tmp/su-exec-${SU_EXEC_VERSION}" \
    && yum autoremove -y -q gcc make \
    && yum clean all -q \
    && rm -fr /var/cache/yum/* /tmp/yum_save*.yumtx /root/.pki

RUN mkdir /docker-entrypoint-init.d

#Download gerrit.war 国内网络环境不好, 离线下载war包
ADD gerrit.war $GERRIT_WAR
#Only for local test
#COPY gerrit-${GERRIT_VERSION}.war $GERRIT_WAR

#Download Plugins
ENV PLUGIN_VERSION=bazel-stable-2.15
ENV GERRITFORGE_URL=https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR=lastSuccessfulBuild/artifact/bazel-genfiles/plugins

#delete-project
RUN curl ${GERRITFORGE_URL}/job/plugin-delete-project-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/delete-project/delete-project.jar \
    -o ${GERRIT_HOME}/delete-project.jar

#events-log
#This plugin is required by gerrit-trigger plugin of Jenkins.
RUN curl ${GERRITFORGE_URL}/job/plugin-events-log-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar \
    -o ${GERRIT_HOME}/events-log.jar

#gitiles
RUN curl ${GERRITFORGE_URL}/job/plugin-gitiles-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/gitiles/gitiles.jar \
    -o ${GERRIT_HOME}/gitiles.jar

#oauth2 plugin
ENV GERRIT_OAUTH_VERSION 2.14.6.2

RUN curl https://github.com/davido/gerrit-oauth-provider/releases/download/v${GERRIT_OAUTH_VERSION}/gerrit-oauth-provider.jar \
    -o ${GERRIT_HOME}/gerrit-oauth-provider.jar

#importer
RUN curl ${GERRITFORGE_URL}/job/plugin-importer-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/importer/importer.jar \
    -o ${GERRIT_HOME}/importer.jar

# Ensure the entrypoint scripts are in a fixed location
COPY gerrit-entrypoint.sh /
COPY gerrit-start.sh /
RUN chmod +x /gerrit*.sh

#A directory has to be created before a volume is mounted to it.
#So gerrit user can own this directory.
RUN su-exec ${GERRIT_USER} mkdir -p $GERRIT_SITE

#Gerrit site directory is a volume, so configuration and repositories
#can be persisted and survive image upgrades.
VOLUME $GERRIT_SITE

ENTRYPOINT ["/gerrit-entrypoint.sh"]

EXPOSE 8080 29418

CMD ["/gerrit-start.sh"]
