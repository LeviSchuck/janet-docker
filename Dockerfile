FROM alpine:3.18 as alpine-base
ENV PATH="/app/bin:$PATH"

FROM alpine-base as alpine-dev
RUN apk add --no-cache gcc musl-dev make git build-base man-pages

FROM alpine-dev as build
WORKDIR /build
ARG COMMIT=HEAD
ADD fake-gitconfig /root/.gitconfig
RUN git clone https://github.com/janet-lang/janet.git . && \
  git checkout $COMMIT && \
  git revert --no-edit 398833ebe333efa751c52d2fa0f0a940d1d9878b && \
  make PREFIX=/app -j && \
  make test && \
  make PREFIX=/app install
WORKDIR /jpm
RUN git clone --depth=1 https://github.com/janet-lang/jpm.git . && \
  PREFIX=/app /app/bin/janet bootstrap.janet

FROM alpine-dev as dev
COPY --from=build /app /app/

WORKDIR /
CMD ["ash"]

FROM alpine-base as core
COPY --from=build /app/ /app/
WORKDIR /
CMD ["janet"]
