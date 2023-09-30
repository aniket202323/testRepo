  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
-- Version 1.1 2004-APR-20 Langdon Davis  
--  
-- This SP will gather data for the specified date/time range for a program to display Line Status  
-- data for Proficy Client computers.  The data is for a specific Master Unit.  The data provided is:  
-- 1.  Stops data by Location.  
-- 2.  Stops data by Failure Mode.    
-- 3.  Stops data by Failure Mode Cause.  
--  
-- 2003-05-18 Vince King  
--  - Removed SchedChangeOverId, not used any more.  
--  
-- 2004-APR-20 Langdon Davis Rev1.1  
--  - Deleted unused program variables.  
--  
--------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE  PROCEDURE dbo.spLocal_ViewCvtgPack  
 @StartTime   DateTime,  -- Beginning period for the data.  
 @EndTime   DateTime,  -- Ending period for the data.  
 @ProdUnit   Int,   -- Prod_Units.PU_Id for the Master Unit selected.  
 @ScheduleStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatBlockStarvedId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @CatELPId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId   Int,   -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @DelayTypeRateLossStr  nVarChar(100)  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
  
AS  
  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON   
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE(  
 ErrMsg    nVarChar(255) )  
  
CREATE TABLE #Delays (  
 TEDetId    Int Primary Key,  
 PrimaryId   Int,  
 SecondaryId   Int,  
 PUId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime,  
 LocationId   Int,  
 L1ReasonId   Int,  
 L2ReasonId   Int,  
 L3ReasonId   Int,  
 L4ReasonId   Int,  
 TEFaultId   Int,  
 L1TreeNodeId   Int,  
 L2TreeNodeId   Int,  
 L3TreeNodeId   Int,  
 L4TreeNodeId   Int,  
 ProdId    Int,  
 LineStatus   nVarChar(50),  
 Shift    nVarChar(10),  
 Crew    nVarChar(10),  
 ScheduleId   Int,  
 CategoryId   Int,  
 GroupCauseId   Int,  
 SubSystemId   Int,  
 DownTime   Int,  
 ReportDownTime   Int,  
 UpTime    Int,  
 ReportUpTime   Int,  
 Stops    Int,  
 StopsUnscheduled  Int,  
 Stops2m    Int,  
 StopsMinor   Int,  
 StopsBreakDowns   Int,  
 StopsProcessFailures  Int,  
 StopsELP   Int,  
 ReportELPDowntime  Int,  
 StopsBlockedStarved  Int,  
 UpTime2m   Int,  
 ReportRLDowntime  Float,  
 StopsRL    Int )  
CREATE INDEX td_PUId_StartTime  
 ON #Delays (PUId, StartTime)  
CREATE INDEX td_PUId_EndTime  
 ON #Delays (PUId, EndTime)  
DECLARE @ProdUnits TABLE(  
 PUId    Int Primary Key,  
 PLId    Int,  
 ExtendedInfo   nVarChar(255),  
 DelayType   nVarChar(100),  
 ScheduleUnit   Int,  
 LineStatusUnit   Int )  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @CatMechEquipId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatMechEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @CatElectEquipId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatElectEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @CatProcFailId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatProcFailId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @CatBlockStarvedId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatBlockStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @SchedPRPolyId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedPRPolyId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @SchedUnscheduledId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnscheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM [dbo].Event_Reason_Catagories WHERE ERC_Id = @CatELPId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CateELPId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VarChar(4),YEAR(GetDate())) + '-' + CONVERT(VarChar(2),MONTH(GetDate())) + '-' +   
     CONVERT(VarChar(2),DAY(GetDate())) + ' ' + CONVERT(VarChar(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VarChar(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VarChar(2),DATEPART(ss,@EndTime))  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE @Position   Int,  
 @PartialString   nVarChar(4000),  
 @Now    DateTime,  
 @@Id    Int,  
 @@ExtendedInfo   nVarChar(255),  
 @PUDelayTypeStr   nVarChar(100),  
 @PUScheduleUnitStr  nVarChar(100),  
 @PULineStatusUnitStr  nVarChar(100),  
 @@PUId    Int,  
 @@TimeStamp   DateTime,  
 @@LastEndTime   DateTime,  
 @@NextStartTime   datetime,  
 @@StartTime   datetime,  
 @@EndTime   datetime,  
 @DelayTypeDesc   nVarChar(100),  
 @DelayTypeCvtrStr  nVarChar(100)  
  
SELECT @Now = GetDate(),  
 @PUDelayTypeStr = 'DelayType=',  
 @PUScheduleUnitStr = 'ScheduleUnit=',  
 @PULineStatusUnitStr = 'LineStatusUnit=',  
 @DelayTypeCvtrStr = 'CvtrDowntime'  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT @ProdUnits (PUId, PLId, ExtendedInfo)  
 SELECT PU_Id, PL_Id, Extended_Info  
  FROM [dbo].Prod_Units   
  WHERE PU_Id = @ProdUnit  
  
DECLARE ProdUnitCursor INSENSITIVE CURSOR FOR  
 (SELECT PUId, ExtendedInfo  
  FROM @ProdUnits)  
 FOR READ ONLY  
OPEN ProdUnitCursor  
FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@ExtendedInfo  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @Position = CharIndex(@PUDelayTypeStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUDelayTypeStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  SELECT  @DelayTypeDesc = @PartialString  
  UPDATE @ProdUnits  
   SET DelayType = @PartialString  
   WHERE PUId = @@Id  
 END  
 SELECT @Position = CharIndex(@PUScheduleUnitStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUScheduleUnitStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE @ProdUnits  
   SET ScheduleUnit = @PartialString  
   WHERE PUId = @@Id  
 END  
 SELECT @Position = CharIndex(@PULineStatusUnitStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PULineStatusUnitStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE @ProdUnits  
   SET LineStatusUnit = @PartialString  
   WHERE PUId = @@Id  
 END  
  
 FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@ExtendedInfo  
END  
CLOSE ProdUnitCursor  
DEALLOCATE ProdUnitCursor  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
INSERT #Delays (TEDetId, PUId, StartTime, EndTime, LocationId,  
 L1ReasonId, L2ReasonId, L3ReasonId, L4ReasonId, TEFaultId,  
 DownTime,  
 ReportDownTime,  
 PrimaryId, SecondaryId)  
 SELECT ted.TEDet_Id, ted.PU_Id, ted.Start_Time, Coalesce(ted.End_Time, @Now), ted.Source_PU_Id,  
  ted.Reason_Level1, ted.Reason_Level2, ted.Reason_Level3, ted.Reason_Level4, ted.TEFault_Id,  
  DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),  
  DateDiff(Second, (CASE WHEN ted.Start_Time < @StartTime THEN @StartTime ELSE ted.Start_Time END),  
   (CASE WHEN Coalesce(ted.End_Time, @Now) > @EndTime THEN @EndTime ELSE Coalesce(ted.End_Time, @Now) END)),  
  ted2.TEDet_Id, ted3.TEDet_Id  
  FROM  [dbo].Timed_Event_Details ted  
--  JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
  LEFT JOIN [dbo].Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
    AND ted.Start_Time = ted2.End_Time  
    AND ted.TEDet_Id <> ted2.TEDet_Id  
  LEFT JOIN [dbo].Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
    AND ted.End_Time = ted3.Start_Time  
    AND ted.TEDet_Id <> ted3.TEDet_Id  
  WHERE  ted.Start_Time < @EndTime  
  AND  (ted.End_Time >= @StartTime  
    OR ted.End_Time IS NULL)  
  AND  ted.PU_Id = @ProdUnit  
-------------------------------------------------------------------------------  
-- Add the detail records that span either end of this collection but may not be  
-- in the data set.  These are records related to multi-downtime events where only  
-- one of the set is within the Report Period.  
-------------------------------------------------------------------------------  
-- Multi-event downtime records that span prior to the Report Period.  
WHILE (SELECT Count(td1.TEDetId)  
  FROM #Delays td1  
  LEFT JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.PrimaryId IS NOT NULL) > 0  
 INSERT #Delays (TEDetId, PUId, StartTime, EndTime, LocationId,  
  L1ReasonId, L2ReasonId, L3ReasonId, L4ReasonId, TEFaultId,  
  DownTime, ReportDownTime,  
  PrimaryId)  
  SELECT ted.TEDet_Id, ted.PU_Id, ted.Start_Time, Coalesce(ted.End_Time, @Now), ted.Source_PU_Id,  
   ted.Reason_Level1, ted.Reason_Level2, ted.Reason_Level3, ted.Reason_Level4, ted.TEFault_Id,  
   DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)), 0,  
   ted2.TEDet_Id  
   FROM  [dbo].Timed_Event_Details ted  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN [dbo].Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
     AND ted.Start_Time = ted2.End_Time  
     AND ted.TEDet_Id <> ted2.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.PrimaryId  
        FROM #Delays td1  
        LEFT JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.PrimaryId IS NOT NULL)  
-- Multi-event downtime records that span after the Report Period.  
WHILE (SELECT Count(td1.TEDetId)  
  FROM #Delays td1  
  LEFT JOIN #Delays td2 ON td1.SecondaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.SecondaryId IS NOT NULL) > 0  
 INSERT #Delays (TEDetId, PUId, StartTime, EndTime, LocationId,  
  L1ReasonId, L2ReasonId, L3ReasonId, L4ReasonId, TEFaultId,  
  DownTime, ReportDownTime,  
  SecondaryId)  
  SELECT ted.TEDet_Id, ted.PU_Id, ted.Start_Time, Coalesce(ted.End_Time, @Now), ted.Source_PU_Id,  
   ted.Reason_Level1, ted.Reason_Level2, ted.Reason_Level3, ted.Reason_Level4, ted.TEFault_Id,  
   DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)), 0,  
   ted3.TEDet_Id  
   FROM  [dbo].Timed_Event_Details ted  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN [dbo].Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
     AND ted.End_Time = ted3.Start_Time  
     AND ted.TEDet_Id <> ted3.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.SecondaryId  
        FROM #Delays td1  
        LEFT JOIN #Delays td2 ON td1.SecondaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.SecondaryId IS NOT NULL)  
-------------------------------------------------------------------------------  
-- If the dataset has more than 65000 records, then send an error message and  
-- suspend processing.  This is because Excel can not handle more than 65536 rows  
-- in a spreadsheet.  
-------------------------------------------------------------------------------  
IF (SELECT Count(TEDetId)  
  FROM #Delays) > 65000  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The dataset contains more than 65000 rows.  This exceeds the Excel limit.')  
 GOTO DropTables  
END  
  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM #Delays td1  
  JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 UPDATE td1  
  SET PrimaryId = td2.PrimaryId  
  FROM #Delays td1  
  JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
UPDATE #Delays  
 SET PrimaryId = TEDetId  
 WHERE PrimaryId IS NULL  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ProdId = ps.Prod_Id  
 FROM #Delays td  
 JOIN [dbo].Production_Starts ps ON td.PUId = ps.PU_Id  
  AND td.StartTime >= ps.Start_Time  
  AND (td.StartTime < ps.End_Time  
   OR ps.End_Time IS NULL)  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Shift = cs.Shift_Desc,  
  Crew = cs.Crew_Desc  
 FROM #Delays td  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN [dbo].Crew_Schedule cs ON tpu.ScheduleUnit = cs.PU_Id  
  AND td.StartTime >= cs.Start_Time  
  AND td.StartTime < cs.End_Time  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
DECLARE DelaysCursor INSENSITIVE CURSOR FOR  
 (SELECT StartTime, PUId  
  FROM #Delays)  
 FOR READ ONLY  
OPEN DelaysCursor  
FETCH NEXT FROM DelaysCursor INTO @@Timestamp, @@PUId  
WHILE @@Fetch_Status = 0  
BEGIN  
 UPDATE td  
  SET LineStatus = (SELECT TOP 1 P.Phrase_Value  
     FROM [dbo].Local_PG_Line_Status LS  
     JOIN [dbo].Phrase P ON LS.Line_Status_Id = P.Phrase_Id  
     JOIN @ProdUnits pu ON pu.PUId = @@PUId  
     WHERE LS.Start_DateTime <= @@Timestamp  
      AND pu.LineStatusUnit = LS.Unit_Id  
     ORDER BY LS.Start_DateTime DESC)  
 FROM #Delays td  
 WHERE PUId = @@PUId AND StartTime = @@Timestamp  
 FETCH NEXT FROM DelaysCursor INTO @@Timestamp, @@PUId  
END  
CLOSE DelaysCursor  
DEALLOCATE DelaysCursor  
  
-------------------------------------------------------------------------------  
-- Retrieve the Tree Node Ids so we can get the associated categories.  
-------------------------------------------------------------------------------  
-- Level 1.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L1TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN [dbo].Prod_Events pe ON td.LocationId = pe.PU_Id  
  AND pe.Event_Type = 2  
 JOIN [dbo].Event_Reason_Tree_Data ertd ON pe.Name_Id = ertd.Tree_Name_Id  
  AND ertd.Event_Reason_Level = 1  
  AND ertd.Event_Reason_Id = td.L1ReasonId  
-------------------------------------------------------------------------------  
-- Level 2.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L2TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN [dbo].Event_Reason_Tree_Data ertd ON td.L1TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 2  
  AND ertd.Event_Reason_Id = td.L2ReasonId  
-------------------------------------------------------------------------------  
-- Level 3.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L3TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN [dbo].Event_Reason_Tree_Data ertd ON td.L2TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 3  
  AND ertd.Event_Reason_Id = td.L3ReasonId  
-------------------------------------------------------------------------------  
-- Level 4.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L4TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN [dbo].Event_Reason_Tree_Data ertd ON td.L3TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 4  
  AND ertd.Event_Reason_Id = td.L4ReasonId  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- lowest point on the tree.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ScheduleId = erc.ERC_Id  
  
 FROM #Delays td  
 JOIN [dbo].Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN [dbo].Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
UPDATE td  
 SET CategoryId = erc.ERC_Id  
 FROM #Delays td  
 JOIN [dbo].Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN [dbo].Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @CategoryStr + '%'  
/* -- These categories are currently not used in the DDS report.  Removed to save processing time.  
UPDATE td  
 SET GroupCauseId = erc.ERC_Id  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @GroupCauseStr + '%'  
UPDATE td  
 SET SubSystemId = erc.ERC_Id  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @SubSystemStr + '%'  
*/  
-------------------------------------------------------------------------------  
-- Populate a separate temporary table that only contains the Primary records.  
-- This allows us to perform aggregates of the DownTime and also to retrieve the  
-- EndTime of the previous downtime event which is used to calculate UpTime.  
-------------------------------------------------------------------------------  
CREATE TABLE #Primaries (  
 TEDetId    Int Primary Key,  
 PUId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime,  
 ScheduleId   Int,  
 CategoryId   Int,  
 DownTime   Int,  
 ReportDownTime   Int,  
 LastEndTime   DateTime,  
 UpTime    Int,  
 ReportUpTime   Int,  
 Stops    Int,  
 StopsUnscheduled  Int,  
 Stops2m    Int,  
 StopsMinor   Int,  
 StopsBreakDowns   Int,  
 StopsProcessFailures  Int,  
 StopsELP   Int,  
 ReportELPDowntime  Int,  
 StopsBlockedStarved  Int,  
 UpTime2m   Int )  
INSERT #Primaries (TEDetId, PUId, StartTime, EndTime,  
 ScheduleId, CategoryId, DownTime, ReportDownTime)  
 SELECT td1.TEDetId, td1.PUId, Min(td2.StartTime), Max(td2.EndTime),  
  td1.ScheduleId, td1.CategoryId, Sum(td2.DownTime), Sum(td2.ReportDownTime)  
  FROM #Delays td1  
  JOIN #Delays td2 ON td1.TEDetId = td2.PrimaryId  
  WHERE td1.TEDetId = td1.PrimaryId  
  GROUP BY td1.TEDetId, td1.PUId, td1.ScheduleId, td1.CategoryId  
DECLARE PrimariesCursor INSENSITIVE CURSOR FOR  
 (SELECT TEDetId, PUId, StartTime  
  FROM #Primaries)  
 FOR READ ONLY  
OPEN PrimariesCursor  
FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @@LastEndTime = NULL  
 SELECT @@LastEndTime = Max(End_Time)  
  FROM [dbo].Timed_Event_Details  
  WHERE PU_Id = @@PUId  
  AND End_Time < @@TimeStamp  
  AND End_Time > DateAdd(Month, -1, @@TimeStamp)  
 UPDATE #Primaries  
  SET LastEndTime = @@LastEndTime,  
   UpTime = DateDiff(Second, @@LastEndTime, @@TimeStamp),  
   ReportUpTime = DateDiff(Second,  
    (CASE WHEN @@LastEndTime < @StartTime THEN @StartTime ELSE @@LastEndTime END),  
    (CASE WHEN @@TimeStamp < @StartTime THEN @StartTime ELSE @@TimeStamp END))  
  WHERE TEDetId = @@Id  
 FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
END  
CLOSE PrimariesCursor  
DEALLOCATE PrimariesCursor  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
UPDATE tp  
 SET Stops =   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsUnscheduled = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.ScheduleId = @SchedUnscheduledId OR tp.ScheduleId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  Stops2m =  CASE WHEN tp.DownTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.ScheduleId = @SchedUnscheduledId OR tp.ScheduleId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsMinor =  CASE WHEN tp.DownTime < 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.ScheduleId = @SchedUnscheduledId OR tp.ScheduleId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsBreakDowns = CASE WHEN tp.DownTime >= 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND tp.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsELP =  CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.CategoryId = @CatELPId)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  ReportELPDowntime = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.CategoryId = @CatELPId)  
       AND (tp.StartTime >= @StartTime)  
       THEN tp.ReportDownTime  
      ELSE 0  
      END,  
  StopsBlockedStarved = CASE WHEN tp.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  UpTime2m =  CASE WHEN tp.UpTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
 FROM #Primaries tp  
 JOIN @ProdUnits tpu ON tp.PUId = tpu.PUId  
UPDATE tp  
 SET StopsProcessFailures = CASE WHEN tp.DownTime >= 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND Coalesce(tp.StopsMinor, 0) = 0  
       AND Coalesce(tp.StopsBreakDowns, 0) = 0  
       AND Coalesce(tp.StopsBlockedStarved, 0) = 0  
       AND (tp.ScheduleId = @SchedUnscheduledId OR tp.ScheduleId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
 FROM #Primaries tp  
 JOIN @ProdUnits tpu ON tp.PUId = tpu.PUId  
UPDATE td  
 SET StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
 FROM #Delays td  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  
  
-- CREATE INDEX Primaries_TEDetId  
--  ON #Primaries (TEDetId)  
  
UPDATE td  
 SET UpTime = tp.UpTime,  
  ReportUpTime = tp.ReportUpTime,  
  Stops = tp.Stops,  
  StopsUnscheduled = tp.StopsUnscheduled,  
  Stops2m = tp.Stops2m,  
  StopsMinor = tp.StopsMinor,  
  StopsBreakDowns = tp.StopsBreakDowns,  
  StopsELP = tp.StopsELP,  
  ReportELPDowntime = tp.ReportELPDowntime,  
  StopsBlockedStarved = tp.StopsBlockedStarved,  
  StopsProcessFailures = tp.StopsProcessFailures,  
  UpTime2m = tp.UpTime2m  
 FROM #Delays td  
 JOIN #Primaries tp ON td.TEDetId = tp.TEDetId  
  
DropTables:  
 DROP TABLE #Primaries  
  
ReturnResultSets:  
  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Location for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  pu.PU_Desc [Location],  
   SUM(Coalesce(td.Stops, 0)) [Total Stops],  
   SUM(CONVERT(FLOAT, td.ReportDowntime) / 60.0) [Total Downtime]  
  FROM  #Delays td  
   LEFT JOIN [dbo].Prod_Units pu ON td.LocationId = pu.PU_Id  
   LEFT JOIN @ProdUnits ppu ON td.PUId = ppu.PUId  
  GROUP BY pu.PU_Desc  
  ORDER BY [Total Downtime] DESC  
  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Failure Mode for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  er.Event_Reason_Name [Failure Mode],  
   SUM(Coalesce(td.Stops, 0)) [Total Stops],  
   SUM(CONVERT(FLOAT, td.ReportDowntime) / 60.0) [Total Downtime]  
  FROM  #Delays td  
   LEFT JOIN [dbo].Event_Reasons er ON td.L1ReasonId = er.Event_Reason_Id  
   LEFT JOIN @ProdUnits ppu ON td.PUId = ppu.PUId  
  GROUP BY er.Event_Reason_Name  
  ORDER BY [Total Downtime] DESC  
  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Failure Mode for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  er.Event_Reason_Name [Failure Mode Cause],  
   SUM(Coalesce(td.Stops, 0)) [Total Stops],  
   SUM(CONVERT(FLOAT, td.ReportDowntime) / 60.0) [Total Downtime]  
  FROM  #Delays td  
   LEFT JOIN [dbo].Event_Reasons er ON td.L2ReasonId = er.Event_Reason_Id  
   LEFT JOIN @ProdUnits ppu ON td.PUId = ppu.PUId  
  GROUP BY er.Event_Reason_Name  
  ORDER BY [Total Downtime] DESC  
  
  
--Drop Tables.  
 DROP TABLE #Delays  
  
Finished:  
 SET NOCOUNT OFF  
 RETURN  
  
