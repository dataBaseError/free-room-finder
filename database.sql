/*
 * Script to create all the relation schemas for the free-room-finder database
 */
/*
Command line access
sudo -u postgres createdb free_room_finder
sudo -u postgres psql free_room_finder
*/

# Delete the existing information
drop table if exists faculties;
drop table if exists semesters;
drop table if exists class_type;
drop table if exists campus;
drop table if exists rooms;
drop table if exists professors;
drop table if exists courses;
drop table if exists offerings;

/*
faculties
-----------
    - facultyId primary key (integer)
    - code        //facility code
    - name        //Name is stored in faculties file in webct folder
*/
CREATE TABLE faculties
(
    _id   serial,
    code        VARCHAR(32) NOT NULL,
    name        VARCHAR(64) NOT NULL,
    PRIMARY KEY(_id)
);



/*
semesters table
---------------
    - semesterId primary key NOT NULL
    - year YEAR(4) NOT NULL     (ie. 2012) 
    - semester VARCHAR(32) NOT NULL     (ie. Winter, Spring/Summer, Summer)
*/
CREATE TABLE semesters
(
    _id  serial,
    year        INTEGER,
    semester    VARCHAR(32) NOT NULL,
    code        VARCHAR(32) NOT NULL,
    PRIMARY KEY(_id)
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
    _id     serial,
    acr     VARCHAR(32),
    type    VARCHAR(32),
    PRIMARY KEY(_id)
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
    _id         serial,
    acr         VARCHAR(32),
    name        VARCHAR(64),
    PRIMARY KEY(_id)
);



/*
users
-----
    - userId primary key NOT NULL
    - username VARCHAR(32) NOT NULL
    - password VARCHAR(64) NOT NULL
*/
/*
CREATE TABLE users
(
    _id         serial,
    first_name  VARCHAR(32),
    last_name   VARCHAR(32),
    student_id  BLOB,
    email       VARCHAR(64),
    username    VARCHAR(32),
    password    BLOB,
    reg_date    DATE,
    last_access DATE,
    PRIMARY KEY (_id)
);
*/



/*
rooms
-------
    - roomId primary key NOT NULL
    - name VARCHAR(64) NOT NULL
    - campusId INTEGER UNSIGNED NOT NULL
    - room_capacity (INTEGER) NOT NULL
    - room info such as
    - laptop recharge support (Boolean)
    - Ethernet ports (Boolean)
*/
CREATE TABLE rooms
(
    _id             serial,
    name            VARCHAR(32) NOT NULL,
    campusId        serial,
    room_capacity   INTEGER NOT NULL,
    power_outlet    BOOLEAN,
    ethernet_ports  BOOLEAN,
    PRIMARY KEY(_id),
    FOREIGN KEY(campusId) REFERENCES campus(_id)
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
    _id         serial,
    roomId      serial,
    start_time  timestamp,
    end_time    timestamp,
    num_people  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(_id),
    FOREIGN KEY(roomId) REFERENCES rooms(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);
*/


/*
room_requests
-------------
    - user_id foreign key NOT NULL
    - occupyId foreign key NOT NULL
    - number_of_people INTEGER NOT NULL
*/
/*
CREATE TABLE room_requests
(
    _id         serial,
    userId      serial,
    occupyId    serial,
    num_people  INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY(_id),
    FOREIGN KEY(userId) REFERENCES users(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(occupyId) REFERENCES occupied(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);
*/

/* NOTE, PER Semester (delete entries a few days after the end of each semester) */



/*
professors
-----------
    - profId primary key NOT NULL
    - name VARCHAR(32)
    - facultyId foreign key   prof might not be easily linked
*/
CREATE TABLE professors
(
    _id     serial,
    name    VARCHAR(64),
    PRIMARY KEY(_id)
);



/*
courses
---------
    - courseId primary key NOT NULL,
    - course_code VARCHAR(4) NOT NULL
    - name VARCHAR(64) NOT NULL
    - facultyId foreign key
*/
CREATE TABLE courses
(
    _id         serial,
    name        VARCHAR(64) NOT NULL,
    course_code VARCHAR(32) NOT NULL,
    level       VARCHAR(64) NOT NULL,
    facultyId   serial,
    PRIMARY KEY(_id),
    FOREIGN KEY(facultyId) REFERENCES faculties(_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);



/*
offerings
-----------
    - courseId foreign key NOT NULL
    - crn         VARCHAR(8)  NOT NULL,
    - section     VARCHAR(3)  NOT NULL,
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
    _id         serial,
    courseId    serial,
    crn         VARCHAR(32)  NOT NULL,
    section     VARCHAR(32)  NOT NULL,
    typeId      serial,
    registered  INTEGER NOT NULL,
    day         VARCHAR(32),
    week_alt    BOOLEAN     DEFAULT NULL,
    profId      serial,
    roomId      serial,
    start_time  time,
    end_time    time,
    start_date  date,
    end_date    date,
    semesterId  serial,
    PRIMARY KEY(_id),
    FOREIGN KEY(courseId) REFERENCES courses(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(typeId) REFERENCES class_type(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE,
    FOREIGN KEY(profId) REFERENCES professors(_id)
        ON DELETE SET NULL    ON UPDATE CASCADE,
    FOREIGN KEY(roomId) REFERENCES rooms(_id)    
        ON DELETE SET NULL    ON UPDATE CASCADE,
    FOREIGN KEY(semesterId) REFERENCES semesters(_id)
        ON DELETE CASCADE    ON UPDATE CASCADE
);