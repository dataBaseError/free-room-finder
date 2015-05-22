
require 'sinatra'
require 'json'

require_relative 'find_room'
require_relative 'utility'

# Example: http://localhost:4567/rooms/UON/2015-05-15/11:00:00/3

get '/rooms/:campus/:date/:start_time/:duration' do

    results = Utility.validateFindRoom(params['campus'], params['date'], params['start_time'], params['duration'])

    room_finder = FindRoom.new

    #TODO catch errors if there are any and show them rather than just letting them cause an internal server error.
    # Post the json
    room_finder.getRooms(results['campus'], results['day'], results['semester_code'], results['start_time'], results['end_time']).to_json
    #results
end