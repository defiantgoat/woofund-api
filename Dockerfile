FROM ruby:2.7.3

# docker build -t woohoofund/api -f Dockerfile .

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

RUN gem update --system && gem install bundler && bundle --version

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["/bin/bash", "-c", "bundle exec ruby start_rackup.rb"]