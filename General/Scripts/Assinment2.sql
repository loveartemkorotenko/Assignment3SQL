DROP TABLE IF EXISTS Enrollments, FitnessClasses, Trainers, Members, Memberships CASCADE;

CREATE TABLE Memberships (
    MembershipID SERIAL PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Members (
    MemberID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    MembershipID INT REFERENCES Memberships(MembershipID)
);

CREATE TABLE Trainers (
    TrainerID SERIAL PRIMARY KEY,
    TrainerName VARCHAR(100) NOT NULL,
    Specialization VARCHAR(50)
);

CREATE TABLE FitnessClasses (
    ClassID SERIAL PRIMARY KEY,
    ClassName VARCHAR(100) NOT NULL,
    TrainerID INT REFERENCES Trainers(TrainerID),
    ClassDate TIMESTAMP NOT NULL
);

CREATE TABLE Enrollments (
    EnrollmentID SERIAL PRIMARY KEY,
    MemberID INT REFERENCES Members(MemberID),
    ClassID INT REFERENCES FitnessClasses(ClassID),
    Status VARCHAR(20) DEFAULT 'Confirmed'
);

TRUNCATE TABLE Enrollments, FitnessClasses, Trainers, Members, Memberships RESTART IDENTITY CASCADE;

INSERT INTO Memberships (TypeName, Price)
SELECT 
    'Абонемент типу ' || i,
    (random() * 9000 + 1000)::numeric(10,2) 
FROM generate_series(1, 10000) AS s(i);

INSERT INTO Members (FullName, Email, MembershipID)
SELECT 
    'Клієнт ' || i, 
    'client' || i || '@kse-test.com', 
    floor(random() * 10000 + 1)::int
FROM generate_series(1, 10000) AS s(i);

INSERT INTO Trainers (TrainerName, Specialization)
SELECT 
    'Тренер ' || i,
    (ARRAY['Кросфіт', 'Йога', 'Бокс', 'Пілатес', 'Бодібілдинг'])[floor(random() * 5 + 1)]
FROM generate_series(1, 10000) AS s(i);

INSERT INTO FitnessClasses (ClassName, TrainerID, ClassDate)
SELECT 
    'Групове заняття ' || s.i::text,
    floor(random() * 10000 + 1)::int,
    NOW() + (random() * (interval '60 days'))
FROM generate_series(1, 10000) AS s(i);


INSERT INTO Enrollments (MemberID, ClassID, Status)
SELECT 
    floor(random() * 10000 + 1)::int, 
    floor(random() * 10000 + 1)::int, 
    (ARRAY['Confirmed', 'Cancelled', 'Waitlist'])[floor(random() * 3 + 1)]
FROM generate_series(1, 10000) AS s(i);



Неоптимізований запит

EXPLAIN ANALYZE
SELECT fc.ClassName, t.TrainerName, COUNT(e.EnrollmentID) AS total_enrollments
FROM FitnessClasses fc
JOIN Trainers t ON fc.TrainerID = t.TrainerID
JOIN Enrollments e ON fc.ClassID = e.ClassID
GROUP BY fc.ClassName, t.TrainerName
HAVING COUNT(e.EnrollmentID) = (
    SELECT MAX(cnt) FROM (
        SELECT COUNT(EnrollmentID) AS cnt
        FROM FitnessClasses f2
        JOIN Enrollments e2 ON f2.ClassID = e2.ClassID
        GROUP BY f2.ClassID
    ) AS sub_max
)

UNION ALL

SELECT fc.ClassName, t.TrainerName, COUNT(e.EnrollmentID) AS total_enrollments
FROM FitnessClasses fc
JOIN Trainers t ON fc.TrainerID = t.TrainerID
JOIN Enrollments e ON fc.ClassID = e.ClassID
GROUP BY fc.ClassName, t.TrainerName
HAVING COUNT(e.EnrollmentID) = (
    SELECT MIN(cnt) FROM (
        SELECT COUNT(EnrollmentID) AS cnt
        FROM FitnessClasses f3
        JOIN Enrollments e3 ON f3.ClassID = e3.ClassID
        GROUP BY f3.ClassID
    ) AS sub_min
);

CREATE INDEX IF NOT EXISTS idx_enrollments_classid ON Enrollments(ClassID);
CREATE INDEX IF NOT EXISTS idx_fitnessclasses_trainerid ON FitnessClasses(TrainerID);

Оптимізований запит

EXPLAIN ANALYZE
WITH ClassCounts AS (
    SELECT fc.ClassName, t.TrainerName, COUNT(e.EnrollmentID) AS total_enrollments
    FROM FitnessClasses fc
    JOIN Trainers t ON fc.TrainerID = t.TrainerID
    JOIN Enrollments e ON fc.ClassID = e.ClassID
    GROUP BY fc.ClassName, t.TrainerName
),
MinMaxValues AS (
    SELECT MAX(total_enrollments) AS max_val, MIN(total_enrollments) AS min_val 
    FROM ClassCounts
)
SELECT c.ClassName, c.TrainerName, c.total_enrollments
FROM ClassCounts c, MinMaxValues m
WHERE c.total_enrollments = m.max_val OR c.total_enrollments = m.min_val;


SET enable_seqscan = OFF;

EXPLAIN ANALYZE
SELECT fc.ClassName, COUNT(e.EnrollmentID) AS total_enrollments
FROM FitnessClasses fc
JOIN Enrollments e ON fc.ClassID = e.ClassID
GROUP BY fc.ClassName;

SET enable_seqscan = ON;
