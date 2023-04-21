FROM debian:bookworm as build 
RUN apt update && apt install build-essential clang -y
# Oh boy
RUN rm /usr/bin/gcc && ln -s /usr/bin/clang /usr/bin/gcc

COPY . /toy
WORKDIR /toy
RUN mkdir out && CFLAGS="-fsanitize=fuzzer-no-link -std=c18" TOY_OUTDIR=out make -j8 -C source library && cp out/libtoy.so fuzz/
WORKDIR /toy/fuzz
RUN make

FROM debian:bookworm
COPY --from=build /toy/fuzz .
ENV LD_LIBRARY_PATH .
