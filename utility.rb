require 'date'
require 'time'

require_relative 'acronyms'

class Utility

    MIN_DURATION = 0
    MAX_DURATION = 12
    TIME_STRING = '%H:%M:%S'

    def self.add_hours(time, hours)
        return time + (hours * 60 * 60)
    end

    def self.get_semester(date)
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

    # Validate the campus
    def self.validCampus?(campus)
        if Acronyms::CAMPUS_ACRONYM[campus]
            return campus
        end
        raise "Invalid Campus, valid campuses: #{Acronyms::CAMPUS_ACRONYM.keys}"
    end

    # Validate the date
    def self.validDate?(date)

        #date = nil
        begin
            # Format YYYY-MM-DD
            return Date.parse(date)
        rescue ArgumentError
            raise "Invalid Date, format is: YYYY-MM-DD"
        end
    end

    def self.validDay?(week_day)

        day = Acronyms::DAY[week_day]
        if day == nil
            # TODO just return all the rooms since they should all be available
            raise "Invalid Date, App is not for Sunday and Saturday. To find a free room find a class and hope it's free."
        end
        return day
    end

    def self.validTime?(time_string)

        start_time = nil
        time = nil
        begin
            time = Time.parse(time_string)

            start_time = time.strftime(TIME_STRING)
        rescue ArgumentError
            raise "Invalid Time, format is: HH-MM-SS and in 24 hour format"
        end

        return [start_time, time]
    end

    def self.getEndTime(start_time, duration)
        if duration && duration.to_f > MIN_DURATION && duration.to_f < MAX_DURATION
            return add_hours(start_time, duration.to_f).strftime(TIME_STRING)
        end
        raise "Invalid Duration, duration must be an Integer between (#{MIN_DURATION}, #{MAX_DURATION})"
    end

    def self.validateFindRoom(campus, date, start_time, duration)
        result = Hash.new

        result['campus'] = validCampus?(campus)

        # Get the date
        date = validDate?(date)
       
        result['semester_code'] = get_semester(date)

        result['day'] = validDay?(date.wday)

        result['start_time'], time = validTime?(start_time)

        result['end_time'] = getEndTime(time, duration)

        return result
    end
end