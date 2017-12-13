require './joindb_api'
require 'io/console'

DB_FDW_MAPPING = {
    :Postgres => "postgres_fdw",
    :MySQL => "mysql_fdw"
}

# Gets the user's username and password for the Analytics DB
def login_prompt
    # Get user input. What username do they want?
    puts "Please log in to your JoinDB. If this is your first time, we will create an account with the following credentials:"
    print "Username: "
    username = gets.chomp
    
    # What password?
    print "Password: "
    password = STDIN.noecho(&:gets).chomp
    puts

    #TODO: Add some validation
    return {:username => username, :password => password}
end

def setup_prompt(username, password)
    # Create the user
    add_user(username, password)

    # Create the database
    create_db(username)
end

def add_db_prompt(username, password)
    # Get DB type
    puts "What type of database?"
    counter = 1
    # Print each of the possible types
    possible_types = DB_FDW_MAPPING.keys
    possible_types.each do |db_type|
        puts "#{counter}. #{db_type}"
        counter += 1
    end
    puts "#{counter}. Cancel"
    db_type_input = gets.chomp.to_i

    # Go back if they want to cancel
    if db_type_input == counter
        return
    elsif db_type_input < 1 or db_type_input > counter
        puts "That is not a valid option. Canceling."
        return
    end

    # If all is good, get the type
    fdw_type = DB_FDW_MAPPING[possible_types[db_type_input-1]]

    # Get DB connection details
    puts "Now enter your details for the remote server:"
    print "Username: "
    remoteuser = gets.chomp
    print "Password: "
    remotepass = STDIN.noecho(&:gets).chomp
    puts
    print "Host: "
    remotehost = gets.chomp
    print "Port: "
    remoteport = gets.chomp
    if remoteport.length == 0
        remoteport = nil
    end
    print "DB Name: "
    remotedbname = gets.chomp || "postgres"
    print "Schema: "
    remoteschema = gets.chomp || "public"

    # Add it
    case fdw_type
    when DB_FDW_MAPPING[:Postgres]
        add_fdw_postgres(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname, remoteschema, remoteport)
    when DB_FDW_MAPPING[:MySQL]
        add_fdw_mysql(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname, remoteport)
    end
end

def add_csv_prompt(username, password)
    puts "Enter the filenames or paths to the CSV file"
    puts "(multiple files separated by commas):"
    files = gets.chomp.split(",")
    add_csv(files, username, password)
end

def show_details_prompt(username, password)
    puts "~~~ Server Details ~~~"
    puts "Hostname: localhost"
    puts "Port: 5432"
    puts "Connect via `psql -U #{username}`"
    puts
    puts "~~~ Connection Details ~~~"
    puts "Schemas:"
    get_schemas(username, password).each{|res| puts res}
    puts
    puts "Foreign servers:"
    get_foreign_servers(username, password).each{|res| puts res}
    puts
    puts "Local tables:"
    get_local_tables(username, password).each{|res| puts res}
    puts
    puts "Foreign tables:"
    get_foreign_tables(username, password).each{|res| puts res}
end

cont = true
puts "Welcome to JoinDB!"

# Have the user login
login = login_prompt
login_username = login[:username]
login_password = login[:password]

# Main loop; continue until user wants to exit
while cont == true
    puts
    puts "What would you like to do?"
    puts "1. Setup"
    puts "2. Add DB"
    puts "3. Add CSV"
    puts "4. Show JoinDB details"
    puts "5. Exit"
    option = gets.chomp.to_i rescue "nopenopenope"
    puts ""

    case option
    when 1
        setup_prompt(login_username, login_password)
    when 2
        add_db_prompt(login_username, login_password)
    when 3
        add_csv_prompt(login_username, login_password)
    when 4
        show_details_prompt(login_username, login_password)
    when 5
        cont = false
    else
        puts "That option is not recognized."
    end
end
