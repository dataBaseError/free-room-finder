
require 'sinatra'
require 'json'

require 'date'
require 'time'

require_relative 'find_room'
require_relative 'acronyms'

def add_hours(time, hours)
    return time + (hours * 60 * 60)
end

def get_semester(date)
    semester = nil
    if date.month >= Acronyms::SEMESTER['fall'].to_i && date.month <= 12
        # Fall
        semester = Acronyms::SEMESTER['fall']
    elsif date.month >= Acronyms::SEMESTER['winter'].to_i && date.month < Acronyms::SEMESTER['summer'].to_i
        # Winter
        semester = Acronyms::SEMESTER['winter']
    elsif date.month >= Acronyms::SEMESTER['summer'].to_i && date.month < Acronyms::SEMESTER['fall'].to_i
        # Spring/Summer
        semester = Acronyms::SEMESTER['summer']
    end
    return "#{date.year}#{semester}"
end

TIME_STRING = '%H:%M:%S'


get '/rooms/:campus/:date/:start_time/:duration' do

    # Validate the campus
    campus = nil
    if Acronyms::CAMPUS_ACRONYM[params['campus']]
        campus = params['campus']
    else
        raise "Invalid Campus, valid campuses: #{Acronyms::CAMPUS_ACRONYM.keys}"
    end

    # Validate the date
    date = nil
    begin
        # Format YYYY-MM-DD
        date = Date.parse(params['date'])
    rescue ArgumentError
        raise "Invalid Date, format is: YYYY-MM-DD"
    end

    semester_code = get_semester(date)

    day = Acronyms::DAY[date.wday]
    if day == nil
        raise "Invalid Date, App is not for Sunday and Saturday. To find a free room find a class and hope it's free."
    end

    start_time = nil
    time = nil
    begin
        time = Time.parse(params['start_time'])

        start_time = time.strftime(TIME_STRING)
    rescue ArgumentError
        raise "Invalid Time, format is: HH-MM-SS and in 24 hour format"
    end

    end_time = nil
    duration = params['duration']

    if duration && duration.to_f > 0 && duration.to_f < 12
        end_time = add_hours(time, duration.to_f).strftime(TIME_STRING)
    else
        raise "Invalid Duration, duration must be an Integer between (0, 12)"
    end

    room_finder = FindRoom.new

    # Post the json
    room_finder.getRooms(campus, day, semester_code, start_time, end_time).to_json
end