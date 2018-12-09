# defining base ruby image
FROM ruby:alpine as ruby
ENV APP_ROOT=/app \
    RUNAS_USER=app
WORKDIR ${APP_ROOT}


# installing runtime deps
FROM ruby as runtime
COPY Gemfile* ${APP_ROOT}/
RUN apk add --no-cache -q make g++ && \
    bundle install --deployment
COPY . ${APP_ROOT}/


# test
FROM runtime as test
RUN apk add --no-cache redis
CMD redis-server --daemonize yes && bundle exec rake test


# release
FROM runtime as release
RUN adduser -h ${APP_ROOT} -D ${RUNAS_USER} && \
    chown -R app:app ${APP_ROOT}
USER ${RUNAS_USER}
EXPOSE 8080
CMD bundle exec rackup -o 0.0.0.0 -p 8080
