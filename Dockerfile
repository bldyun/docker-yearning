ARG GO_IMAGE=golang:1.15-alpine
ARG NODE_IMAGE=node:12.10.0-alpine
FROM ${GO_IMAGE} as builder

RUN set -x \
 && sed -i "s/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g" /etc/apk/repositories \
 && apk --no-cache add \
    bash \
    curl \
    file \
    git \
    make
FROM builder AS yearning
ARG TAG=v2.3.0
RUN git clone --depth=1 https://gitee.com/cookieYe/Yearning.git $GOPATH/src/github.com/cookieY/Yearning
WORKDIR $GOPATH/src/github.com/cookieY/Yearning
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN GO_LDFLAGS=" " GOPROXY="http://mirrors.tencentyun.com/go/,http://mirrors.cloud.tencent.com/go/,https://goproxy.cn,direct" go build -o yearning
RUN ls *
FROM ${NODE_IMAGE} as yearning-frontend
RUN set -x \
 && sed -i "s/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g" /etc/apk/repositories \
 && apk --no-cache add \
    bash \
    curl \
    file \
    git \
    make
RUN git clone --depth=1 https://github.com/cookieY/Yearning-gemini.git /hello
WORKDIR /hello
RUN NPM_REG="http://mirrors.cloud.tencent.com/npm";NPM_REG1="http://mirrors.tencentyun.com/npm"; \
   curl ${NPM_REG1} >/dev/null 2>&1 && NPM_REG=${NPM_REG1}; echo "${NPM_REG}" | tee -a /tmp/.npm_reg
RUN  yarn  --registry $(head -n 1 /tmp/.npm_reg) \
  && yarn run build

FROM ${GO_IMAGE}
WORKDIR /
COPY --from=yearning $GOPATH/src/github.com/cookieY/Yearning/yearning /
COPY --from=yearning $GOPATH/src/github.com/cookieY/Yearning/juno   /
COPY --from=yearning-frontend /hello/dist /dist
COPY docker /docker
RUN set -x \
 && sed -i "s/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g" /etc/apk/repositories \
 && chmod +x /docker/docker-entrypoint.sh juno \
 && apk --no-cache add bash
ENTRYPOINT /docker/docker-entrypoint.sh
EXPOSE 8080
