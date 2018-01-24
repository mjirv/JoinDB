require_relative 'joindb_api_methods'
require 'io/console'

DB_NAME = "joiner"
DB_HOST = "localhost"

DB_FDW_MAPPING = {
    :Postgres => "postgres_fdw",
    :MySQL => "mysql_fdw",
    :SQLServer => "sql_server_fdw"
}

class JoinDBApi
    extend JoindbApiMethods
end

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

    JoinDBApi.open_connection(DB_NAME, DB_HOST,
        username, password) if not register

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
    remote_user = gets.chomp
    print "Password: "
    remote_pass = STDIN.noecho(&:gets).chomp || ""
    puts
    print "Host: "
    remote_host = gets.chomp
    print "Port: "
    remote_port = gets.chomp
    if remote_port.length == 0
        remote_port = nil
    end
    print "DB Name: "
    remote_db_name = gets.chomp || "postgres"
    print "Schema: "
    remote_schema = gets.chomp || "public"

    # Add it
    case fdw_type
    when DB_FDW_MAPPING[:Postgres]
        JoinDBApi.add_fdw_postgres(username: username, password: password,
            db_name: DB_NAME, db_host: DB_HOST, remote_user: remote_user, 
            remote_pass: remote_pass, remote_host: remote_host, 
            remote_db_name: remote_db_name, remote_schema: remote_schema, 
            remote_port: remote_port)
    when DB_FDW_MAPPING[:MySQL]
        JoinDBApi.add_fdw_other(username: username, password: password,
            db_name: DB_NAME, db_host: DB_HOST, remote_user: remote_user, 
            remote_pass: remote_pass, remote_host: remote_host, 
            remote_db_name: remote_db_name, remote_port: remote_port,
            driver_type: "MySQL")
    when DB_FDW_MAPPING[:SQLServer]
        JoinDBApi.add_fdw_other(username: username, password: password,
        db_name: DB_NAME, db_host: DB_HOST, remote_user: remote_user, 
        remote_pass: remote_pass, remote_host: remote_host, 
        remote_db_name: remote_db_name, remote_port: remote_port,
        driver_type: "SQL Server")
    end
end

def add_csv_prompt(username, password)
    puts "Enter the filenames or paths to the CSV file"
    puts "(multiple files separated by commas):"
    files = gets.chomp.split(",")
    JoinDBApi.add_csv(files: files, username: username,
        password: password, db_name: DB_NAME)
end

def show_details_prompt(username, password, verbose=true)
    port = JoinDBApi.get_port()
    puts "~~~ Server Details ~~~"
    puts "Hostname: localhost"
    puts "Port: #{port}"
    puts "Connect via `psql -h #{DB_HOST} -U #{username}
        -d #{DB_NAME} -p #{port}`"
    puts
    # Exit if we just want to show the basics
    return if verbose == false
    puts "~~~ Connection Details ~~~"
    puts "Schemas:"
    JoinDBApi.get_schemas(username, password, DB_NAME, DB_HOST).
        each{ |res| puts res}
    puts
    puts "Foreign servers:"
    JoinDBApi.get_foreign_servers(username, password, DB_NAME, DB_HOST).
        each{|res| puts res}
    puts
    puts "Local tables:"
    JoinDBApi.get_local_tables(username, password, DB_NAME, DB_HOST).
        each{|res| puts res}
    puts
    puts "Foreign tables:"
    JoinDBApi.get_foreign_tables(username, password, DB_NAME, DB_HOST).
        each{|res| puts res}
end

