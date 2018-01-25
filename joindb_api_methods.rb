module JoindbApiMethods
    require 'pg'
    PG_USERNAME = "docker"
    PG_PASSWORD = "docker"
    CONTAINER_NAME = "joiner"
    FILE_DIRECTORY = "/var/lib/postgresql/file_copy"

    # Return the default login info
    def get_default_login
        return { username: PG_USERNAME, password: PG_PASSWORD }
    end

    # Adds the user who will own the database
    def add_user(username:, password:, db_host:, db_name:, db_user: PG_USERNAME,
        db_pass: PG_PASSWORD)
        masterconn = PG::Connection.open(:host => db_host, :dbname => db_name,
            :user => db_user, :password => db_pass, :port => get_port())
        
        # Only make a superuser if this is the first user being created
        if dbuser == PG_USERNAME
            masterconn.exec("CREATE USER #{username} WITH SUPERUSER")
        else
            masterconn.exec("CREATE USER #{username}")
        end
        res = masterconn.exec("ALTER USER #{username} WITH password
            '#{password}'")
        
        #If successful, delete the docker user login for security
        if res
            masterconn.exec("ALTER USER #{PG_USERNAME} WITH NOLOGIN")
        else
            puts "User creation unsuccessful."
        end
    end

    # If we're connecting to a server on the host, we want to give it the
    # host IP
    def dockerize_localhost(remotehost)
        if remotehost == "localhost" or remotehost == "127.0.0.1"
            remotehost = `ifconfig | grep "docker0" -A 1 | grep "inet" |
                cut -d ":" -f 2 | cut -d " " -f 1`
        end
        return remotehost
    end

    # Adds a Postgres FDW
    def add_fdw_postgres(username:, password:, db_name:, db_host:, remote_user: '',
        remote_pass: '', remote_host:, remote_db_name: 'postgres',
        remote_schema: 'public', remote_port: 5432)
        remotehost = dockerize_localhost(remote_host)
        conn = open_connection(db_name, db_host, username, password)    
        schema_name = "#{remote_db_name}_#{remote_schema}"
        begin
            conn.transaction do |c| 
                # Create the server
                c.exec("CREATE SERVER #{schema_name}
                    FOREIGN DATA WRAPPER odbc_fdw
                    OPTIONS (
                        odbc_DRIVER 'PostgreSQL',
                        odbc_SERVERNAME '#{remote_host}',
                        odbc_PORT '#{remote_port}'
                    )")
                
                # Create the user mapping
                c.exec("CREATE USER MAPPING FOR #{user_name}
                    SERVER #{schema_name}
                    OPTIONS (
                        odbc_USERNAME '#{remote_user}',
                        odbc_PASSWORD '#{remote_pass}'
                    )")
                
                # Import the schema
                c.exec("CREATE SCHEMA #{schema_name}")
                c.exec("IMPORT FOREIGN SCHEMA #{remote_schema}
                    FROM SERVER #{schema_name}
                    INTO #{schema_name}
                    OPTIONS (
                        odbc_DATABASE '#{remote_db_name}'
                    )")
            end
        rescue StandardError
            $stderr.print "Error: #{$!}"
        end
    end

    # Adds a MySQL FDW or a SQL Server FDW depending on whether drivertype is
    # "MySQL" or "SQL Server"
    def add_fdw_other(username:, password:, db_name:, db_host:, remote_user: '',
            remote_pass: '', remote_host:, remote_db_name:, remote_port: 3306,
            driver_type:)
        remotehost = dockerize_localhost(remote_host)
        conn = open_connection(db_name, db_host, username, password)
        schema_name = "#{remote_db_name}"
        begin
            conn.transaction do |conn| 
                # Create the server
                conn.exec("CREATE SERVER #{schema_name}
                    FOREIGN DATA WRAPPER odbc_fdw
                    OPTIONS (
                        odbc_DRIVER '#{driver_type}',
                        odbc_SERVER '#{remote_host}', 
                        odbc_PORT '#{remote_port}'
                    )")
                
                # Create the user mapping
                conn.exec("CREATE USER MAPPING FOR #{username}
                    SERVER #{schema_name}
                    OPTIONS (
                        odbc_UID '#{remote_user}',
                        odbc_PWD '#{remote_pass}'
                    )")
                
                # Import the schema
                conn.exec("CREATE SCHEMA #{schema_name}")
                conn.exec("IMPORT FOREIGN SCHEMA #{schema_name}
                    FROM SERVER #{schema_name}
                    INTO #{schema_name}
                    OPTIONS (
                        odbc_DATABASE '#{schema_name}'
                    )")
            end
        rescue StandardError
            $stderr.print "Error: #{$!}"
        end
    end

    # Adds a CSV
    def add_csv(files:, username:, password:, db_name:)
        port = get_port()
        files.each do |file|
            file = file.gsub("\n","")
            puts ""
            puts "Importing #{file}"
            # Copy it to the server
            `docker cp #{file} #{CONTAINER_NAME}:#{FILE_DIRECTORY}`
            
            # Run pgfutter on the server
            puts `docker exec -it #{CONTAINER_NAME} ./pgfutter --user 
                #{username} --pw #{password} --db #{db_name} --ignore-errors 
                csv #{FILE_DIRECTORY}/#{File.basename(file)}`
        end
    end

    # Open the db connection
    def open_connection(db_name, db_host, username, password)
        return PG::Connection.open(:host => db_host, :dbname => db_name,
        :user => username, :password => password, :port => get_port())
    end

    # Gets the server's port, since with Docker you don't know what port it'll
    # be running on
    def get_port()
        return `docker ps | grep 'joiner' | sed "s/.*://g" | sed "s/->.*//g"`.
            to_i
    end

    def get_schemas(username, password, db_name, db_host)
        conn = open_connection(db_name, db_host, username, password)

        # Show the schemas
        conn.send_query("SELECT schema_name FROM information_schema.schemata")
        conn.get_result
    end

    def get_foreign_servers(username, password, db_name, db_host)
        conn = open_connection(db_name, db_host, username, password)

        # Show the servers
        conn.send_query("SELECT srvname, srvoptions FROM pg_foreign_server")
        conn.get_result
    end

    def get_local_tables(username, password, db_name, db_host)
        conn = open_connection(db_name, db_host, username, password)

        # Show the tables
        conn.send_query("SELECT schemaname, tablename FROM pg_tables WHERE 
            schemaname not in ('pg_catalog', 'information_schema') 
            ORDER BY schemaname desc;")
        conn.get_result
    end

    def get_foreign_tables(username, password, db_name, db_host)
        conn = open_connection(db_name, db_host, username, password)

        # Show the tables
        conn.send_query("SELECT ftoptions FROM pg_foreign_table")
        conn.get_result
    end
end
