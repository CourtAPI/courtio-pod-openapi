FROM perl:5.30

RUN cpanm install --notest Carton \
  && rm -rf $HOME/.cpanm

WORKDIR /app

ENV PERL5LIB /app/local/lib/perl5:/app/lib

# install CourtIO::YAML::Include
COPY vendor/courtio-yaml-include/cpanfile .
RUN carton install \
  && rm -rf $HOME/.cpanm local/cache cpanfile.snapshot \
  && rm -f cpanfile
ADD vendor/courtio-yaml-include/lib /app/lib

COPY cpanfile .
RUN carton install \
  && rm -rf $HOME/.cpanm local/cache cpanfile.snapshot

ADD lib /app/lib
RUN chmod -R a+rX /app/lib

ADD bin /app/bin
RUN chmod -R a+rX /app/bin

ENTRYPOINT ["/app/bin/pod-to-openapi"]
