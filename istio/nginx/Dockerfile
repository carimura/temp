FROM nginx

COPY run.sh .
RUN chmod +x run.sh
COPY nginx.conf.templ .
ENTRYPOINT [ "./run.sh" ]
