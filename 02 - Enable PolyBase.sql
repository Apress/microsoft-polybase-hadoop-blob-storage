USE [master]
GO
-- Enable PolyBase
EXEC sp_configure 'polybase enabled', 1;
GO
RECONFIGURE
GO
-- Enable PolyBase writing
EXEC sp_configure 'show advanced', 1;
GO
RECONFIGURE
GO
EXEC sp_configure 'allow polybase export', 1;
GO
RECONFIGURE
GO
-- Now restart the PolyBase engine and data movement services