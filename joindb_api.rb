require 'pg'
DB_NAME = "analytics_db"
PG_DBNAME   = ENV['PG_DBNAME']
PG_USERNAME = ENV['PG_USER']
PG_PASSWORD = ENV['PG_PASS']

# Creates a new DB based on the name parameter
def create_db(name, username)
    puts "createdb -U postgres -O #{username} #{name}"
    return `createdb -U postgres -O #{username} #{name}`
end

# Adds the user who will own the database
def add_user(username, password)
    create_user = `createuser -U postgres #{username}`
    masterconn = PG::Connection.open(:dbname => PG_DBNAME, :user => PG_USER, :password => PG_PASSWORD)
    masterconn.exec("ALTER USER #{username} WITH password '#{password}'")
    masterconn.exec("ALTER USER #{username} SUPERUSER")
end

# Adds a Postgres FDW
def add_postgres(conn, username, remoteuser, remotepass, remotehost, remotedbname, remoteschema)
    schema_name = "#{remotedbname}_#{remoteschema}"                
    conn.exec("CREATE EXTENSION postgres_fdw") rescue nil
    conn.exec("CREATE SERVER #{schema_name}
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host '#{remotehost}', dbname '#{remotedbname}')")
    conn.exec("CREATE USER MAPPING FOR #{username}
        SERVER #{schema_name}
        OPTIONS (user '#{remoteuser}', password '#{remotepass}')")
    # Import the schema
    conn.exec("CREATE SCHEMA #{schema_name}")
    conn.exec("IMPORT FOREIGN SCHEMA #{remoteschema}
        FROM SERVER #{schema_name}
        INTO #{schema_name}")
end

# Adds a MySQL FDW
def add_mysql(conn)
end

# Adds a CSV FDW
def add_csv(conn)

end

# Adds a MongoDB FDW
def add_mongodb(conn)
end

# Adds a generic FDW
def add_generic(conn)
end

# Open the db connection
def open_connection(db_name, username, password)
    conn = PG::Connection.open(:dbname => db_name, :user => username, :password => password)
end

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
    files.each do |file|
        puts `pgfutter_windows_386.exe --user #{username} --pw #{password} --db #{DB_NAME} csv #{file}`
        puts "- #{file} added to schema import."
    end
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
