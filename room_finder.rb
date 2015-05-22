require_relative 'find_room'
require_relative 'utility'

# Example: ruby room_finder.rb UON 2015-05-15 11:00:00 3
if ARGV.size == 4
    campus, date, start_time, duration = ARGV[0], ARGV[1], ARGV[2], ARGV[3]
else
    abort("Invalid parameters")
end

results = Utility.validateFindRoom(campus, date, start_time, duration)

# Simple command line interface to allow for finding free rooms on UOIT
find_room = FindRoom.new

# TODO print them nicely
rooms = find_room.getRooms(results['campus'], results['day'], results['semester_code'], results['start_time'], results['end_time'])

puts "Rooms available on #{Acronyms::CAMPUS_ACRONYM[campus]} on #{date} from #{start_time} to #{results['end_time']}"
rooms.each do |room, times|
    puts "Room = #{room}, available from #{times['before']} - #{times['after']}"
end