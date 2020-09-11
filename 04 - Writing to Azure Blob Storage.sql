-- Assumptions:  you have created a database
-- and set a master key.  Replace this with your master key.
OPEN MASTER KEY DECRYPTION BY PASSWORD = '<<SomeSecureKey>>';
GO
-- In case you have not enabled it already, this is
-- how you can configure PolyBase to insert data to
-- V1 external data sources.
EXEC sp_configure
    @configname = 'allow polybase export',
    @configvalue = 1;
GO
RECONFIGURE
GO

CREATE EXTERNAL DATA SOURCE AzureNCPopBlob WITH
(
	TYPE = HADOOP,
	LOCATION = 'wasbs://<Your blob container>@<Your blob account>.blob.core.windows.net',
	CREDENTIAL = AzureStorageCredential
);

-- This script will cause an error.
CREATE EXTERNAL TABLE dbo.SomeTable
(
    -- Identity columns not allowed!
    Id INT IDENTITY(1,1),
    SomeVal INT,
    SomeChar CHAR(10)
)
WITH
(
    LOCATION = N'SomeTable',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);

CREATE EXTERNAL TABLE dbo.SomeTable
(
    SomeVal INT,
    SomeChar CHAR(10)
)
WITH
(
    LOCATION = N'SomeTable',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);

INSERT INTO dbo.SomeTable
(
    SomeVal,
    SomeChar
)
SELECT TOP(100000)
    CHECKSUM(NEWID()),
    CONCAT(LEFT(ao1.name, 5), LEFT(ao2.name, 5))
FROM sys.all_objects ao1
    CROSS JOIN sys.all_objects ao2;

-- These scripts will cause errors.
-- PolyBase does not allow DML actions other than INSERT.
UPDATE dbo.SomeTable SET SomeVal = 1;
DELETE FROM dbo.SomeTable;
TRUNCATE TABLE dbo.SomeTable;

-- You cannot insert into a single file
-- Even if you name the location like a file, it will create a folder.
CREATE EXTERNAL TABLE dbo.SomeTableFile
(
    SomeVal INT,
    SomeChar CHAR(10)
)
WITH
(
    LOCATION = N'SomeTable.csv',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);

INSERT INTO dbo.SomeTableFile
(
    SomeVal,
    SomeChar
)
SELECT TOP(100000)
    CHECKSUM(NEWID()),
    CONCAT(LEFT(ao1.name, 5), LEFT(ao2.name, 5))
FROM sys.all_objects ao1
    CROSS JOIN sys.all_objects ao2;

CREATE EXTERNAL TABLE dbo.SomeTableExistingFile
(
    SomeVal INT,
    SomeChar CHAR(10)
)
WITH
(
    LOCATION = N'Sample.csv',
    DATA_SOURCE = AzureNCPopBlob,
    FILE_FORMAT = CsvFileFormat,
    REJECT_TYPE = VALUE,
    REJECT_VALUE = 0
);

-- Assuming you have a Sample.csv file,
-- this will return an error if you try to 
-- insert.
INSERT INTO dbo.SomeTableExistingFile
(
    SomeVal,
    SomeChar
)
SELECT TOP(100000)
    CHECKSUM(NEWID()),
    CONCAT(LEFT(ao1.name, 5), LEFT(ao2.name, 5))
FROM sys.all_objects ao1
    CROSS JOIN sys.all_objects ao2;