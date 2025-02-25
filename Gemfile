# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.5"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.1.6.1"

# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"

# Use Puma as the app server
gem "puma", "~> 5.6"

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem "webpacker"

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Data integration with BigQuery
gem "google-cloud-bigquery"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

# Manage multiple processes i.e. web server and webpack
gem "foreman"

# Canonical meta tag
gem "canonical-rails"

# Soft delete records
gem "discard", "~> 1.2"

# Sentry
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"

# Logging
gem "amazing_print", "~> 1.4"
gem "rails_semantic_logger", "4.10.0"

# Thread-safe global state
gem "request_store", "~> 1.5"

# Used to build our forms and style them using govuk-frontend class names
gem "govuk-components", "~> 3.0"
gem "govuk_design_system_formbuilder"

# Background job processor
gem "sidekiq", "~> 6.5"
gem "sidekiq-cron", "~> 1.7"

# UK postcode parsing and validation for Ruby
gem "uk_postcode"

gem "config", "~> 4.0"

gem "httparty", "~> 0.20"

# Wrap jsonb columns with activemodel-like classes
gem "store_model", "~> 1.0"

gem "pundit"

# DfE Sign-in
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"

# Full text search
gem "pg_search", "~> 2.3"

gem "slack-notifier"

# Tracking changes to models
gem "audited", "~> 5.0"

# Trainee state and transitions
gem "stateful_enum"

# Pagination
gem "kaminari"

gem "activerecord-session_store"

# End-user application performance monitoring
gem "skylight"

# Run data migrations alongside schema migrations
gem "data_migrate"

# Gov Notify
gem "govuk_notify_rails"

gem "blazer"

gem "auto_strip_attributes"

# Markdown
gem "redcarpet"

gem "mechanize" # interact with HESA

# pinned to a commit as v1 doesn't contain the Doctor of Philosophy disambiguation
gem "dfe-reference-data", require: "dfe/reference_data", github: "DFE-Digital/dfe-reference-data", ref: "9ed4450"

# for sending analytics data to the analytics platform
gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.3.0"

group :qa, :review, :staging, :production do
  # Pull list of CloudFront proxies so request.remote_ip returns the correct IP.
  gem "cloudfront-rails"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]

  gem "erb_lint", require: false
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "scss_lint-govuk"

  # Debugging
  gem "debug"
  gem "pry-byebug"

  # Better use of test helpers such as save_and_open_page/screenshot
  gem "launchy"

  # Testing framework
  gem "rspec-rails", "~> 5.1.2"

  gem "rails-controller-testing"

  # Adds support for Capybara system testing and selenium driver
  gem "capybara", "~> 3.37"

  gem "dotenv-rails"

  gem "timecop", "~> 0.9.5"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "listen", ">= 3.0.5", "< 3.8"
  gem "web-console", ">= 3.3.0"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-commands-rspec", "~> 1.0"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  # Headless browser testing kit
  gem "cuprite", "~> 0.13"
  gem "webdrivers", "~> 5.0"

  gem "shoulda-matchers", "~> 5.1"
  # Code coverage reporter
  gem "simplecov", "~> 0.21.2", require: false

  # Page objects
  gem "site_prism", "~> 3.7"

  gem "webmock"
end

# Required for example_data so needed in review, qa and pen too
group :development, :test, :review, :qa, :audit do
  gem "bundle-audit", require: false
  gem "factory_bot_rails"
  gem "faker"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
