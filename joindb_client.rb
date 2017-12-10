require './joindb_api'

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

def setup_prompt
    # Create the user
    add_user(username, password)

    # Create the database
    create_db(DB_NAME, username)

    # Open the db connection
    conn = open_connection(DB_NAME, username, password)
end

def add_db_prompt(username, password)
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
    conn = open_connection(DB_NAME, username, password)
    add_postgres(conn, username, remoteuser, remotepass, remotehost, remotedbname, remoteschema)
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
        setup_prompt
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
