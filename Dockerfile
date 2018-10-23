FROM ruby:alpine
ENV APP_ROOT=/app
WORKDIR ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/
RUN bundle install --deployment
COPY . ${APP_ROOT}/
EXPOSE 8080
CMD bundle exec ruby ./main.rb -p 8080 -o 0.0.0.0
