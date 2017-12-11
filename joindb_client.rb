require './joindb_api'
DB_FDW_MAPPING = {
    :Postgres => "postgres_fdw",
    :MySQL => "mysql_fdw"
}

# Gets the user's username and password for the Analytics DB
def login_prompt
    # Get user input. What username do they want?
    puts "What username do you want to use on the Analytics DB?"
    username = gets.chomp
    
    # What password?
    puts "What password?"
    password = gets.chomp

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
    puts "Username:"
    remoteuser = gets.chomp
    puts "Password:"
    remotepass = gets.chomp
    puts "Host:"
    remotehost = gets.chomp
    puts "DB Name:"
    remotedbname = gets.chomp || "postgres"
    puts "Schema:"
    remoteschema = gets.chomp || "public"

    # Add it
    case fdw_type
    when DB_FDW_MAPPING[:Postgres]
        add_fdw_postgres(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname, remoteschema)
    when DB_FDW_MAPPING[:MySQL]
        add_fdw_mysql(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname)
    end
end

def add_csv_prompt(username, password)
    puts "Enter the filenames or paths to the CSV file"
    puts "(multiple files separated by commas):"
    files = gets.chomp.split(",")
    add_csv(files, username, password)
end

cont = true
puts "Welcome to JoinDB!"

# Have the user login
login = login_prompt
login_username = login[:username]
login_password = login[:password]

# Main loop; continue until user wants to exit
while cont == true
    puts ""
    puts "What would you like to do?"
    puts "1. Setup"
    puts "2. Add DB"
    puts "3. Add CSV"
    puts "4. Exit"
    option = gets.chomp.to_i
    puts ""

    case option
    when 1
        setup_prompt(login_username, login_password)
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
