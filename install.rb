require_relative 'joindb_client_methods'
require 'io/console'

default_login = JoinDBApi.get_default_login()

puts "Welcome to Joiner!"
puts
puts "Connection details:"
show_details_prompt(default_login[:username], default_login[:password],
    verbose=false)

puts "Let's get you started!"
puts "Create your login."
login = login_prompt(register=true)
JoinDBApi.add_user(username: login[:username], password: login[:password],
    db_host: DB_HOST, db_name: DB_NAME)
