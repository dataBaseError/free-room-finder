require 'pg'

class DBinterface

    USERNAME = "postgres"
    PASSWORD = "z3vvt0aTlkoPb5"

    def initialize(name)
        @conn = PG.connect(dbname: name, user: USERNAME, password: PASSWORD, hostaddr: "127.0.0.1")
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

    def get_available_classes(campus, day, semester_code, start_time, end_time)

        query = "
            SELECT 
                r2.rooms_id,
                r2.room_name,
                o2.start_time,
                o2.end_time
            FROM
                offerings as o2 NATURAL JOIN
                rooms as r2 NATURAL JOIN
                semesters as s2 NATURAL JOIN
                campus as c2
            WHERE
                o2.day = $1 AND
                c2.campus_acr = $2 AND
                s2.semester_code = $3 AND
                r2.rooms_id NOT IN
                (
                    SELECT DISTINCT
                        r.rooms_id
                    FROM 
                        offerings as o NATURAL JOIN
                        rooms as r NATURAL JOIN
                        semesters as s NATURAL JOIN
                        campus as c
                    WHERE
                        o.day = $1 AND
                        c.campus_acr = $2 AND
                        s.semester_code = $3 AND
                        (
                            (
                                /* This checks if the start time happens during the desired interval */
                                start_time >= $4 AND
                                start_time < $5
                            )
                            OR
                            (
                                /* The case where the start time is before and the end time is during or after */
                                start_time < $4 AND
                                end_time > $4
                            )
                        )
                        OR
                        r.room_name LIKE 'ONLINE%'
                )
            order by
                r2.rooms_id,
                o2.start_time,
                o2.end_time"

        # Covert the array into a parameter hash that pg is expecting
        param = create_params([day, campus, semester_code, start_time, end_time])

        # Get the results
        results = Array.new
        @conn.exec_params(query, param).each_row do |row|
            results << Hash.new
            results[-1]['rooms_id'] = row[0]
            results[-1]['room'] = row[1]
            results[-1]['start_time'] = row[2]
            results[-1]['end_time'] = row[3]
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