CREATE PROCEDURE dbo.spPurge_GetStartupInfo
 AS
set nocount on
set nocount on
CREATE TABLE  #SpaceTable 
 ( 	 [Table_Name] varchar(50),
 	 Row_Count Bigint,
 	 Table_Size varchar(50),
 	 Data_Space_Used varchar(50),
 	 Index_Space_Used varchar(50),
 	 Unused_Space 	 varchar(50))
Declare @MinId BigInt
Declare @MaxId BigInt
Declare @Data Table(Id BigInt,MinTime DateTime,MaxTime DateTime)
Declare @StartId Int,@NextId Int
DECLARE @FindDates Int
SELECT @FindDates = 1
DECLARE @StartInfo TABLE( 	 TableName 	  	  	 VarChar(100),
 	  	  	  	  	  	  	 Is_Variable 	  	  	 Int,
 	  	  	  	  	  	  	 Is_Unit 	  	  	  	 Int,
 	  	  	  	  	  	  	 Default_Retention 	 Int,
 	  	  	  	  	  	  	 Default_Batch 	  	 Int,
 	  	  	  	  	  	  	 CurrentRowCount 	  	 Bigint,
 	  	  	  	  	  	  	 DataSpace 	  	  	 VarChar(100),
 	  	  	  	  	  	  	 Earliest 	  	  	 DateTime,
 	  	  	  	  	  	  	 Latest 	  	  	  	 DateTime)
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Active_Specs''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,0,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(Effective_Date) FROM Active_Specs WHERE Effective_Date Is Not Null) WHERE TableName = 'Active_Specs'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(Effective_Date) FROM Active_Specs WHERE Effective_Date Is Not Null) WHERE TableName = 'Active_Specs'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Alarms''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,0,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(End_time) FROM Alarms WHERE End_time Is Not Null) WHERE TableName = 'Alarms'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(End_time) FROM Alarms WHERE End_time Is Not Null) WHERE TableName = 'Alarms'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Report_Engine_Activity''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,0,36,5000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 SELECT @MinId = Min(REA_Id) From report_engine_Activity
 	 SELECT @MaxId = Max(REA_Id) From report_engine_Activity
 	 UPDATE @StartInfo SET Earliest = (SELECT Time From report_engine_Activity where REA_Id = @MinId) WHERE TableName = 'Report_Engine_Activity'
 	 UPDATE @StartInfo SET Latest = (select Time From report_engine_Activity where REA_Id = @MaxId) WHERE TableName = 'Report_Engine_Activity'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Sheet_Columns''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,0,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 DELETE FROM @Data
 	 Select @StartId = Null
 	 SELECT @StartId = Min(Sheet_Id) From Sheets
 	 While @StartId Is Not Null
 	 BEGIN
 	  	 INSERT INTO @Data(Id,MinTime,MaxTime)
 	  	  	 SELECT @StartId,Min(Result_On),Max(Result_On)
 	  	  	  	 FROM Sheet_Columns WHERE Sheet_Id = @StartId
 	  	 Select @NextId = Null
 	  	 SELECT @NextId = Min(Sheet_Id) From Sheets WHERE  Sheet_Id > @StartId
 	  	 SELECT @StartId = @NextId
 	 END
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(MinTime) FROM @Data WHERE MinTime is not null) WHERE TableName = 'Sheet_Columns'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(MaxTime) FROM @Data  WHERE MaxTime is not null) WHERE TableName = 'Sheet_Columns'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Var_Specs''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,0,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(Effective_Date) FROM Var_Specs WHERE Effective_Date Is Not Null) WHERE TableName = 'Var_Specs'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(Effective_Date) FROM Var_Specs WHERE Effective_Date Is Not Null) WHERE TableName = 'Var_Specs'
END
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT 'Deleted_Variables',0,0,36,10000,COUNT(*),' '
 	 FROM  Variables where PU_Id = 0
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Timed_Event_Details''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 SELECT @MinId = Min(TEDet_Id) From Timed_Event_Details
 	 SELECT @MaxId = Max(TEDet_Id) From Timed_Event_Details
 	 UPDATE @StartInfo SET Earliest = (SELECT Start_Time From Timed_Event_Details where TEDet_Id = @MinId) WHERE TableName = 'Timed_Event_Details'
 	 UPDATE @StartInfo SET Latest = (select Start_Time From Timed_Event_Details where TEDet_Id = @MaxId) WHERE TableName = 'Timed_Event_Details'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Waste_Event_Details''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 DELETE FROM @Data
 	 INSERT INTO @Data(Id,MinTime)
 	  	 SELECT Top 1000 WED_Id,TimeStamp
 	  	  	 FROM Waste_Event_Details order by WED_Id
 	 SELECT @MaxId = Max(WED_Id) From Waste_Event_Details
 	 UPDATE @StartInfo SET Earliest = (SELECT min(MinTime) FROM @Data) WHERE TableName = 'Waste_Event_Details'
 	 UPDATE @StartInfo SET Latest   = (SELECT TimeStamp FROM Waste_Event_Details WHERE WED_Id = @MaxId) WHERE TableName = 'Waste_Event_Details'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Events''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
SELECT @MinId = Min(Event_Id) From Events
SELECT @MaxId = Max(Event_Id) From Events
IF @FindDates > 0
BEGIN
 	 UPDATE @StartInfo SET Earliest = (SELECT TimeStamp FROM Events WHERE Event_Id = @MinId) WHERE TableName = 'Events'
 	 UPDATE @StartInfo SET Latest   = (SELECT TimeStamp FROM Events WHERE Event_Id = @MaxId) WHERE TableName = 'Events'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''GB_RSum''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,500,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 SELECT @MinId = Min(RSum_Id) From GB_RSum
 	 SELECT @MaxId = Max(RSum_Id) From GB_RSum
 	 UPDATE @StartInfo SET Earliest = (SELECT Start_Time FROM GB_RSum WHERE RSum_Id = @MinId) WHERE TableName = 'GB_RSum'
 	 UPDATE @StartInfo SET Latest   = (SELECT Start_Time FROM GB_RSum WHERE RSum_Id = @MaxId) WHERE TableName = 'GB_RSum'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Production_Starts''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,500,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(End_time) FROM Production_Starts WHERE End_time Is Not Null) WHERE TableName = 'Production_Starts'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(Start_Time) FROM Production_Starts) WHERE TableName = 'Production_Starts'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''Tests''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,1,0,36,10000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 DELETE FROM @Data
 	 INSERT INTO @Data(Id,MinTime)
 	  	 SELECT Top 1000 Test_Id,result_on
 	  	  	 FROM Tests order by test_id
 	 SELECT @MaxId = Max(Test_Id) From Tests
 	 UPDATE @StartInfo SET Earliest = (SELECT min(MinTime) FROM @Data) WHERE TableName = 'Tests'
 	 UPDATE @StartInfo SET Latest   = (SELECT Result_on FROM Tests WHERE Test_id = @MaxId) WHERE TableName = 'Tests'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''User_Defined_Events''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,1000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 DELETE FROM @Data
 	 Select @StartId = Null
 	 SELECT @StartId = Min(PU_Id) From Prod_Units
 	 While @StartId Is Not Null
 	 BEGIN
 	  	 INSERT INTO @Data(Id,MinTime,MaxTime)
 	  	  	 SELECT @StartId,Min(End_time),Max(End_time)
 	  	  	  	 FROM User_Defined_Events WHERE PU_Id = @StartId and End_time Is Not Null
 	  	 Select @NextId = Null
 	  	 SELECT @NextId = Min(PU_Id) From Prod_Units WHERE  PU_Id > @StartId
 	  	 SELECT @StartId = @NextId
 	 END
 	 UPDATE @StartInfo SET Earliest = (SELECT MIN(MinTime) FROM @Data WHERE MinTime is not null) WHERE TableName = 'User_Defined_Events'
 	 UPDATE @StartInfo SET Latest = (SELECT MAX(MaxTime) FROM @Data  WHERE MaxTime is not null) WHERE TableName = 'User_Defined_Events'
END
DELETE FROM #SpaceTable
INSERT INTO #SpaceTable EXEC('sp_spaceused ''OEEAggregation''')
INSERT INTO @StartInfo(TableName,Is_Variable,Is_Unit,Default_Retention,Default_Batch,CurrentRowCount,DataSpace) 
 	 SELECT Table_Name,0,1,36,5000,Row_Count,Data_Space_Used
 	 FROM  #SpaceTable
IF @FindDates > 0
BEGIN
 	 SELECT @MinId = Min(OEEAggregation_Id) From OEEAggregation
 	 SELECT @MaxId = Max(OEEAggregation_Id) From OEEAggregation
 	 UPDATE @StartInfo SET Earliest = (SELECT Start_Time FROM OEEAggregation WHERE OEEAggregation_Id = @MinId) WHERE TableName = 'OEEAggregation'
 	 UPDATE @StartInfo SET Latest   = (SELECT Start_Time FROM OEEAggregation WHERE OEEAggregation_Id = @MaxId) WHERE TableName = 'OEEAggregation'
END
UPDATE @StartInfo SET DataSpace = Replace(DataSpace,' KB','')
Drop table #SpaceTable
SELECT [Table] = TableName,
Is_Variable,
Is_Unit,
[Retention Limit] = Default_Retention,
[Batch Size] = Default_Batch,
[Row Count] = CurrentRowCount,
[Space (KB)] = DataSpace,
[Earliest Date] = Earliest,
[Latest Date] = Latest 
FROM @StartInfo Order by TableName
