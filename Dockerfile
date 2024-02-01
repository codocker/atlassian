FROM haxqer/jira:9.12.2 AS jira
FROM ccr.ccs.tencentyun.com/storezhang/ubuntu:23.04.17 AS builder

# 复制所需要的文件
COPY --from=jira /var/agent /docker/opt/atlassian/agent
COPY --from=jira /usr/local/openjdk-11 /docker/opt/oracle/openjdk
# ! 必须在最后一步复制需要做出修改的文件，不然文件内容会被覆盖
COPY docker /docker



# 打包真正的镜像
FROM ccr.ccs.tencentyun.com/storezhang/ubuntu:23.04.17


LABEL author="storezhang<华寅>" \
    email="storezhang@gmail.com" \
    qq="160290688" \
    wechat="storezhang" \
    description="Atlassian公司产品基础镜像，安装了JRE执行环境以及Agent破解程序，并设置Agent执行参数"


# 复制文件
COPY --from=builder /docker /


RUN set -ex \
    \
    \
    \
    # 安装缺失字体
    && apt update -y \
    && apt upgrade -y \
    && apt install fontconfig -y \
    \
    \
    \
    # 安装健康检查依赖命令
    && apt install curl -y \
    # 增加破解命令 \
    && chmod +x /usr/local/bin/crack \
    \
    \
    \
    # 清理镜像，减少无用包
    && rm -rf /var/lib/apt/lists/* \
    && apt autoclean


# 配置运行时环境变量
ENV JAVA_HOME /opt/oracle/openjdk
# 设置破解程序
ENV JAVA_OPTS "-javaagent:/opt/atlassian/agent/atlassian-agent.jar -Djira.downgrade.allowed=true ${JAVA_OPTS}"

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

# 日志清理
ENV LOG_EXPIRED_DAYS 30


# 健康检查
HEALTHCHECK --interval=15s --timeout=5s --retries=10 --start-period=1m CMD curl --include --fail --silent ${PROXY_SCHEME}://${PROXY_DOMAIN}:${PROXY_PORT} || exit 1
