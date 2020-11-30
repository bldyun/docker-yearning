ARG GO_IMAGE=golang:1.15-alpine
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

FROM ${GO_IMAGE}
WORKDIR /
COPY --from=yearning $GOPATH/src/github.com/cookieY/Yearning/yearning /
COPY docker /docker
RUN set -x \
 && sed -i "s/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g" /etc/apk/repositories \
 && chmod +x /docker/docker-entrypoint.sh \
 && apk --no-cache add bash
ENTRYPOINT /docker/docker-entrypoint.sh
EXPOSE 8080
