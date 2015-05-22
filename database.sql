/*
 * Script to create all the relation schemas for the free-room-finder database
 */
/*
Command line access
sudo -u postgres createdb free_room_finder
sudo -u postgres psql free_room_finder
*/

/*
createuser -d -P -s room-finder
gNoXRPUWNZ4XL1r$W37iwnR8fVz:JN7hi7gq6P2o0Aci3pbG7B!Ld(Z7@0hXaxKfGy92GdryKw!NXbSZ
ALTER USER postgres with password 'gNoXRPUWNZ4XL1r$W37iwnR8fVz:JN7hi7gq6P2o0Aci3pbG7B!Ld(Z7@0hXaxKfGy92GdryKw!NXbSZ';
    */


/* Delete the existing information */
drop table if exists offerings;
drop table if exists courses;
drop table if exists professors;
drop table if exists rooms;
drop table if exists campus;
drop table if exists class_type;
drop table if exists semesters;
drop table if exists faculties;

/*
faculties
-----------
    - facultyId primary key (integer)
    - code        //facility code
    - name        //Name is stored in faculties file in webct folder
*/
CREATE TABLE faculties
(
    faculties_id   serial,
    faculty_code        TEXT NOT NULL,
    faculty_name        TEXT NOT NULL,
    PRIMARY KEY(faculties_id)
);



/*
semesters table
---------------
    - semesterId primary key NOT NULL
    - year YEAR(4) NOT NULL     (ie. 2012) 
    - semester TEXT NOT NULL     (ie. Winter, Spring/Summer, Summer)
*/
CREATE TABLE semesters
(
    semesters_id  serial,
    year        INTEGER,
    semester    TEXT NOT NULL,
    semester_code        TEXT NOT NULL,
    PRIMARY KEY(semesters_id)
);



/*
class_type table
----------------
    - typeId primary key NOT NULL
    - class acr (ie. acronym LEC, TUT)
    - class type (ie. Lecture, Tutorial)
*/
CREATE TABLE class_type
(
    class_type_id     serial,
    acr     TEXT,
    type    TEXT,
    PRIMARY KEY(class_type_id)
);



/*
campus table
------------
    - campusId  primary key NOT NULL
    - acr acr (ie. UON),
    - name (ie. North Oshawa Campus)
*/
CREATE TABLE campus
(
    campus_id         serial,
    campus_acr         TEXT,
    campus_name        TEXT,
    PRIMARY KEY(campus_id)
);



/*
users
-----
    - userId primary key NOT NULL
    - username TEXT NOT NULL
    - password TEXT NOT NULL
*/
/*
CREATE TABLE users
(
    id         serial,
    first_name  TEXT,
    last_name   TEXT,
    studentid  BLOB,
    email       TEXT,
    username    TEXT,
    password    BLOB,
    reg_date    DATE,
    last_access DATE,
    PRIMARY KEY (id)
);
*/



/*
rooms
-------
    - roomId primary key NOT NULL
    - name TEXT NOT NULL
    - campusId INTEGER UNSIGNED NOT NULL
    - room_capacity (INTEGER) NOT NULL
    - room info such as
    - laptop recharge support (Boolean)
    - Ethernet ports (Boolean)
*/
CREATE TABLE rooms
(
    rooms_id             serial,
    room_name            TEXT NOT NULL,
    campus_id       INTEGER,
    room_capacity   INTEGER NOT NULL,
    power_outlet    BOOLEAN,
    ethernet_ports  BOOLEAN,
    PRIMARY KEY(rooms_id),
    FOREIGN KEY(campus_id) REFERENCES campus(campus_id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);



/*
occupied
---------
    - occupyId primary key NOT NULL
    - date (including time (from-to), day, month, year)
    - might be worth while to have the date separate of the tixme
    - room_reference foreign key NOT NULL
    - number_of_people INTEGER NOT NULL
*/
/*
CREATE TABLE occupied
(
    id         serial,
    roomId      serial,
    start_time  timestamp,
    end_time    timestamp,
    num_people  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(id),
    FOREIGN KEY(roomId) REFERENCES rooms(id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);
*/


/*
room_requests
-------------
    - userid foreign key NOT NULL
    - occupyId foreign key NOT NULL
    - number_of_people INTEGER NOT NULL
*/
/*
CREATE TABLE room_requests
(
    id         serial,
    userId      serial,
    occupyId    serial,
    num_people  INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY(id),
    FOREIGN KEY(userId) REFERENCES users(id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(occupyId) REFERENCES occupied(id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);
*/

/* NOTE, PER Semester (delete entries a few days after the end of each semester) */



/*
professors
-----------
    - profId primary key NOT NULL
    - name TEXT
    - facultyId foreign key   prof might not be easily linked
*/
CREATE TABLE professors
(
    professors_id     serial,
    professor_name    TEXT,
    PRIMARY KEY(professors_id)
);



/*
courses
---------
    - courseId primary key NOT NULL,
    - course_code TEXT NOT NULL
    - name TEXT NOT NULL
    - facultyId foreign key
*/
CREATE TABLE courses
(
    courses_id         serial,
    course_name        TEXT NOT NULL,
    course_code TEXT NOT NULL,
    level       TEXT NOT NULL,
    faculties_id  INTEGER,
    PRIMARY KEY(courses_id),
    FOREIGN KEY(faculties_id) REFERENCES faculties(faculties_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);



/*
offerings
-----------
    - courseId foreign key NOT NULL
    - crn         TEXT  NOT NULL,
    - section     TEXT  NOT NULL,
    - typeId      INTEGER     UNSIGNED    NOT NULL,
    - registered INTEGER NOT NULL
    - day CHAR(1) NOT NULL
    - week_alt BOOLEAN DEFAULT NULL, identifies whether the class alternates
      weekly, default, NULL indicates that the class occurs each week, TRUE,
      indicates it occurs for week 1, FALSE, indicates it occurs for week 2
    - profId foreign key        (IF NULL Prof == TBA/UNKNOWN)
    - roomId foreign key        (COULD BE AN ONLINE COURSE)
    - campusId foreign key INTEGER UNSIGNED
    - start_time  INTEGER     UNSIGNED,
    - end_time INTEGER     UNSIGNED,
    - start_date foreign key NOT NULL
    - end_date foreign key NOT NULL
    - semesterId      INTEGER     UNSIGNED    NOT NULL,
*/
CREATE TABLE offerings
(
    offerings_id            serial,
    courses_id              INTEGER,
    crn                     TEXT  NOT NULL,
    section                 TEXT  NOT NULL,
    class_type_id           INTEGER,
    registered              INTEGER NOT NULL,
    day                     TEXT,
    week_alt                BOOLEAN     DEFAULT NULL,
    professors_id           INTEGER,
    rooms_id                INTEGER,
    start_time              time,
    end_time                time,
    start_date              date,
    end_date                date,
    semesters_id            INTEGER,
    PRIMARY KEY(offerings_id),
    FOREIGN KEY(courses_id) REFERENCES courses(courses_id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(class_type_id) REFERENCES class_type(class_type_id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(professors_id) REFERENCES professors(professors_id)
        ON DELETE SET NULL    ON UPDATE CASCADE,
    FOREIGN KEY(rooms_id) REFERENCES rooms(rooms_id)    
        ON DELETE SET NULL    ON UPDATE CASCADE,
    FOREIGN KEY(semesters_id) REFERENCES semesters(semesters_id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);