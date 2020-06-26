FROM courtapi/courtio-yaml-include:v0.07

RUN cpanm install --notest Carton \
  && rm -rf $HOME/.cpanm

WORKDIR /app

ENV PERL5LIB /app/local/lib/perl5:/app/lib

COPY cpanfile .
RUN carton install \
  && rm -rf $HOME/.cpanm local/cache cpanfile.snapshot

ADD lib /app/lib
RUN chmod -R a+rX /app/lib

ADD bin /app/bin
RUN chmod -R a+rX /app/bin

ENTRYPOINT ["/app/bin/pod-to-openapi"]
