-- Assumptions:  you have created a database
-- and set a master key.  Replace this with your master key.
OPEN MASTER KEY DECRYPTION BY PASSWORD = '<<SomeSecureKey>>';
GO

-- Public container
-- You are welcome to use this data source.
CREATE EXTERNAL DATA SOURCE PolyBaseRevealedPublicData WITH
(
	TYPE = HADOOP,
	LOCATION = 'wasbs://polybaserevealedpublicdata@cspolybasepublic.blob.core.windows.net'
);

CREATE EXTERNAL FILE FORMAT CsvFileFormat WITH
(
	FORMAT_TYPE = DELIMITEDTEXT,
	FORMAT_OPTIONS
	(
		FIELD_TERMINATOR = N',',
		USE_TYPE_DEFAULT = True,
		STRING_DELIMITER = '"',
		ENCODING = 'UTF8'
	)
);

CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulation
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
    LOCATION = N'NorthCarolinaPopulation.csv',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5
);
GO

SELECT *
FROM dbo.NorthCarolinaPopulation ncp;
GO


-- Private container
-- You'll have to create your own container and fill in the details.
CREATE DATABASE SCOPED CREDENTIAL AzureStorageCredential
WITH IDENTITY = '<Your blob account>',
SECRET = '<Your blob secret>';

CREATE EXTERNAL DATA SOURCE AzureNCPopBlob WITH
(
	TYPE = HADOOP,
	LOCATION = 'wasbs://<Your blob container>@<Your blob account>.blob.core.windows.net',
	CREDENTIAL = AzureStorageCredential
);

CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulationPrivate
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
    LOCATION = N'Census/NorthCarolinaPopulation.csv',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5
);
GO