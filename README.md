# Free Room Finder

A implemented free room finder created in ruby. The parsing is done through a simple command line tool. Finding free rooms can be done via command line or through the web json api.

## Datebase setup

1. Install postgresql 9.4 (note if you have previous version ensure that you are using 9.4), for debian https://wiki.postgresql.org/wiki/Apt


2. Find the port 9.4 is running on and use that port to create and insert the schema
        sudo service postgresql status
        sudo -u postgres createdb -p<port> free-room-finder
        sudo -u postgres psql -p<port> free-room-finder < database.sql

## Parsing Data

1. Install the necessary ruby gems
    apt-get install ruby-dev
    apt-get install postgreql
    apt-get install libpq-dev

    gem install mechanize
    gem install nokogiri
    gem install json
    gem install pg

2. Open [parse.db](parse.rb) and modify the campus as needed. It is currently set to grab all data for every semester for the north campus.

3. Run the script

        ruby parse.rb

## Run the web api

1. Install the necessary ruby gems
    gem install sinatra

2. Configure the server (if running on a server)

        set :bind, '0.0.0.0'
        set :port, '94294'

3. Run the web app.

        ruby app.rb

### API Commands

* Find free rooms on a campus

        get '/rooms/:campus/:date/:start_time/:duration'

    campus
    - UON - North Oshawa Campus
    - UOD - Downtown Oshawa Campus
    - UOG - Georgian Campus
 
    date
    - Formated date, YYYY-MM-DD (e.g. 2015-05-14)

    start_time
    - Formated time, HH-MM-SS (e.g. 13:10:00)

    duration
    - Number of hours the event will last for (e.g. 3 would be for a 3 hours event)

* Find all the available campuses

        get '/campus'

* Find all the available semesters

        get '/semesters'


## Run command line finder

1. Open [find_room.rb](find_room.rb) and call getRooms method. *TODO* add a script for running this.
