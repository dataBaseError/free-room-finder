# Free Room Finder

A implemented free room finder created in ruby. The parsing is done through a simple command line tool. Finding free rooms can be done via command line or through the web json api.

## Parsing Data

1. Install the necessary ruby gems

2. Open [db-parser.db](db-parser.rb) and modify the campus as needed.

3. Run the script

        ruby db-parser.rb

## Run the web api

1. Install the necessary ruby gems

2. Run the web app.

        ruby app.rb

### API Commands

1. Find free rooms on a campus

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

## Run command line finder

1. Open [find_room.rb](find_room.rb) and call getRooms method. *TODO* add a script for running this.
