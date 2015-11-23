
require 'sinatra'
require 'json'

require_relative 'find_room'
#require_relative 'utility'

# Example: http://localhost:4567/rooms/UON/2015-05-15/11:00:00/3

get '/rooms/:campus/:date/:start_time/:duration' do

    room_finder = FindRoom.new

    #TODO catch errors if there are any and show them rather than just letting them cause an internal server error.
    # Post the json
    room_finder.getRooms(params['campus'], params['date'], params['start_time'], params['duration']).to_json
end

# Example: http://localhost:4567/campus

get '/campus' do 

    room_finder = FindRoom.new

    room_finder.getCampus.to_json
end

# Example: http://localhost:4567/semesters

get '/semesters' do

    room_finder = FindRoom.new

    room_finder.getSemester.to_json
end

# Example: http://localhost:4567/latest_semesters
# TODO test and validate

#get '/latest_semesters' do

#    room_finder = FindRoom.new

#    room_finder.getLatest
#end
