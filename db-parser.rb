require 'rubygems'
require 'bundler/setup'

require 'mechanize'
#require 'json'

require 'nokogiri'
require 'open-uri'

require_relative 'db-interface'
require_relative 'acronyms'

require_relative 'progress/progress'

# Define the compact function to remove all nil entries
class Hash
  def compact
    delete_if { |k, v| v.nil? }
  end
end

class Parse

    def initialize(test=false)
        @db = DBinterface.new("free_room_finder")
        @test = test
    end

    #https://ssbp.mycampus.ca/prod/bwckschd.p_disp_dyn_sched?TRM=UA2240
    #https://ssbprod.aac.mycampus.ca/prod/bwckschd.p_disp_dyn_sched?TRM=U
    #https://ssbp.mycampus.ca/prod/bwckschd.p_get_crse_unsec?TRM=U&begin_ap=a&begin_hh=0&begin_mi=0&end_ap=a&end_hh=0&end_mi=0&sel_attr=dummy&sel_camp=%25&sel_crse=&sel_day=dummy&sel_from_cred=&sel_insm=dummy&sel_instr=dummy&sel_levl=dummy&sel_ptrm=dummy&sel_schd=dummy&sel_sess=dummy&sel_subj=dummy&sel_subj=ENGR&sel_title=&sel_to_cred=&term_in=201501
    def getURL(campus, faculty, semester, year)
        # A function which returns a url to get the course schedule based on the
        # campus and faculty.

        url = 'https://ssbp.mycampus.ca/prod/bwckschd.p_get_crse_unsec'
        url += '?TRM=U&begin_ap=a&begin_hh=0&begin_mi=0&end_ap=a&end_hh=0&end_mi=0&sel_attr=dummy'
        url += campus
        url += '&sel_crse=&sel_day=dummy&sel_from_cred=&sel_insm=dummy&sel_instr=dummy&sel_levl=dummy&sel_ptrm=dummy'
        url += '&sel_schd=dummy&sel_sess=dummy&sel_subj=dummy&sel_subj='
        url += faculty
        url += '&sel_title=&sel_to_cred=&term_in='
        url += year.to_s
        url += semester
        return url
    end

    def parse(campus, faculty, semester, year)

        url = getURL(Acronyms::CAMPUSES[campus], faculty, semester, year)

        # Get the semester and faculty id for later use.
        campus_id = @db.get_id_existing('campus', {'campus_acr' => campus.upcase})
        semester_id = @db.get_id_existing('semesters', {'semester_code' => "#{year}#{semester}"})
        faculty_id = @db.get_id_existing('faculties', {'faculty_code' => faculty})

        if @test
            puts "Campus_id = #{campus_id}, semester_id = #{semester_id}, faculty_id = #{faculty_id}"
        end

        if campus_id == nil || semester_id == nil || faculty_id == nil
            puts "Campus, Semester or Faculty not found, call parseSemester and getFaculties for the given semester"
            return false
        end

        parsed_html = Nokogiri::HTML(open(url))

        course_headers = parsed_html.css('body div div[class="pagebodydiv"] table th[class="ddheader"]')

        # Get all of the classes.
        parsed_html.css('tr:not([align="left"]):not([colspan="16"]) td[class^="dddefault"]:not([colspan="16"])').each_with_index do |node, i|

            # get the information about the course
            title_info = parseCourse(course_headers[i])

            # TODO This is inaccurate and needs to be fixed
            level = 'undergrade'#node.children[10].text.rstrip

            course_search = {'course_name' => title_info['name']}
            code = title_info['course_code'].split(/ /)[-1]
            course_hash = {'course_name' => title_info['name'], 'course_code' => code, 'level' => level, 'faculties_id' => faculty_id}
            
            if @test
                puts "course = #{course_hash}"
            end
            
            course_id = @db.insert_nonexist('courses', course_search, course_hash)

            course_row = Array.new
            #puts "course_info = #{node}"
            course_info = node.css("tr:nth-of-type(n+2)")


            # The number of people that can fit into the room
            capacity = parseCapacity(course_info[0])

            # Get the information
            i = 1
            while course_info[i] != nil
                course_row << parseRow(course_info[i])
                i += 1
            end
            
            # For each row of course information we'll insert the necessary information 
            course_row.each do |course|

                # First part is storing the room information
                # Try and extract the rooms short form name (e.g. 'UA2240' rather than 'University Building A1 UA2240')
                room_name = ""
                regex_result = course["where"].scan(ROOM_REGEX)
                if regex_result && regex_result[0]
                    # Extract the short formed name
                    room_name = regex_result[0][0]
                else
                    # Regex didnt work just default it to the full text
                    room_name = course["where"]
                end

                # Ethernet and power outlets are set to false since we can't really say given the information that there are any.
                room = {'room_name' => room_name, 'campus_id' => campus_id, 'room_capacity' => capacity["capacity"], 'power_outlet' => false, 'ethernet_ports' => false}

                if @test
                    puts "room = #{room}"
                end

                room_id = @db.insert_nonexist("rooms", {"room_name" => room_name}, room)

                # Remove tailing bracket info
                prof_name = course['instructor'].gsub(/ \(.*$/, '')
                
                #if prof_name == 'TBA'
                #    prof_name = nil
                #end

                prof_info = {'professor_name' => prof_name}
                # Next we check the professor
                if @test
                    puts "prof = #{prof_info}"
                end

                prof_id = @db.insert_nonexist('professors', prof_info, prof_info)

                week_alt = nil
                if course['week'].match(/W[12]/)
                    if course['week'].match(/W1/)
                        week_alt = false
                    else
                        week_alt = true
                    end
                end

                start_time, end_time = splitRange(course['time'])
                start_date, end_date = splitRange(course['date_range'])
                
                if start_time == 'TBA'
                    start_time = nil
                end

                if start_date == 'TBA'
                    start_date = nil
                end

                # Get the id of the type, in the event that some other class type is found (that is not within the @db) the full name will be inserted (short form isnt here)
                class_type = {"type" => course['schedule_type']}

                # Some reason this is still messing up and inserting a lot of duplicate values
                if @test
                    puts "type = #{class_type}"
                end

                type_id = @db.insert_nonexist('class_type', class_type, class_type)

                # Insert course offering information
                offering_info = {'courses_id' => course_id, 'crn' => title_info['crn'], 'section' => title_info['section'], 'class_type_id' => type_id, 'registered' => capacity["actual"], 'day' => course['days'], 'professors_id' => prof_id, 'rooms_id' => room_id, 'week_alt' => week_alt, 'start_time' => start_time, 'end_time' => end_time, 'start_date' => start_date, 'end_date' => end_date, 'semesters_id' => semester_id}

                # Remove the nil values
                offering_info.compact

                # Insert the offering, each course offering will be unique so there should not be a check if it already exists.
                if @test
                    puts "offering = #{offering_info}"
                end
                @db.insert("offerings", offering_info)
            end
        end
        return true
    end

    
    def parseSemester()
        agent = Mechanize.new
        agent.get("https://ssbp.mycampus.ca/prod/bwckschd.p_disp_dyn_sched?TRM=U") do |page|

            page.at('#term_input_id').children[2..-1].each_with_index do |val, index|
                # UOIT <Full Semester Name> <Year>
                result = val.text.scan(/UOIT (.+) ([0-9]+)/)
                if result
                    # Store the term name, year and the code
                    term, year = result[0]
                    code = val.attribute("value").text
                    entries = {'year' => year, 'semester' => term, 'semester_code' => code}
                    # Inserting to db if they are not already there
                    @db.insert_nonexist('semesters', {'semester_code' => code}, entries)
                else
                    # Something went wrong!
                    puts "Invalid Semester Name: #{val.text}"
                end
            end
        end
    end

    def getFaculties(year)
        agent = Mechanize.new
        agent.get("https://ssbp.mycampus.ca/prod/bwckgens.p_proc_term_date?p_calling_proc=bwckschd.p_disp_dyn_sched&TRM=U&p_term=#{year}") do |page|

            # Subject codes
            page.at('#subj_id').children[1..-1].each_with_index do |val, index|

                # <Code> - <Full Name> 
                code, full_name = splitRange(val.text.rstrip)
                entries = {'faculty_code' => code, 'faculty_name' => full_name}
                #puts "subjs = #{entries}"
                # Insert into the db
                @db.insert_nonexist('faculties', {'faculty_code' => code}, entries)
            end

            # TODO test these two to make sure that the list lines up
            class_types = page.at('#schd_id')

            # Pre 201409 (e.g. 201405) this table does not exist
            if class_types != nil
                # Class types
                class_types.children[2..-1].each_with_index do |val, index|
                    # Full name (e.g. Lecture) => val.text.rstrip
                    # Short form (e.g. LEC) => val.attribute("value").text

                    # TODO add a check if the type is found but it doesn't have an acr

                    acr = val.attribute("value").text
                    entries = {'type' => val.text.rstrip, 'acr' => acr}
                    puts "type = #{entries}"    
                    @db.insert_nonexist('class_type', {'type' => val.text.rstrip}, entries)
                end
            end

            campus_names = page.at('#camp_id')

            # Pre 201009 (e.g. 201005) this table does not exist guess UOIT didn't have other campuses then.
            if campus_names != nil
                # Campuses
                campus_names.children[2..-1].each_with_index do |val, index|
                    # Full name (e.g. UOIT - North Oshawa) => val.text.rstrip
                    # Short form (e.g. UON) => val.attribute("value").text
                    
                    campus = val.text.rstrip

                    # Campus names are a bit funny this regex may break easily
                    result = campus.scan(CAMPUS_NAME)

                    if result && result[0]
                        campus = result[0][2]
                    end
                    acr = val.attribute("value").text
                    entries = {'campus_name' => campus, 'campus_acr' => acr}
                    #puts "campus = #{entries}"
                    @db.insert_nonexist('campus', {'campus_acr' => acr}, entries)
                end
            end
        end
    end

    def parseEachFaculty(campus, semester, year, child=nil)

        second = true
        if child == nil
            second = false
        end
        progress_indicator = Progress.new("Schedual Parser #{campus}, #{semester}, #{year}", second)

        progress_indicator.puts "Loading Faculties..."

        # Get each faculty
        faculties = @db.get_entries('faculties', ['faculty_code'])
        progress_indicator.total_length = faculties.size

        faculties.each_with_index do |hash, index|

            if child != nil
                child.print_bar(["Parsing #{year}, #{semester}"])
            end

            progress_indicator.percentComplete(["Parsing #{hash['faculty_code']}"])

            # Start parsing
            if parse(campus, hash['faculty_code'], semester, year) == false
                return false
            end
        end
    end

    def parseEachSemester(campus)
        parseSemester

        progress_indicator = Progress.new("Schedual Parser #{campus}")

        semesters = @db.get_entries('semesters', ['year', 'semester', 'code'])
        progress_indicator.total_length = semesters.size

        semesters.each_with_index do |hash, index|

            progress_indicator.percentComplete(["Parsing #{hash['year']}, #{hash['semester']}"])

            #if hash['year'].to_i < 2010
            getFaculties(hash['code'])

            if !parseEachFaculty(campus, Acronyms::SEMESTER[hash['semester'].downcase], hash['year'].downcase, progress_indicator)
                return false
            end
            #end
        end
    end

private

    ROOM_REGEX = /(\w+)$/
            
    # Campus names are a bit funny this regex may break easily for new campuses
    CAMPUS_NAME = /UOIT ?(-(Off)?)? (.*)/

    ROW_NAMES = ["week", "type", "time", "days", "where", "date_range", "schedule_type", "instructor"]
    COURSE_NAMES = ["name", "crn", "course_code", "section"]

    NUMBERS = ["capacity", "actual", "Remaining"]

    def parseCapacity(node)
        result = Hash.new
        node.css("td:nth-of-type(n+2)").each_with_index do |val, i|
            result[NUMBERS[i]] = val.text
        end
        return result
    end

    def parseRow(node)
        result = Hash.new
        node.css("td:nth-of-type(n+1)").each_with_index do |val, i|
            result[ROW_NAMES[i]] = val.text
        end
        return result
    end

    def parseCourse(node)
        # Full name - CRN - Code - Section
        result = Hash.new
        # Apparently a valid section number is 'EX1'
        row = node.text.scan(/([\w\W]+?) - ([0-9]+) - ([\w]+ [0-9\w]+?) - ([\w0-9]+)/)
        
        if row[0] == nil
            puts "node = #{node.text}"
        end

        row[0].each_with_index do |val, i|
            #node.text.split(/ - /).each_with_index do |val, i|
            result[COURSE_NAMES[i]] = val.strip
        end
        return result
    end

    def splitRange(text)
        range = text.split(/ - /)
        if range
            return range
        end
        return [nil,nil]
    end
end


semester = 'winter'
campus = 'UON'
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

parser.parseEachFaculty(campus, Acronyms::SEMESTER[semester], year)
#parser.parseEachSemester(campus)

=begin

           
=end
