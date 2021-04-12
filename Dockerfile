FROM ubuntu AS builder


# 版本
ENV AGENT_VERSION 1.2.3


WORKDIR /opt/atlassian



RUN apt update && apt install -y axel
# 安装Agent（破解程序）
RUN axel --num-connections 64 --insecure "https://gitee.com/pengzhile/atlassian-agent/attach_files/283101/download/atlassian-agent-v${AGENT_VERSION}.tar.gz"
RUN tar -xzvf atlassian-agent-v${AGENT_VERSION}.tar.gz && mkdir -p /opt/atlassian/agent && mv atlassian-agent-v${AGENT_VERSION}/atlassian-agent.jar /opt/atlassian/agent/agent.jar




# 打包真正的镜像
FROM storezhang/ubuntu


MAINTAINER storezhang "storezhang@gmail.com"
LABEL architecture="AMD64/x86_64" version="latest" build="2021-04-12"
LABEL Description="Atlassian公司产品基础镜像，安装了JRE执行环境以及Agent破解程序，并设置Agent执行参数。"



# 设置Java Agent
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
ENV JAVA_OPTS -javaagent:/opt/atlassian/agent/agent.jar



# 复制破解文件
COPY --from=builder /opt/atlassian/agent /opt/atlassian/agent



RUN set -ex \
    \
    \
    \
    # 安装JRE，确保可以启动应用
    && apt update -y --fix-missing \
    && apt upgrade -y \
    \
    \
    \
    # 安装守护进程，因为要Xvfb和Nuwa同时运行
    && apt install -y openjdk-11-jre \
    \
    \
    \
    # 清理镜像，减少无用包
    && rm -rf /var/lib/apt/lists/* \
    && apt autoclean
