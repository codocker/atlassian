FROM storezhang/alpine AS builder


# MySQL驱动版本，之所以需要两个，是因为MySQL8之后的SSLException的Bug
ENV JDBC_MYSQL8_VERSION 8.0.24
ENV JDBC_MYSQL5_VERSION 5.1.46

ENV JRE_VERSION 11.0.11
ENV JRE_MAJOR_VERSION 11
ENV OPENJ9_VERSION 0.26.0



WORKDIR /opt/oracle



RUN apk update
RUN apk add axel

# 安装AdoptOpenJDK，替代Oracle JDK
RUN axel --num-connections 6 --output jre${JRE_VERSION}.tar.gz --insecure "https://download.fastgit.org/AdoptOpenJDK/openjdk${JRE_MAJOR_VERSION}-binaries/releases/download/jdk-${JRE_VERSION}+9_openj9-${OPENJ9_VERSION}/OpenJDK${JRE_MAJOR_VERSION}U-jre_x64_linux_openj9_${JRE_VERSION}_9_openj9-${OPENJ9_VERSION}.tar.gz"
RUN tar -xzf jre${JRE_VERSION}.tar.gz
RUN mkdir -p /usr/lib/jvm/java-${JRE_MAJOR_VERSION}-adoptopenjdk-amd64
RUN mv jdk-${JRE_VERSION}+9-jre/* /usr/lib/jvm/java-${JRE_MAJOR_VERSION}-adoptopenjdk-amd64

# 安装MySQL驱动
# 安装MySQL8驱动
RUN mkdir -p /opt/oracle/mysql/lib
RUN axel --num-connections 6 --insecure --output=mysql${JDBC_MYSQL8_VERSION}.tar.gz "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${JDBC_MYSQL8_VERSION}.tar.gz"
RUN tar -xzf mysql${JDBC_MYSQL8_VERSION}.tar.gz
RUN mv mysql-connector-java-${JDBC_MYSQL8_VERSION}/mysql-connector-java-${JDBC_MYSQL8_VERSION}.jar /opt/oracle/mysql/lib/mysql-connector-java-${JDBC_MYSQL8_VERSION}.jar

# 安装MySQL5驱动
RUN axel --num-connections 6 --insecure --output=mysql${JDBC_MYSQL5_VERSION}.tar.gz "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${JDBC_MYSQL5_VERSION}.tar.gz"
RUN tar -xzf mysql${JDBC_MYSQL5_VERSION}.tar.gz
RUN mv mysql-connector-java-${JDBC_MYSQL5_VERSION}/mysql-connector-java-${JDBC_MYSQL5_VERSION}.jar /opt/oracle/mysql/lib/mysql-connector-java-${JDBC_MYSQL5_VERSION}.jar






# 打包真正的镜像
FROM storezhang/alpine

MAINTAINER storezhang "storezhang@gmail.com"
LABEL architecture="AMD64/x86_64" version="latest" build="2021-10-22"
LABEL Description="Atlassian公司产品基础镜像，安装了JRE执行环境以及Agent破解程序，并设置Agent执行参数"



# 复制破解文件
COPY --from=builder /opt/oracle/mysql/lib /opt/oracle/mysql/lib
COPY --from=builder /usr/lib/jvm /usr/lib/jvm
COPY docker /



RUN set -ex \
    \
    \
    \
    # 安装缺失字体
    && apk update \
    && apk --no-cache add fontconfig \
    \
    \
    \
    # 安装CURL，供健康检查调用
    && apk --no-cache add curl \
    \
    \
    \
    # 增加执行权限，自定义的keygen命令，可以用来快速破解Atlassian便宜桶
    && chmod +x /usr/bin/keygen \
    \
    \
    \
    # 清理镜像，减少无用包
    && rm -rf /var/cache/apk/*




# 设置Java安装目录
ENV JAVA_HOME /usr/lib/jvm/java-11-adoptopenjdk-amd64
ENV JAVA_OPTS ""

# 配置反向代理
ENV PROXY_SCHEME http
ENV PROXY_DOMAIN "127.0.0.1"
ENV PROXY_PORT 80

# 配置上下文路径
ENV CONTEXT_PATH ""

# Agent参数，方便调用
ENV NAME "storezhang"
ENV ORG "https://ruijc.com"
ENV EMAIL "storezhang@gmail.com"

# 设置主目录文件权限
ENV SET_PERMISSIONS true

# 数据库连接配置
ENV DB_TYPE mysql8
ENV DB_HOST "localhost"
ENV DB_PORT 3306
ENV DB_NAME "atlassian"
ENV DB_USER "atlassian"
ENV DB_PASSWORD "atlassian"



# 健康检查
HEALTHCHECK --interval=15s --timeout=5s --retries=3 CMD curl --include --fail --silent ${PROXY_SCHEME}://${PROXY_DOMAIN}:${PROXY_PORT}
