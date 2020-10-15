# defining base ruby image
FROM ruby:2.7.2-alpine as ruby
ENV APP_ROOT=/app \
    RUNAS_USER=app
WORKDIR ${APP_ROOT}


# installing runtime deps
FROM ruby as build
COPY Gemfile* ${APP_ROOT}/
RUN apk add --no-cache -q make g++
RUN \
    bundle config set deployment 'true' && \
    bundle install
COPY . ${APP_ROOT}/


# test
FROM build as test
RUN apk add --no-cache redis
CMD bundle exec rake test


# release
FROM ruby as release
COPY --from=build ${APP_ROOT} ${APP_ROOT}
COPY --from=build /usr/local/bundle /usr/local/bundle
RUN adduser -h ${APP_ROOT} -D ${RUNAS_USER} && \
    chown -R app:app ${APP_ROOT}
USER ${RUNAS_USER}
EXPOSE 8080
CMD bundle exec rackup -o 0.0.0.0 -p 8080
