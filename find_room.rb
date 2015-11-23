
require_relative 'db-interface'

require_relative 'utility'
require_relative 'db-parser'

class FindRoom

    OPENING_TIME = '8:00:00'
    CLOSING_TIME = '23:00:00'

    def initialize(test=false)
        @db = DBinterface.new("free_room_finder")
    end

    def getRooms(campus, date, start_time, duration)
        @db.get_available_classes(campus, date, start_time, duration)
    end

    def getCampus
        @db.get_entries('campus', ['campus_acr', 'campus_name'])
    end

    def getSemester
        @db.get_entries('semesters', ['semester', 'year', 'semester_code'])
    end

    # This only works if we assume that if a semester_code is in the database then it is parsed.
    # Easiest way is to parse all the data (for past years and up to the latest available) during setup.
    # This can then be used to grab the latest data.
    # *Note* this does not require previous semesters to be parsed however it will not be able to parse previous semesters
    def getLatest
        # Get the latest semesters code
        year = Time.now
        code = get_semester(year)
        year = year.year

        # Check if the latest code is already in the database.
        if @db.get_id_existing('semesters', {'semester_code' => code}) == nil
            # Already parsed nothing to do
            return ''
        end

        # Attempt to parse the current data.
        parser = Parse.new(false)

        # Parse other information about the courses
        parser.parseSemester
        parser.getFaculties(short)

        # Iterate through each faculty and retrieve all the classes
        parser.parseEachFaculty(Acronyms::SEMESTER[semester], year)
    end
end