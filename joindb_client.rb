require_relative 'joindb_client_methods'
require 'io/console'

cont = true
puts "Welcome to JoinDB!"

# Have the user login
testconn = "error"
while testconn == "error"
    login = login_prompt
    login_username = login[:username]
    login_password = login[:password]

    testconn = JoinDBApi.open_connection(DB_NAME, DB_HOST, login_username,
        login_password) #rescue "error"
end

# Main loop; continue until user wants to exit
while cont == true
    puts
    puts "What would you like to do?"
    puts "1. Show Joiner connection info"
    puts "2. Add DB"
    puts "3. Add CSV"
    puts "4. Exit"
    option = gets.chomp.to_i rescue "nopenopenope"
    puts ""

    case option
    when 1 
        show_details_prompt(login_username, login_password)
    when 2
        add_db_prompt(login_username, login_password)
    when 3
        add_csv_prompt(login_username, login_password)
    when 4
        cont = false
    else
        puts "That option is not recognized."
    end
end
