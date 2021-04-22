FROM ubuntu AS builder


# 版本
ENV JDBC_MARIADB_VERSION 8.0.23



WORKDIR /opt/oracle



RUN apt update && apt install -y axel
# 安装JDBC
RUN axel --num-connections 64 --insecure "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${JDBC_MARIADB_VERSION}.tar.gz"
RUN tar -xzvf mysql-connector-java-${JDBC_MARIADB_VERSION}.tar.gz && mkdir -p /opt/oracle/mariadb/lib && mv mysql-connector-java-${JDBC_MARIADB_VERSION}/mysql-connector-java-${JDBC_MARIADB_VERSION}.jar /opt/oracle/mariadb/lib/mysql-connector-java-${JDBC_MARIADB_VERSION}.jar




# 打包真正的镜像
FROM storezhang/ubuntu


MAINTAINER storezhang "storezhang@gmail.com"
LABEL architecture="AMD64/x86_64" version="latest" build="2021-04-13"
LABEL Description="Atlassian公司产品基础镜像，安装了JRE执行环境以及Agent破解程序，并设置Agent执行参数。"



# 设置Atlassian Agent
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
ENV JAVA_OPTS -javaagent:/opt/atlassian/agent/agent.jar

# 配置反向代理
ENV PROXY_SCHEME https
ENV PROXY_DOMAIN ""
ENV PROXY_PORT 443

# 配置上下文路径
ENV CONTEXT_PATH ""

# Agent参数，方便调用
ENV NAME ""
ENV ORG ""
ENV EMAIL ""



# 复制破解文件
COPY --from=builder /opt/oracle/mariadb/lib /opt/oracle/mariadb/lib
COPY docker /



RUN set -ex \
    \
    \
    \
    # 安装Atlassian公司全家桶的Java执行环境
    && apt update -y --fix-missing \
    && apt upgrade -y \
    && apt install -y openjdk-11-jre \
    \
    \
    \
    # 增加执行权限，自定义的keygen命令，可以用来快速破解Atlassian便宜桶
    && chmod +x /usr/bin/keygen \
    \
    \
    \
    # 清理镜像，减少无用包
    && rm -rf /var/lib/apt/lists/* \
    && apt autoclean
