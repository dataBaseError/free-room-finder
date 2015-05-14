require 'pg'

class DBinterface

    USERNAME = "postgres"
    PASSWORD = "z3vvt0aTlkoPb5"

    def initialize(name)
        @conn = PG.connect(dbname: name, user: USERNAME, password: PASSWORD, hostaddr: "127.0.0.1")
        @prepare_hash = Hash.new
    end

    def insert(table, attributes)

        #attribute_list = prepare_values(attributes.values).join(", ")
        attribute_name_list = attributes.keys.join(", ")
        list = prepare_statement_list(attributes.size).join(",")

        # The second part creates a uuid for inserts where a column may not be inserted (offerings)
        statement_name = "#{table}_#{attributes.keys.map{|x| x[0]}.join("")}"
        # There might be an issue with postgresql or pg where if the prepare name is too long it just stops checking
        #if statement_name == "offerings_courseIdcrnsectiontypeIdregistereddayprofIdroomIdstart_dateend_datesemesterId"
        #    a = gets
        #end
        #puts "statement = #{statement_name}"
        if @prepare_hash[statement_name] == nil
            #puts "hash = #{@prepare_hash}"
            #puts "#{statement_name} does not exist yet!"
            @conn.prepare(statement_name, "
            INSERT INTO 
                #{table}
            (
                #{attribute_name_list}
            )
            VALUES 
            (
                #{list}
            )
            RETURNING _id")
            @prepare_hash[statement_name] = true
        end

        id = nil
        @conn.exec_prepared(statement_name, attributes.values) do |results|
            results.each do |value|
                id = value["_id"]
            end
        end
        return id
    end

    def get_id_existing(table, identifier)

        #attribute_values = prepare_values(identifier.values)
        attribute_name_list = identifier.keys
        # TODO convert this to use prepared statements, this requires the statement to be prepared on the fly and also for the type of the identifier value(s) to be known.
        # This would also force the insert to be prepared as well.
        attribute_list = set_prepare(attribute_name_list)

        statement_name = "#{table}_id_exist"
        if @prepare_hash[statement_name] == nil
            @conn.prepare(statement_name, "
            SELECT 
                _id
            FROM 
                #{table}
            WHERE
                #{attribute_list}
            ")
            @prepare_hash[statement_name] = true
        end

        params = create_params(identifier.values)

        id = nil
        @conn.exec_prepared(statement_name, params) do |results|
            results.each do |value|
                id = value["_id"]
            end
        end
        return id
    end

    def get_entries(table, attributes, identifier=nil)

        attribute_name_list = attributes.join(", ")
        where = ""
        if identifier
            where += "WHERE "
            where += set_equal(identifier.keys, prepare_values(identifier.values))
        end

        i = 0
        values = Array.new
        @conn.exec("
            SELECT 
                #{attribute_name_list}
            FROM 
                #{table}
            #{where}
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
                r2._id,
                r2.name,
                o2.start_time,
                o2.end_time
            FROM
                offerings as o2 INNER JOIN
                rooms as r2 ON o2.roomId = r2._id INNER JOIN
                semesters as s2 ON o2.semesterId = s2._id INNER JOIN
                campus as c2 ON r2.campusId = c2._id
            WHERE
                o2.day = $1 AND
                c2.acr = $2 AND
                s2.code = $3 AND
                r2._id NOT IN
                (
                    SELECT DISTINCT
                        r._id
                        /*,
                        r.name,
                        o.start_time,
                        o.end_time*/
                    FROM 
                        offerings as o INNER JOIN
                        rooms as r ON o.roomId = r._id INNER JOIN
                        semesters as s ON o.semesterId = s._id INNER JOIN
                        campus as c ON r.campusId = c._id
                    WHERE
                        o.day = $1 AND
                        c.acr = $2 AND
                        s.code = $3 AND
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
                        r.name LIKE 'ONLINE%'
                )
            order by
                r2._id,
                o2.start_time,
                o2.end_time"

        # Covert the array into a parameter hash that pg is expecting
        param = create_params([day, campus, semester_code, start_time, end_time])

        # Get the results
        results = Array.new
        @conn.exec_params(query, param).each_row do |row|
            results << Hash.new
            results[-1]['id'] = row[0]
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