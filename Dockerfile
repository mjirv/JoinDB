#
# example Dockerfile for https://docs.docker.com/examples/postgresql_service/
#

FROM ubuntu

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.6``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.6
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python-software-properties software-properties-common postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 mysql-client git
RUN apt-get install -y make
RUN apt-get install -y postgresql-server-dev-9.6
RUN apt-get install -y build-essential
RUN apt-get install -y libmysqlclient-dev
RUN apt-get install -y wget
RUN apt-get install -y net-tools

# Download ODBC drivers
RUN apt-get install -y unixodbc unixodbc-dev
# SQL Server
RUN apt-get install -y tdsodbc
# Postgres
RUN apt-get install odbc-postgresql
# MySQL
RUN mkdir /usr/lib/mysql-connector-odbc/
RUN  wget -c https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit.tar.gz
RUN gunzip mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit.tar.gz
RUN tar -xf  mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit.tar -C /usr/lib/mysql-connector-odbc/

# Install the drivers
# MySQL
RUN /usr/lib/mysql-connector-odbc/mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit/bin/myodbc-installer -d -a -n "MySQL" -t "DRIVER=/usr/lib/mysql-connector-odbc/mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit/lib/libmyodbc5w.so"
# Postgres
RUN /usr/lib/mysql-connector-odbc/mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit/bin/myodbc-installer -d -a -n "PostgreSQL" -t "DRIVER=/usr/lib/x86_64-linux-gnu/odbc/psqlodbcw.so"
# SQL Server
RUN /usr/lib/mysql-connector-odbc/mysql-connector-odbc-5.3.9-linux-ubuntu17.04-x86-64bit/bin/myodbc-installer -d -a -n "SQL Server" -t "DRIVER=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so"

# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Add the odbc_fdw
RUN git clone https://github.com/CartoDB/odbc_fdw.git
RUN cd odbc_fdw &&\
    sed -i "s/create_foreignscan_path(root, baserel, baserel->rows/create_foreignscan_path(root, baserel, NULL, baserel->rows/g" odbc_fdw.c &&\
    make &&\
    make install
RUN cd ..

# Add the mysql_fdw
RUN export PATH=/usr/lib/postgresql/9.6/bin/:$PATH
RUN export PATH=/usr/lib/mysql-client/bin/:$PATH
RUN git clone https://github.com/EnterpriseDB/mysql_fdw.git &&\
    cd mysql_fdw &&\
    make USE_PGXS=1 &&\
    make USE_PGXS=1 install

# Add the CSV fdw
RUN    wget -O pgfutter https://github.com/lukasmartinelli/pgfutter/releases/download/v1.1/pgfutter_linux_amd64 &&\
    chmod +x pgfutter

# Add the MongoDB fdw
RUN apt-get install -y pkg-config git-core automake autoconf libtool gcc unzip make
#RUN mkdir temp && cd temp && git clone https://github.com/mongodb/libbson.git
#RUN cd temp/libbson && ./autogen.sh
#RUN cd temp/libbson && make && make install
#RUN cd temp && git clone https://github.com/mongodb/mongo-c-driver.git
#RUN cd temp/mongo-c-driver && ./autogen.sh
#RUN cd temp/mongo-c-driver && automake && ./configure --with-libbson=system
RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
#RUN cd temp/mongo-c-driver && make clean && make && make install
RUN git clone --recursive https://github.com/EnterpriseDB/mongo_fdw.git
#RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
RUN cd mongo_fdw &&\
    sed -i "s/.\/configure/.\/configure --enable-shared/g" autogen.sh
RUN cd mongo_fdw &&\
    sed -i "s/.\/configure --enable-shared --with-libbson=auto/.\/configure --with-libbson=auto/g" autogen.sh
RUN cd mongo_fdw && ./autogen.sh --with-legacy
RUN cd mongo_fdw && sed -i "s/-D_POSIX_SOURCE/-D_POSIX_C_SOURCE=200112L/g" Makefile */Makefile
RUN cd mongo_fdw && make clean && make
RUN cd mongo_fdw && make install

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.6`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker joiner &&\
    psql -d joiner --command "CREATE EXTENSION odbc_fdw"

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.6/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf

# Add a directory to scp files to
RUN mkdir /var/lib/postgresql/file_copy/

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
ENV DOCKER_HOST_IP="ifconfig | grep -E \"([0-9]{1,3}\.){3}[0-9]{1,3}\" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1"
CMD ["/usr/lib/postgresql/9.6/bin/postgres", "-D", "/var/lib/postgresql/9.6/main", "-c", "config_file=/etc/postgresql/9.6/main/postgresql.conf"] 
