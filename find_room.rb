
require_relative 'db-interface'

class FindRoom

    OPENING_TIME = '8:00:00'
    CLOSING_TIME = '23:00:00'

    def initialize(test=false)
        @db = DBinterface.new("free_room_finder")
    end

    def find_before(room, end_time)
        # First room to have this is the closest before
        if room['end_time'] < end_time
            return true
        end
        return nil
    end

    def find_after(room, start_time)
        # First room to have this is the closest after
        if room['start_time'] > start_time
            return true
        end
        return nil
    end

    def getRooms(campus, day, semester_code, start_time, end_time)
        possible_rooms = @db.get_available_classes(campus, day, semester_code, start_time, end_time)

        range = find_range(possible_rooms, start_time, end_time)
        print_range(range)
    end


    # Find out when the previous class end and the next class starts to find out how long the class is really available for.
    # Alteratively the possible rooms could be returned right now (without start/end times and removing duplicate rooms).
    def find_range(possible_rooms, start_time, end_time)
        if possible_rooms

            range = Hash.new

            possible_rooms.each do |room|

                if range[room['room']] == nil
                    range[room['room']] = Hash.new
                end

                #if range[room['room']]['before'] == nil
                if find_before(room, end_time)
                    range[room['room']]['before'] = room['end_time']
                end
                #end
                if range[room['room']]['after'] == nil
                    if find_after(room, start_time)
                        range[room['room']]['after'] = room['start_time']
                    end
                end
            end
            return range
        end
        return nil
    end

    # Fill in the missing values were no class precede the desired start time or no class follows the desired end time.
    def print_range(range)
        #rooms = range.keys
        range.each do |room, times|

            if times['before'] == nil
                times['before'] = OPENING_TIME
            end
            if times['after'] == nil
                times['after'] = CLOSING_TIME
            end
            
        end
        return range
    end

    private :find_before, :find_after
end

=begin
campus = 'UON'
day = 'T'
semester_code = '201505'
start_time = '13:00:00'
end_time = '15:30:00'

#db = DBinterface.new("free_room_finder")
find_room = FindRoom.new

puts find_room.getRooms(campus, day, semester_code, start_time, end_time)
=end

#range = find_range(possible_rooms, start_time, end_time)
#puts print_range(range)