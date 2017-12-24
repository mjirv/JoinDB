# Joiner
Spin up a data warehouse in under 5 minutes!

Joiner lets you easily join across all your databases and even CSVs in minutes. No complex ETLs or integration projects required.

### Setup
1. Clone the repository onto your local machine
2. Joiner requires Ruby and Docker. You will need to download those if you don't have them already.
#### Start the server
3. After downloading Docker, pull the Docker image with `docker pull mjirv/joiner`
4. Run the docker image with `docker run -P --name joiner mjirv/joiner`
5. If you want to allow connections from other computers, note the port it's running on (using `docker ps`) and make sure it's open
#### Use the client
6. Run `ruby joindb_client.rb` and follow the prompts on the screen to set up your analytics database and add connections to it!

### Notes
- Joiner currently only supports PostgreSQL and MySQL connections plus CSV imports. I'm adding more soon!
- Best practice is to connect to your other DBs using a read-only user so that your Joiner can't change your production DBs
