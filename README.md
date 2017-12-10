# JoinDB
Spin up a data warehouse in under 5 minutes!

JoinDB lets you easily join across all your databases and even CSVs in minutes. No complex ETLs or integration projects required.

### Setup
1. Clone the repository onto your local machine
2. JoinDB requires Ruby and Postgres. You will need to download those if you don't have them already.
3. Make sure a Postgres server is running locally
4. Set the environment variables `$PG_DBNAME`, `$PG_USER`, and `$PG_PASS` to the default Postgres database, username, and password on your machine.
5. Run `ruby joindb_client.rb` and follow the prompts on the screen to set up your analytics database and add connections to it!

### Notes
- JoinDB currently only supports Postgres connections. I'm adding more soon!
- Best practice is to connect to your other DBs using a read-only user so that your JoinDB can't change your production DBs
- The prompt requires you to enter your default Postgres password (`$PG_PASS`) at several points, for now.
