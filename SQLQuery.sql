CREATE TABLE Zip_Code(
address VARCHAR(30) NOT NULL PRIMARY KEY,
city VARCHAR(20) NOT NULL,
state VARCHAR(20) NOT NULL,
zip INT NOT NULL
);

CREATE TABLE Persons(
person_id INT NOT NULL PRIMARY KEY,
name VARCHAR(20),
birthdate DATE,
phone INT,
address VARCHAR(30),

FOREIGN KEY (address) REFERENCES Zip_Code(address)
);

CREATE TABLE Physician(
person_id INT NOT NULL PRIMARY KEY,
specialty VARCHAR(20) NOT NULL,
phone_no INT NOT NULL,

FOREIGN KEY (person_id) REFERENCES Persons (person_id)
);

CREATE TABLE Volunteer(
person_id INT NOT NULL PRIMARY KEY,
skill VARCHAR(20) NOT NULL,

FOREIGN KEY (person_id) REFERENCES Persons (person_id)
);

CREATE TABLE Employees(
person_id INT NOT NULL PRIMARY KEY,
date_hired DATE NOT NULL,

FOREIGN KEY (person_id) REFERENCES Persons (person_id)
);
