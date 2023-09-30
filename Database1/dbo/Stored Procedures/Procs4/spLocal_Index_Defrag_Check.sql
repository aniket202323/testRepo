

CREATE PROCEDURE [dbo].[spLocal_Index_Defrag_Check] 
AS
/*
--Must be run in the database to be defragmented.
*/

-- Declare variables

SET NOCOUNT ON
DECLARE @tablename 	VARCHAR (128)
DECLARE @dbname 	sysname
DECLARE @tableid 	INT
DECLARE @tableidchar 	VARCHAR(255)

--check this is being run in a user database
SELECT @dbname = db_name()
IF @dbname IN ('master', 'msdb', 'model', 'tempdb')
BEGIN
PRINT 'This procedure should not be run in system databases.'
RETURN
END

-- checking fragmentation
-- Declare cursor
DECLARE defrag_tables CURSOR FOR
SELECT convert(varchar,so.id)
FROM sysobjects so
JOIN sysindexes si
ON so.id = si.id
WHERE so.type ='U'
AND si.indid < 2
AND si.rows > 0

-- Open the cursor
OPEN defrag_tables

-- Loop through all the tables in the database running dbcc showcontig on each one
FETCH NEXT
FROM defrag_tables
INTO @tableidchar

WHILE @@FETCH_STATUS = 0
BEGIN
-- Do the showcontig of all indexes of the table
INSERT INTO dbo.Local_Index_Defrag 
       ([ObjectName],
	[ObjectId],
	[IndexName],
	[IndexId],
	[Lvl],
	[CountPages],
	[CountRows],
	[MinRecSize],
	[MaxRecSize],
	[AvgRecSize],
	[ForRecCount],
	[Extents],
	[ExtentSwitches],
	[AvgFreeBytes],
	[AvgPageDensity],
	[ScanDensity],
	[BestCount],
	[ActualCount],
	[LogicalFrag],
	[ExtentFrag])
EXEC ('DBCC SHOWCONTIG (' + @tableidchar + ') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
FETCH NEXT
FROM defrag_tables
INTO @tableidchar
END

-- Close and deallocate the cursor
CLOSE defrag_tables
DEALLOCATE defrag_tables




