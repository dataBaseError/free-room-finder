ALTER TABLE faculties RENAME COLUMN _id TO faculty_id;
ALTER TABLE semesters RENAME COLUMN _id TO semester_id;
ALTER TABLE class_type RENAME COLUMN _id TO class_type_id;
ALTER TABLE campus RENAME COLUMN _id TO campus_id;
ALTER TABLE rooms RENAME COLUMN _id TO room_id;
ALTER TABLE rooms RENAME COLUMN campusId TO campus_id;
ALTER TABLE professors RENAME COLUMN _id TO professor_id;
ALTER TABLE courses RENAME COLUMN _id TO course_id;
ALTER TABLE courses RENAME COLUMN facultyId TO faculty_id;
ALTER TABLE offerings RENAME COLUMN _id TO offering_id;
ALTER TABLE offerings RENAME COLUMN courseId TO course_id;
ALTER TABLE offerings RENAME COLUMN typeId TO class_type_id;
ALTER TABLE offerings RENAME COLUMN profId TO professor_id;
ALTER TABLE offerings RENAME COLUMN roomId TO room_id;
ALTER TABLE offerings RENAME COLUMN semesterId TO semester_id;

CREATE FUNCTION dow(date_ DATE)
RETURNS TEXT
IMMUTABLE
LANGUAGE SQL
AS
$$
  SELECT CASE date_part('dow', $1)
  WHEN 1 THEN 'M'
  WHEN 2 THEN 'T'
  WHEN 3 THEN 'W'
  WHEN 4 THEN 'R'
  WHEN 5 THEN 'F'
  END;
$$;

create type timerange as range (subtype = time);
create type daterange as range (subtype = date);

with day_offerings as
(
    select *
    from offerings
    where day = dow('2015-02-02')
    and daterange(start_date, end_date, '[]') @> '2015-02-02'::date
),
taken_rooms as
(
    select distinct room_id
    from day_offerings
    where timerange(start_time, end_time, '()') &&
          timerange('13:00'::time, '13:00'::time + interval '1 hours', '()')
),
free_rooms as
(
    select room_id
    from rooms
    except
    select room_id from taken_rooms
),
free_info as
(
    select room_id,
           (select offering_id
            from day_offerings a
            where a.room_id = f.room_id
            and a.end_time <= '13:00'::time
            order by end_time desc
            limit 1) as previous_offering_id,
           (select offering_id
            from day_offerings a
            where a.room_id = f.room_id
            and a.start_time >= ('13:00'::time + interval '1 hours')
            order by start_time
            limit 1) as next_offering_id
    from free_rooms f
)
select free_info.room_id,
       room_name,
       coalesce(prev_offering.end_time, '08:00'::time) as previous_time,
       coalesce(next_offering.start_time, '23:00'::time) as next_time,
       (coalesce(next_offering.start_time, '23:00'::time) - '13:00'::time) as duration
from free_info
natural join rooms
left outer join offerings prev_offering on previous_offering_id = prev_offering.offering_id
left outer join offerings next_offering on next_offering_id = next_offering.offering_id
order by duration, room_name;
