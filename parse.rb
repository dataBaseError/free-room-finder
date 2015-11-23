require_relative 'db-parser'

semester = 'fall'
#campus = 'UON'
year = 2015
short = "#{year}#{Acronyms::SEMESTER[semester]}"
test = false


parser = Parse.new(test)

# Parse other information about the courses
parser.parseSemester
parser.getFaculties(short)

# Iterate through each faculty and retrieve all the classes
#url = parser.getURL(Acronyms::CAMPUSES['ALL'], 'ENGR', Acronyms::SEMESTER['winter'], 2015)
#parser.parse('UON', 'ELEE', Acronyms::SEMESTER['winter'], 2015)

parser.parseEachFaculty(Acronyms::SEMESTER[semester], year)
#parser.parseEachSemester(campus)

=begin

           
=end