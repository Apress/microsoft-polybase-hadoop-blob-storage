-- Assumptions:  you have created a database
-- and set a master key.  Replace this with your master key.
OPEN MASTER KEY DECRYPTION BY PASSWORD = '<<SomeSecureKey>>';
GO
SELECT
    RegistrationState,
    COUNT(*) AS NumberOfViolations
FROM dbo.ParkingViolationsORC
GROUP BY
    RegistrationState
HAVING
    COUNT(*) > 500
ORDER BY
    NumberOfViolations DESC
OPTION(DISABLE EXTERNALPUSHDOWN);
GO

SELECT
    RegistrationState,
    COUNT(*) AS NumberOfViolations
FROM dbo.ParkingViolationsORC
GROUP BY
    RegistrationState
HAVING
    COUNT(*) > 500
ORDER BY
    NumberOfViolations DESC
OPTION(FORCE EXTERNALPUSHDOWN);

-- Review running jobs:
-- http://clusterino:8088/cluster/apps
-- http://clusterino:8088/ui2/#/yarn-apps/apps
-- http://clusterino:8080/#/main/services/YARN/summary
	-- Select YARN --> ResourceManager UI --> Applications

SELECT
	execution_id,
	step_index,
	total_elapsed_time,
	row_count,
	command
FROM sys.dm_exec_distributed_request_steps
ORDER BY
    execution_id DESC,
    step_index ASC;

-- Get the parking tickets from the following URLs:
-- https://cspolybasepublic.blob.core.windows.net/polybaserevealedpublicdata/Parking_Violations_Issued_-_Fiscal_Year_2015.7z
-- https://cspolybasepublic.blob.core.windows.net/polybaserevealedpublicdata/Parking_Violations_Issued_-_Fiscal_Year_2016.7z
-- https://cspolybasepublic.blob.core.windows.net/polybaserevealedpublicdata/Parking_Violations_Issued_-_Fiscal_Year_2017.7z
-- You will need a tool like 7-Zip to unzip these.
-- Note that each of these is over 1 GB unzipped
CREATE EXTERNAL TABLE ParkingViolationsNum
(
    SummonsNumber VARCHAR(50),
    PlateID VARCHAR(120),
    RegistrationState VARCHAR(30),
    PlateType VARCHAR(50),
    IssueDate VARCHAR(50),
    ViolationCode VARCHAR(50),
    VehicleBodyType VARCHAR(50),
    VehicleMake VARCHAR(50),
    IssuingAgency VARCHAR(50),
    StreetCode1 VARCHAR(50),
    StreetCode2 VARCHAR(50),
    StreetCode3 VARCHAR(50),
    VehicleExpirationDate VARCHAR(50),
    ViolationLocation VARCHAR(50),
    ViolationPrecinct VARCHAR(50),
    IssuerPrecinct VARCHAR(50),
    IssuerCode VARCHAR(50),
    IssuerCommand VARCHAR(100),
    IssuerSquad VARCHAR(100),
    ViolationTime VARCHAR(100),
    TimeFirstObserved VARCHAR(100),
    ViolationCounty VARCHAR(100),
    ViolationInFrontOfOrOpposite VARCHAR(100),
    HouseNumber VARCHAR(50),
    StreetName VARCHAR(100),
    IntersectingStreet VARCHAR(100),
    DateFirstObserved VARCHAR(50),
    LawSection VARCHAR(30),
    SubDivision VARCHAR(50),
    ViolationLegalCode VARCHAR(100),
    DaysParkingInEffect VARCHAR(50),
    FromHoursInEffect VARCHAR(50),
    ToHoursInEffect VARCHAR(50),
    VehicleColor VARCHAR(50),
    UnregisteredVehicle VARCHAR(50),
    VehicleYear INT,
    MeterNumber VARCHAR(50),
    FeetFromCurb VARCHAR(50),
    ViolationPostCode VARCHAR(30),
    ViolationDescription VARCHAR(150),
    NoStandingorStoppingViolation VARCHAR(50),
    HydrantViolation VARCHAR(50),
    DoubleParkingViolation VARCHAR(50)
)
WITH
(
    LOCATION = N'/PolyBaseData/NYCParkingTickets/',
    DATA_SOURCE = Clusterino,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5000
);

SELECT
	ViolationPrecinct,
	COUNT(*) AS NumberOfViolations
FROM dbo.ParkingViolationsNum pv
WHERE
	pv.RegistrationState = 'OH'
	AND pv.VehicleYear >= 2005 AND pv.VehicleYear <= 2010
GROUP BY
	ViolationPrecinct
ORDER BY
	NumberOfViolations DESC
OPTION(FORCE EXTERNALPUSHDOWN);

CREATE TABLE #Age
(
	VehicleYear INT,
	Age VARCHAR(20)
);
INSERT INTO #Age
(
	VehicleYear,
	Age
)
VALUES
	(2000, '2000-2004'), (2001, '2000-2004'), (2002, '2000-2004'),
	(2003, '2000-2004'), (2004, '2000-2004'), (2005, '2005-2009'),
	(2006, '2005-2009'), (2007, '2005-2009'), (2008, '2005-2009'),
	(2009, '2005-2009'), (2010, '2010-2014'), (2011, '2010-2014'),
    (2012, '2005-2009'), (2013, '2010-2014'), (2014, '2010-2014');

SELECT
	ViolationPrecinct,
	COUNT(*) AS NumberOfViolations
FROM dbo.ParkingViolationsNum pv
    INNER JOIN #Age a
        ON pv.VehicleYear = a.VehicleYear
WHERE
	pv.RegistrationState = 'OH'
	AND a.Age = '2005-2009'
GROUP BY
	ViolationPrecinct
ORDER BY
	NumberOfViolations DESC
OPTION(FORCE EXTERNALPUSHDOWN);