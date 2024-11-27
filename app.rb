require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "rails"
  gem "pg"
end

require "active_record"
require "action_controller/railtie"

ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new("adapter" => "postgresql", "database" => "railstestdb").purge
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :books, force: true do |t|
    t.string :name
    t.timestamps
  end
end

class Book < ActiveRecord::Base
end

class TestApp < Rails::Application
  secrets.secret_token    = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
  Rails.logger = config.logger
  config.hosts.clear

  routes.draw do
    get 'book', to: 'books#show'
  end
end

class BooksController < ActionController::Base
  include Rails.application.routes.url_helpers

  def show
    @books = Book.find_by(name: search_params[:name])
    render plain: @books.count
  end

  private

  def search_params
    params.require(:search).permit(:name)
  end
end

require "minitest/autorun"

class BooksControllerTest < Minitest::Test
  include Rack::Test::Methods

  def test_indexs
    get "/book", search: { name: "\u0000" }
    assert last_response.ok?
  end

  private

  def app
    Rails.application
  end
end