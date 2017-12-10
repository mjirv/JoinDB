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

