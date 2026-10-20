
FROM nginx:stable-alpine

ARG BUILD_NUMBER=local

COPY index.html /usr/share/nginx/html/index.html

RUN sed -i "s/__BUILD_NUMBER__/${BUILD_NUMBER}/g" /usr/share/nginx/html/index.html

EXPOSE 80
