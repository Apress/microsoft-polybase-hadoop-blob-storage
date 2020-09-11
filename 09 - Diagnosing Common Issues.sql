-- Demo 9 setup
-- Shut off PolyBase services, then run the following:
OPEN MASTER KEY DECRYPTION BY PASSWORD = '<<SomeSecureKey>>';
GO
SELECT * FROM dbo.NorthCarolinaPopulation;

-- Troubleshooting connectivity settings:
EXEC sp_configure 'polybase enabled'
EXEC sp_configure 'allow polybase'
GO
-- Check whether services are on

-- Review mapdred-site.xml and yarn-site.xml
-- Typically in %PROGRAMFILES%\MSSQL[##].MSSQLSERVER\MSSQL \Binn\Polybase\Hadoop\conf

-- Try a protected external data source without credentials
-- You can try my external data source--it will give you an error.
CREATE EXTERNAL DATA SOURCE AzureNCPopBlobBad WITH
(
	TYPE = HADOOP,
	LOCATION = 'wasbs://ncpop@cspolybase.blob.core.windows.net'
);

CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulationBad
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
    DATA_SOURCE = AzureNCPopBlobBad,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5
);
GO

SELECT * FROM dbo.NorthCarolinaPopulationBad;
GO

-- Try an invalid URL
CREATE EXTERNAL TABLE dbo.NorthCarolinaPopulationBad
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
    LOCATION = N'NotARealFile.csv',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 5
);
GO

SELECT * FROM dbo.NorthCarolinaPopulationBad;
GO

-- Try to force pushdown on Azure Blob Storage
SELECT * FROM dbo.NorthCarolinaPopulation OPTION(FORCE EXTERNALPUSHDOWN);

-- Review Hadoop data nodes
-- Check if /etc/hosts has entries for 127.0.0.1

-- Two files with different counts of columns
-- First, try with three columns.
CREATE EXTERNAL TABLE dbo.DifferentColumnCounts
(
    RowNum INT,
	RowChar CHAR(1),
	RowValue INT
)
WITH
(
    LOCATION = N'BadDataTests/DifferentColumnCounts/',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.DifferentColumnCounts;
GO

-- Then, try with four columns.
DROP EXTERNAL TABLE dbo.DifferentColumnCounts;
GO
CREATE EXTERNAL TABLE dbo.DifferentColumnCounts
(
    RowNum INT,
	RowChar CHAR(1),
	RowValue INT,
	RowOtherChar CHAR(1) NULL
)
WITH
(
    LOCATION = N'BadDataTests/DifferentColumnCounts/',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.DifferentColumnCounts;
GO

-- Finally, try with five columns.
DROP EXTERNAL TABLE dbo.DifferentColumnCounts;
GO
CREATE EXTERNAL TABLE dbo.DifferentColumnCounts
(
    RowNum INT,
	RowChar CHAR(1),
	RowValue INT,
	RowOtherChar CHAR(1) NULL,
    NotARealColumn INT NULL
)
WITH
(
    LOCATION = N'BadDataTests/DifferentColumnCounts/',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.DifferentColumnCounts;
GO

-- Two files with different formats
CREATE EXTERNAL TABLE dbo.DifferentFormats
(
    SomeData VARCHAR(100),
	SomeDate DATE,
	SomeVal INT
)
WITH
(
    LOCATION = N'BadDataTests/DifferentFileFormats/',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.DifferentFormats;
GO

-- File with extra newlines
CREATE EXTERNAL TABLE dbo.ExtraNewlines
(
	SomeVal INT,
	SomeVal2 INT,
    SomeData VARCHAR(2000)	
)
WITH
(
    LOCATION = N'BadDataTests/ExtraNewlines.csv',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.ExtraNewlines;
GO

-- File with extra-wide lines
CREATE EXTERNAL TABLE dbo.ExtraWideLines
(
	SomeVal INT,
	SomeVal2 INT,
    SomeData VARCHAR(8000)	
)
WITH
(
    LOCATION = N'BadDataTests/WideLoad.csv',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.ExtraWideLines;
GO

-- Go over 32K -- looks like 2019 extended the max size beyond 32K,
-- so this may actually work for you.  According to the documentation,
-- however, this should fail.
CREATE EXTERNAL TABLE dbo.WideData
(
	SomeVal INT,
	SomeVal2 INT,
    A VARCHAR(8000),
	B VARCHAR(8000),
	C VARCHAR(8000),
	D VARCHAR(8000),
	E VARCHAR(8000)
)
WITH
(
    LOCATION = N'BadDataTests/WideData.csv',
    DATA_SOURCE = PolyBaseRevealedPublicData,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);
GO
SELECT * FROM dbo.WideData;
GO

-- Cleanup
DROP EXTERNAL TABLE dbo.NorthCarolinaPopulationBad;
DROP EXTERNAL DATA SOURCE AzureNCPopBlobBad;
DROP EXTERNAL TABLE dbo.DifferentColumnCounts;
DROP EXTERNAL TABLE dbo.DifferentFormats;
DROP EXTERNAL TABLE dbo.ExtraNewlines;
DROP EXTERNAL TABLE dbo.ExtraWideLines;
DROP EXTERNAL TABLE dbo.WideData;