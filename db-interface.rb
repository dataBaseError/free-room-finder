require 'pg'

class DBinterface

    USERNAME = "postgres"
    PASSWORD = "z3vvt0aTlkoPb5"

    # Default port
    PORT = '5432' #'5434'

    OPENING_TIME = '8:00:00'
    CLOSING_TIME = '23:00:00'

    def initialize(name)
        @conn = PG.connect(dbname: name, user: USERNAME, password: PASSWORD, hostaddr: "127.0.0.1", port: PORT)
    end

    def insert(table, attributes)

        #attribute_list = prepare_values(attributes.values).join(", ")
        attribute_name_list = attributes.keys.join(", ")
        list = prepare_statement_list(attributes.size).join(",")

        query = "INSERT INTO 
                #{table}
            (
                #{attribute_name_list}
            )
            VALUES 
            (
                #{list}
            )
            RETURNING #{table}_id"

        id = nil
        @conn.exec_params(query, attributes.values) do |results|
            results.each do |value|
                id = value["#{table}_id"]
            end
        end
        return id
    end

    def get_id_existing(table, identifier)

        #attribute_values = prepare_values(identifier.values)
        attribute_name_list = identifier.keys
    
        # This would also force the insert to be prepared as well.
        attribute_list = set_prepare(attribute_name_list)

        query = "SELECT 
                #{table}_id
            FROM 
                #{table}
            WHERE
                #{attribute_list}"

        params = create_params(identifier.values)

        id = nil
        @conn.exec_params(query, params) do |results|
            results.each do |value|
                id = value["#{table}_id"]
            end
        end
        return id
    end

    def get_entries(table, attributes)

        attribute_name_list = attributes.join(", ")

        i = 0
        values = Array.new

        # Could add prepare here.
        @conn.exec("
            SELECT 
                #{attribute_name_list}
            FROM 
                #{table}
            ") do |results|
            results.each_row do |row|
                values[i] = Hash.new
                row.each_with_index do |element, j|
                    # Retrieve the values and store them into an array hash
                   values[i][attributes[j]] = element
                end
                i += 1
            end
        end
        return values


    end

     # Unique is the hash identifying how to find the entry
    def insert_nonexist(table, unique, input)
        id = get_id_existing(table, unique)

        if id == nil
            # Insert the information
            id = insert(table, input)
        end
        return id
    end

    # TODO expand to include campus as part of the query
    def get_available_classes(campus, date, start_time, duration)


        query = "
            with day_offerings as
            (
                select *
                from offerings
                where day = dow($1)
                and daterange(start_date, end_date, '[]') @> $1::date
            ),
            taken_rooms as
            (
                select distinct rooms_id
                from day_offerings
                where timerange(start_time, end_time, '()') &&
                      timerange($2::time, $2::time + (interval '1 hours' * $3::numeric), '()')
            ),
            free_rooms as
            (
                select rooms_id
                from rooms
                natural join campus
                where campus_acr = $4
                except
                select rooms_id from taken_rooms 
            ),
            free_info as
            (
                select rooms_id,
                       (select offerings_id
                        from day_offerings a
                        where a.rooms_id = f.rooms_id
                        and a.end_time <= $2::time
                        order by end_time desc
                        limit 1) as previous_offering_id,
                       (select offerings_id
                        from day_offerings a
                        where a.rooms_id = f.rooms_id
                        and a.start_time >= ($2::time + (interval '1 hours') * $3::numeric)
                        order by start_time
                        limit 1) as next_offering_id
                from free_rooms f
            )
            select free_info.rooms_id,
                   room_name,
                   coalesce(prev_offering.end_time, '#{OPENING_TIME}'::time) as previous_time,
                   coalesce(next_offering.start_time, '#{CLOSING_TIME}'::time) as next_time,
                   (coalesce(next_offering.start_time, '#{CLOSING_TIME}'::time) - $2::time) as duration
            from free_info
            natural join rooms
            left outer join offerings prev_offering on previous_offering_id = prev_offering.offerings_id
            left outer join offerings next_offering on next_offering_id = next_offering.offerings_id
            order by duration, room_name;"

        # Covert the array into a parameter hash that pg is expecting
        param = create_params([date, start_time, duration, campus])

        # Get the results
        results = Array.new
        @conn.exec_params(query, param).each_row do |row|
            results << Hash.new
            # Don't actually need the room id
            #results[-1]['rooms_id'] = row[0]
            results[-1]['room_name'] = row[1]
            results[-1]['previous_time'] = row[2]
            results[-1]['next_time'] = row[3]
            results[-1]['duration'] = row[4]
        end
        return results
    end

private

    def create_params(values)
        values_list = Array.new
        i = 0
        values.each do |val|
            values_list << Hash.new
            values_list[i][:value] = val
            # Format is assumed to be a string
            values_list[i][:format] = 0
            i+=1
        end
        return values_list
    end

    def set_equal(attribute_list, attribute_value)
        test = ""
        attribute_list.each_with_index do |attribute, index|
            test += "#{attribute} = #{attribute_value[index]}"
            if index + 1 < attribute_list.size
                test += " AND "
            end
        end
        return test
    end

    def set_prepare(attribute_list)
        test = ""
        attribute_list.each_with_index do |attribute, index|
            test += "#{attribute} = $#{index+1}"
            if index + 1 < attribute_list.size
                test += " AND "
            end
        end
        return test
    end

    def prepare_statement_list(size)
        result = Array.new
        size.times do |x|
            result << "$#{x+1}"
        end
        return result
    end

    def prepare_values(values)
        values.map do |value|
            # handle the case where a string needs to be escaped
            if value.class.name == "String"
                value = "'#{value}'"
            else
                value
            end
        end
    end

end

#db = DBinterface.new("free_room_finder")

#attributes = {'type' => 'Lecture'}
#db.insert('class_type', attributes)
#db.get_id_existing('class_type', attributes)
#db.insert_nonexist('class_type', attributes, attributes)

=begin

    def get_id_existing(table, identifier)

        attribute_values = prepare_values(identifier.values)
        attribute_name_list = identifier.keys
        # TODO convert this to use prepared statements, this requires the statement to be prepared on the fly and also for the type of the identifier value(s) to be known.
        # This would also force the insert to be prepared as well.
        attribute_list = set_equal(attribute_name_list, attribute_values)

        id = nil
        @conn.exec("
            SELECT 
                _id
            FROM 
                #{table}
            WHERE
                #{attribute_list}
            ") do |results|
            results.each do |value|
                id = value["_id"]
            end
        end
        return id
    end
=end