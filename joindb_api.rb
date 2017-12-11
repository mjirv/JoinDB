require 'pg'
DB_NAME = "analytics_db"
PG_DBNAME   = ENV['PG_DBNAME']
PG_USERNAME = ENV['PG_USERNAME']
PG_PASSWORD = ENV['PG_PASSWORD']

# Creates a new DB based on the name parameter
def create_db(username)
    puts "createdb -U postgres -O #{username} #{DB_NAME}"
    return `createdb -U postgres -O #{username} #{DB_NAME}`
end

# Adds the user who will own the database
def add_user(username, password)
    create_user = `createuser -U postgres #{username}`
    masterconn = PG::Connection.open(:dbname => PG_DBNAME, :user => PG_USERNAME, :password => PG_PASSWORD)
    masterconn.exec("ALTER USER #{username} WITH password '#{password}'")
    masterconn.exec("ALTER USER #{username} SUPERUSER")
end

# Adds a Postgres FDW
def add_fdw_postgres(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname, remoteschema)
    conn = open_connection(DB_NAME, username, password)    
    schema_name = "#{remotedbname}_#{remoteschema}"                
    conn.transaction{|conn| conn.exec("CREATE EXTENSION #{fdw_type}")}
    conn.transaction{|conn| conn.exec("CREATE SERVER #{schema_name}
        FOREIGN DATA WRAPPER #{fdw_type}
        OPTIONS (host '#{remotehost}', dbname '#{remotedbname}')")}
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
def add_fdw_mysql(fdw_type, username, password, remoteuser, remotepass, remotehost, remotedbname)
    conn = open_connection(DB_NAME, username, password)
    schema_name = "#{remotedbname}"
    begin
        conn.exec("CREATE EXTENSION #{fdw_type}")
        conn.transaction{|conn| conn.exec("CREATE SERVER #{schema_name}
            FOREIGN DATA WRAPPER #{fdw_type}
            OPTIONS (host '#{remotehost}')")}
        conn.transaction{|conn| conn.exec ("CREATE USER MAPPING FOR #{username}
            SERVER #{schema_name}
            OPTIONS (username '#{remoteuser}', password '#{remotepass}')")}
        # Import the schema
        conn.transaction{|conn| conn.exec("CREATE SCHEMA #{schema_name}")}
        conn.transaction{|conn| conn.exec("IMPORT FOREIGN SCHEMA #{schema_name}
            FROM SERVER #{schema_name}
            INTO #{schema_name}")}
    rescue StandardError
        $stderr.print "Error: #{$!}"
    end
end

# Adds a CSV FDW
def add_csv(files, username, password)
    files.each do |file|
        puts ""
        puts "Importing #{file}"
        puts `pgfutter_windows_386.exe --user #{username} --pw #{password} --db #{DB_NAME} --ignore-errors csv #{file}`
    end
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

