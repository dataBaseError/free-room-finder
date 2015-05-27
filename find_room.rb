
require_relative 'db-interface'

class FindRoom

    OPENING_TIME = '8:00:00'
    CLOSING_TIME = '23:00:00'

    def initialize(test=false)
        @db = DBinterface.new("free_room_finder")
    end

    def getRooms(campus, date, start_time, duration)
        @db.get_available_classes(campus, date, start_time, duration)
    end

end