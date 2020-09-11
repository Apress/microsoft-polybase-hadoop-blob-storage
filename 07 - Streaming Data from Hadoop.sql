-- Assumptions:  you have created a database
-- and set a master key.  Replace this with your master key.
OPEN MASTER KEY DECRYPTION BY PASSWORD = '<<SomeSecureKey>>';
GO

CREATE EXTERNAL DATA SOURCE Clusterino WITH
(
	TYPE = HADOOP,
	LOCATION = 'hdfs://<Your HDFS host>:8020',
    RESOURCE_MANAGER_LOCATION = N'<Your YARN host>:8050'
);

CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulationHadoop
(
    SumLev INT NOT NULL,
    County INT NOT NULL,
    Place INT NOT NULL,
    IsPrimaryGeography BIT NOT NULL,
    [Name] VARCHAR(120) NOT NULL,
    PopulationType VARCHAR(20) NOT NULL,
    Year INT NOT NULL,
    Population INT NOT NULL
)
WITH
(
    LOCATION = N'PolyBaseData/NorthCarolinaPopulation.csv',
    DATA_SOURCE = Clusterino,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5
);
GO

SELECT *
FROM dbo.NorthCarolinaPopulationHadoop ncp;
GO

-- Much larger table
-- You can get the ORC files from:
-- https://cspolybasepublic.blob.core.windows.net/polybaserevealedpublicdata/NYCParkingTicketsORC.zip
-- But note that this is 1GB in size.
-- Unzip the files and import them into HDFS.
CREATE EXTERNAL FILE FORMAT OrcFileFormat WITH
(
    FORMAT_TYPE = ORC,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.DefaultCodec'
);

CREATE EXTERNAL TABLE ParkingViolationsORC
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
    VehicleYear VARCHAR(50),
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
    LOCATION = N'/PolyBaseData/NYCParkingTicketsORC/',
    DATA_SOURCE = Clusterino,
    FILE_FORMAT = OrcFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5000
);
GO

SELECT COUNT(1) FROM dbo.ParkingViolationsORC
OPTION(DISABLE EXTERNALPUSHDOWN);

SELECT
	RegistrationState,
	COUNT(*) AS NumberOfViolations
FROM dbo.ParkingViolationsORC
GROUP BY
	RegistrationState
ORDER BY
	RegistrationState
OPTION(DISABLE EXTERNALPUSHDOWN);