Create Procedure DBO.spSupport_SpaceUsed
@orderby varchar(20) = 'data' 
AS
SET NOCOUNT ON
DECLARE @cmdstr varchar(100)
DECLARE @Sort bit
--Create Temporary Table
CREATE TABLE #TempTable 
 ( [Table_Name] varchar(50),
 Row_Count int,
 Table_Size varchar(50),
 Data_Space_Used varchar(50),
 Index_Space_Used varchar(50),
 Unused_Space varchar(50)
 )
 SELECT @cmdstr = 'sp_msforeachtable ''sp_spaceused "?"'''
 INSERT INTO #TempTable EXEC(@cmdstr)
 If @orderby = 'data' 
   SELECT * FROM #TempTable ORDER BY len(Data_Space_Used) Desc ,Data_Space_Used Desc
 else if @orderby = 'table' 
   SELECT * FROM #TempTable ORDER BY len(table_size) Desc ,table_size Desc
DROP TABLE #TempTable 
