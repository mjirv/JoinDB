require_relative 'joindb_api'
require 'io/console'

DB_FDW_MAPPING = {
    :Postgres => "postgres_fdw",
    :MySQL => "mysql_fdw"
}

# Gets the user's username and password for the Analytics DB
def login_prompt(register=false)
    # Get user input. What username do they want?
    print "Username: "
    username = gets.chomp
    
    # What password?
    verify = ""
    password = ""
    while (verify != password or password == "") 
        print "Password: "
        password = STDIN.noecho(&:gets).chomp
        puts
        if register
            print "Verify password: "
            verify = STDIN.noecho(&:gets).chomp
            puts
            puts "Passwords do not match." if verify != password
        else
            verify = password
        end
        puts "Password cannot be blank." if password == ""
    end

    return {:username => username, :password => password}
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
    puts "Now enter your details for the database you want to add:"
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

def show_details_prompt(username, password, verbose=true)
    port = get_port()
    puts "~~~ Server Details ~~~"
    puts "Hostname: localhost"
    puts "Port: #{port}"
    puts "Connect via `psql -h #{DB_HOST} -U #{username} -d #{DB_NAME} -p #{port}`"
    puts
    # Exit if we just want to show the basics
    return if verbose == false
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

