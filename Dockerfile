FROM alpine:edge

ARG x=FFFF
ARG CV=asdfasdf${x}

RUN set -ex && P=java_home
RUN set -ex \
   && printf "Hello"

# RUN set -ex \
#     && printf "The complete list is %s\n "$?" \
#     && for path in \
#         ./data \
#         ./logs \
#         ./config \
#         ./config/scripts \
#     ; do \
#     mkdir -p "$path"; \
#     chown -R boot:docker "$path"; \
#    done \
#      && printf "The complete list is %s\n" "$?"   

ENV PX=$P
ENV MM=${CV}
CMD echo "hello cmd!"

