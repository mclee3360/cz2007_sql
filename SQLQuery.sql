/* See update in Relations document on Drive. Needed to be split for normalization */
CREATE TABLE Zip_Code(
    zip   CHAR(6)     PRIMARY KEY,
    city  VARCHAR(20) NOT NULL,
    state VARCHAR(20) NOT NULL,
    CONSTRAINT zip_only_digits CHECK(
        zip NOT LIKE '%[^0-9]%'
    )
);

CREATE TABLE Addresses(
    address VARCHAR(30) PRIMARY KEY,
    zip     CHAR(6)     NOT NULL
    CONSTRAINT zip_code_exists FOREIGN KEY (zip) REFERENCES Zip_Code(zip)
        ON UPDATE CASCADE
        ON DELETE NO ACTION /* Must set new zip code before deleting old one */
);

CREATE TABLE Persons(
    id        INT         IDENTITY(0, 1) PRIMARY KEY,
    name      VARCHAR(20) NOT NULL,
    birthdate DATE        NOT NULL,
    phone     VARCHAR(10),
    address   VARCHAR(30),

    CONSTRAINT address_exists FOREIGN KEY (address) REFERENCES Addresses(address)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT person_phone_only_digits CHECK(
        phone NOT LIKE '%[^0-9]%'
    )
);

CREATE TABLE Physician(
    id        INT         PRIMARY KEY,
    specialty VARCHAR(20) NOT NULL,
    phone     VARCHAR(10) NOT NULL,

    CONSTRAINT phys_is_person FOREIGN KEY(id) REFERENCES Persons(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT phys_phone_only_digits CHECK(
        phone NOT LIKE '%[^0-9]%'
    )
);

CREATE TABLE Patient(
    id            INT  NOT NULL,
    contact_date  DATE NOT NULL,
    physician_id  INT  NOT NULL,

    PRIMARY KEY(id, contact_date),

    CONSTRAINT patient_is_person FOREIGN KEY (id) REFERENCES Persons(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT phys_exists FOREIGN KEY (physician_id) REFERENCES Physician(id)
        ON UPDATE NO ACTION /* Prevents direct update of physician ID due to
                               potential cycles */
        ON DELETE NO ACTION,/* Forces physician to be updated before removing
                               the physician */
    CONSTRAINT not_your_own_phys CHECK(
        id <> physician_id /* Prevents patient from being their own physician */
    )
);

CREATE TABLE Outpatient(
    id            INT  NOT NULL,
    contact_date  DATE NOT NULL,

    PRIMARY KEY(id, contact_date),

    CONSTRAINT outpatient_is_patient FOREIGN KEY(id, contact_date)
    REFERENCES Patient(id, contact_date)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Visit(
    patient_id   INT          NOT NULL,
    contact_date DATE         NOT NULL,
    phys_id      INT          NOT NULL, /* Physician being visited. Could
                                           potentially not be the patient's
                                           main physician. */
    visit_date   DATE         NOT NULL,
    comment      VARCHAR(100) CONSTRAINT [default_comment] DEFAULT 'NIL',
    /* Removed num_times since it doesn't make sense for a patient to be
       scheduled a visit multiple times to the same physician in one day */

    /* Should be able to uniquely identify every visit with the patient,
       physician being visited, and the date (no physician should be visited
       by the same patient more than once a day */
    PRIMARY KEY(patient_id, phys_id, visit_date),

    CONSTRAINT outpatient_exists FOREIGN KEY(patient_id, contact_date)
    REFERENCES Outpatient(id, contact_date)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT physician_exists FOREIGN KEY(phys_id) REFERENCES Physician(id)
        ON UPDATE NO ACTION /* Prevents direct update of physician ID due to
                               potential cycles */
        ON DELETE NO ACTION /* Must reassign patient's visit to another physician
                               before deletion */
);

CREATE TABLE Volunteer(
    id    INT         PRIMARY KEY,
    skill VARCHAR(20),

    CONSTRAINT volunteer_is_person FOREIGN KEY(id) REFERENCES Persons(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Employees(
    id         INT  PRIMARY KEY,
    date_hired DATE NOT NULL,

    CONSTRAINT employee_is_person FOREIGN KEY(id) REFERENCES Persons(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Staff(
    id        INT         PRIMARY KEY,
    job_class VARCHAR(20) NOT NULL,

    CONSTRAINT staff_is_employee FOREIGN KEY(ID) REFERENCES Employees(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Technician(
    id    INT         PRIMARY KEY,
    skill VARCHAR(20),

    CONSTRAINT tech_is_employee FOREIGN KEY(ID) REFERENCES Employees(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Lab(
    name     VARCHAR(30) PRIMARY KEY,
    location VARCHAR(30) NOT NULL,
);

CREATE TABLE Lab_Assignments(
    tech_id  INT         NOT NULL,
    lab_name VARCHAR(30) NOT NULL,

    PRIMARY KEY(tech_id, lab_name),

    CONSTRAINT tech_exists FOREIGN KEY (tech_id) REFERENCES Technician(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT lab_exists FOREIGN KEY (lab_name) REFERENCES Lab(name)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Care_Centre(
    name         VARCHAR(30) PRIMARY KEY,
    location     VARCHAR(30) NOT NULL,
    type         VARCHAR(20) NOT NULL,
    rn_in_charge INT         NOT NULL UNIQUE, /* Unique b/c one RN can only be
                                                 in charge of one centre at a
                                                 time, per the diagram */
    /* Foreign key is added later because of the way diagram is set up */
);

CREATE TABLE Nurse(
    id              INT         PRIMARY KEY,
    assigned_centre VARCHAR(30),

    CONSTRAINT nurse_is_person FOREIGN KEY (id) REFERENCES Employees(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT nurse_is_assigned FOREIGN KEY (assigned_centre) REFERENCES Care_Centre(name)
        ON UPDATE CASCADE
        ON DELETE NO ACTION /* Must assign a new centre before removing the centre */
);

CREATE TABLE Certificates(
    type VARCHAR(30) PRIMARY KEY
);

CREATE TABLE Nurse_Certifications(
    nurse_id  INT         NOT NULL,
    cert_type VARCHAR(30) NOT NULL,

    PRIMARY KEY(nurse_id, cert_type),

    CONSTRAINT nurse_exists FOREIGN KEY(nurse_id) REFERENCES Nurse(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT cert_exists FOREIGN KEY(cert_type) REFERENCES Certificates(type)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE RN_Certificates(
    type VARCHAR(30) PRIMARY KEY,

    CONSTRAINT rncert_is_cert FOREIGN KEY (type) REFERENCES Certificates(type)
);

CREATE TABLE RN(
    id      INT         PRIMARY KEY,
    rn_cert VARCHAR(30) NOT NULL,

    CONSTRAINT rn_is_nurse FOREIGN KEY (id) REFERENCES Nurse(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT rn_has_rncert FOREIGN KEY (rn_cert) REFERENCES RN_Certificates(type)
        ON UPDATE CASCADE
        ON DELETE CASCADE /* If their RN Certification is no longer recognized
                             (removed from RN Certification table), then they're
                             no longer recognized as an RN */
);

/* Can add this foreign key now b/c RN has been created */
ALTER TABLE Care_Centre
    ADD CONSTRAINT rn_actually_in_charge FOREIGN KEY (rn_in_charge) REFERENCES RN(id)
        ON UPDATE NO ACTION /* Prevents direct update of RN ID to prevent
                               potential cycles in updates */
        ON DELETE NO ACTION /* RN in charge position must be handed off before
                               removing RN from db */
;

CREATE TABLE Bed(
    room_no     INT         NOT NULL,
    bed_no      INT         NOT NULL,
    centre_name VARCHAR(30) NOT NULL,

    PRIMARY KEY(room_no, bed_no),

    CONSTRAINT centre_exists FOREIGN KEY (centre_name) REFERENCES CARE_CENTRE(name)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE Resident(
    id            INT  NOT NULL,
    contact_date  DATE NOT NULL,
    date_admitted DATE NOT NULL,
    room_no       INT  NOT NULL,
    bed_no        INT  NOT NULL,

    PRIMARY KEY(id, contact_date),

    CONSTRAINT resident_is_patient FOREIGN KEY(id, contact_date)
    REFERENCES Patient(id, contact_date)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT bed_exists FOREIGN KEY(room_no, bed_no) REFERENCES Bed(room_no, bed_no)
        ON UPDATE CASCADE
        ON DELETE NO ACTION /* Must move resident to a different bed before
                               removing the bed */
);

CREATE TABLE Resident_Admit_Dates(
    resident_id  INT  NOT NULL,
    contact_date DATE NOT NULL,
    admit_date   DATE NOT NULL,

    PRIMARY KEY(resident_id, admit_date),

    CONSTRAINT resident_exists FOREIGN KEY(resident_id, contact_date)
    REFERENCES Resident(id, contact_date)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


/**************************
 * DATA SELECTION QUERIES *
 **************************/
/* #1 */
SELECT *
FROM   Volunteer
WHERE skill IS NULL;

/* #2 */
SELECT DISTINCT visiting_phys AS unassigned_physician
FROM   (
    /* Wrote out this subquery just for visualziation if needed; can just move
       the SELECT DISTINCT part from superquery into the SELECT statement
       in here */
    SELECT v.patient_id AS pat_id, v.contact_date AS contact,
    	   v.visit_date AS visit, p.physician_id AS primary_phys,
    	   v.phys_id AS visiting_phys
    FROM   Visit AS v, Patient AS p
    WHERE  p.id = v.patient_id AND p.contact_date = v.contact_date
    	   AND p.physician_id <> v.phys_id
) AS unassigned_phys;

/* #3 */
SELECT   patient_id
FROM     Visit
GROUP BY patient_id
HAVING   COUNT(visit_date) = 1;

/* #4 */
SELECT skill, COUNT(id) AS counter
FROM (
    SELECT id, skill
    FROM   Volunteer

    UNION

    SELECT id, skill
    FROM   Technician
) AS list
GROUP BY skill

/* #5 */
SELECT resident_id
FROM   Resident_Admit_Dates
WHERE  DATEDIFF(dy, contact_date, admit_date) <= 7;

/* #6 */
SELECT   phys_id, COUNT(visit_date) AS num_visits
FROM     Visit AS v
GROUP BY  phys_id, visit_date
HAVING   COUNT(visit_date) >= 3;
