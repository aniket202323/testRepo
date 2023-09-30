 --------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Version 1  
--  
-- This SP will support the report template called RptStopsEquipType.xlt.  This  
-- report returns the Stops records for a collection of Production Lines or   
-- Production Units and  
-- allows filters for Products, Categories, etc.  It returns source data to the  
-- template.  The template has the option to save the source data to a CSV file.  
-- In addition to that result set, this SP will also return  
-- an ErrorMsg resultset.  
--  
-- 2002-07-11 Vince King  
--  - Modified the Stops report to be used as an Equipment Type report.  
--    - Added the @ProdUnitList parameter to provide a list of Production Units to be included in   
--      the report.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE spLocal_RptStopsEquipType    
 @StartTime   DateTime,  -- Beginning period for the data.  
 @EndTime   DateTime,  -- Ending period for the data.  
 @ProdLineList   nVarChar(4000),  -- Collection of Prod_Lines.PL_Id delimited by "|".  
 @ProdUnitList   nVarChar(4000),  -- Collection of Prod_Units.PU_Id delimited by "|".  
 @DelayTypeList   nVarChar(4000),  -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
 @ScheduleStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatBlockStarvedId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @SchedUnScheduledId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Scheduled.  
 @SchedPRPolyId   Int,   -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedChangeOverId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:ChangeOver.  
 @DelayTypeRateLossStr  nVarChar(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @MaxNoOfUWS   Int,   -- Maximum number of unwind stands on a single line for all lines configured for this report.  
        -- Minimum value should be 1.  
 @CvtgDTPUStr   nVarChar(100),  -- String used to match prod unit desc for the unit used for genealogy (i.e. Converter)  
 @PRIDVarStr   nVarChar(100),  -- Variables.Var_Desc for the genealogy PRID variable for ALL lines.  Blank if NA.  
 @UWSVarStr   nVarChar(100),  -- Variables.Var_Desc for the genealogy Unwind Stand variable for ALL lines.  Blank if NA.  
 @ProdLinePalList  nVarChar(4000)  -- Collection of Prod_Lines.PL_Id for palletizers (or other prod lines that require Uptime  
AS  
  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
CREATE TABLE #ErrorMessages (  
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
 Stops2m    Int,  
 StopsMinor   Int,  
 StopsBreakDowns   Int,  
 StopsProcessFailures  Int,  
 StopsBlockedStarved  Int,  
 UpTime2m   Int,  
 Comment    VarChar(5000) )  
CREATE INDEX td_PUId_StartTime  
 ON #Delays (PUId, StartTime)  
CREATE INDEX td_PUId_EndTime  
 ON #Delays (PUId, EndTime)  
CREATE TABLE #ProdUnits (  
 PUId    Int Primary Key,  
 PUDesc    nVarChar(100),  
 PLId    Int,  
 ExtendedInfo   nVarChar(255),  
 DelayType   nVarChar(100),  
 ScheduleUnit   Int,  
 LineStatusUnit   Int,  
 PRIDVarId   Int,  
 UWSVarId   Int )  
CREATE  TABLE #UWS (  
 MasterPUId   Int,  
 UWSPUId    Int )  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @CatMechEquipId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@CatMechEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @CatElectEquipId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@CatElectEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @CatProcFailId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@CatProcFailId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @CatBlockStarvedId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@CatBlockStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @SchedUnScheduledId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnScheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @SchedPRPolyId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@SchedPRPolyId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM Event_Reason_Catagories WHERE ERC_Id = @SchedChangeOverId) = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@SchedChangeOverId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF @MaxNoOfUWS < 1 OR @MaxNoOfUWS IS NULL   --If MaxNoOfUWS is invalid or not provided.  
  SELECT @MaxNoOfUWS = 1  
IF @CvtgDTPUStr IS NULL     --If CvtgDTPUStr is not provided.    
  SELECT @CvtgDTPUStr = 'Converter'  
IF @PRIDVarStr IS NULL     --If PRIDVarStr is not provided.  
  SELECT @PRIDVarStr = 'PRID'  
IF @UWSVarStr IS NULL     --If UWSVarStr is not provided.  
  SELECT @UWSVarStr = 'Unwind Stand'  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE @SearchString   nVarChar(4000),  
 @Position   Int,  
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
 @@PRIDVarId   Int,  
 @UWSId    Int,  
 @@PLId    Int,  
 @strSQL    nVarChar(4000),  
 @@PUDesc   nVarChar(100),  
 @@UWSVarId   nVarChar(100)  
  
SELECT @Now = GetDate(),  
 @PUDelayTypeStr = 'DelayType=',  
 @PUScheduleUnitStr = 'ScheduleUnit=',  
 @PULineStatusUnitStr = 'LineStatusUnit='  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-- ProdLineList, This will parse the @ProdLinesList into a table.  If the  
-- @ProdLinesList var is NULL, then the @ProdUnitsList will be parsed.  
-------------------------------------------------------------------------------  
CREATE TABLE #ProdLines (  
 PLId    Int Primary Key )  
SELECT @SearchString = LTrim(RTrim(@ProdLineList))  
WHILE Len(@SearchString) > 0  
BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
 BEGIN  
  IF IsNumeric(@PartialString) <> 1  
  BEGIN  
   INSERT #ErrorMessages (ErrMsg)  
    VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM #ProdLines WHERE PLId = Convert(Int, @PartialString)) = 0  
   INSERT #ProdLines (PLId)   
    VALUES (Convert(Int, @PartialString))  
 END  
END  
-------------------------------------------------------------------------------  
-- ProdUnitList.  Check to see if there are prod lines in the #ProdLines Table.  
--    If not, then parse the @ProdUnitsList var.  
-------------------------------------------------------------------------------  
IF (SELECT COUNT(*) FROM #ProdLines) > 0  
 INSERT #ProdUnits (PUId, PUDesc, PLId, ExtendedInfo)  
  SELECT pu.PU_Id, pu.PU_Desc, pu.PL_Id, pu.Extended_Info  
   FROM Prod_Units pu  
   JOIN #ProdLines tpl ON pu.PL_Id = tpl.PLId  
   JOIN Event_Configuration ec ON pu.PU_Id = ec.PU_Id  
   WHERE pu.Master_Unit IS NULL  
    AND ec.ET_Id = 2  
ELSE  
 BEGIN  
  SELECT @SearchString = LTrim(RTrim(@ProdUnitList))  
  WHILE Len(@SearchString) > 0  
  BEGIN  
   SELECT @Position = CharIndex('|', @SearchString)  
   IF  @Position = 0  
    SELECT @PartialString = RTrim(@SearchString),  
     @SearchString = ''  
   ELSE  
    SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
     @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
   IF Len(@PartialString) > 0  
   BEGIN  
    IF IsNumeric(@PartialString) <> 1  
    BEGIN  
     INSERT #ErrorMessages (ErrMsg)  
      VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
     GOTO ReturnResultSets  
    END  
    IF (SELECT Count(PUId) FROM #ProdUnits WHERE PUId = Convert(Int, @PartialString)) = 0  
     INSERT #ProdUnits (PUId, PUDesc, PLId, ExtendedInfo)   
      SELECT Convert(Int, @PartialString), pu.PU_Desc, pu.PL_Id, pu.Extended_Info  
       FROM Prod_Units pu  
       JOIN Prod_Lines tpl ON pu.PL_Id = tpl.PL_Id  
       JOIN Event_Configuration ec ON pu.PU_Id = ec.PU_Id  
       WHERE pu.Master_Unit IS NULL AND pu.PU_Id = Convert(Int, @PartialString)  
        AND ec.ET_Id = 2  
   END  
  END  
 END  
DECLARE ProdUnitCursor INSENSITIVE CURSOR FOR  
 (SELECT PUId, PLId, ExtendedInfo  
  FROM #ProdUnits)  
 FOR READ ONLY  
OPEN ProdUnitCursor  
FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@PLId, @@ExtendedInfo  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @Position = CharIndex(@PUDelayTypeStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUDelayTypeStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE #ProdUnits  
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
  UPDATE #ProdUnits  
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
  UPDATE #ProdUnits  
   SET LineStatusUnit = @PartialString  
   WHERE PUId = @@Id  
 END  
 UPDATE #ProdUnits  
  SET PRIDVarId = (SELECT Var_Id FROM Variables v  
       JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
     Where Var_Desc = @PRIDVarStr  
      AND pu.PL_Id = @@PLId AND PU_Desc LIKE '%Production%'),  
   UWSVarId = (SELECT Var_Id FROM Variables v  
       JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
     WHERE Var_Desc = @UWSVarStr  
      AND pu.PL_Id = @@PLId AND PU_Desc LIKE '%Production%')  
   WHERE PUId = @@Id AND PUDesc LIKE '%' + @CvtgDTPUStr + '%'  
 INSERT #UWS (MasterPUId, UWSPUId)  
  SELECT pu.Master_Unit, pu.PU_Id  
   FROM Prod_Units pu  
   WHERE pu.Master_Unit = @@Id AND (PU_Desc LIKE '%UWS%' OR PU_Desc LIKE '%Unwind%')  
   
 ------------------------------------------------------------------------------------------  
 -- Insert PLIDs into #ProdLines for the Prod Units provided in the @ProdUnitsList  
 -- variable.  
 ------------------------------------------------------------------------------------------  
 IF (SELECT COUNT(PLId) FROM #ProdLines WHERE PLId = @@PLId) = 0  
  INSERT #ProdLines VALUES (@@PLId)  
  
 FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@PLId, @@ExtendedInfo  
END  
CLOSE ProdUnitCursor  
DEALLOCATE ProdUnitCursor  
-------------------------------------------------------------------------------  
-- DelayTypeList  
-------------------------------------------------------------------------------  
CREATE TABLE #DelayTypes (  
 DelayTypeDesc   nVarChar(100) Primary Key)  
SELECT @SearchString = LTrim(RTrim(@DelayTypeList))  
WHILE Len(@SearchString) > 0  
BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
  AND (SELECT Count(DelayTypeDesc) FROM #DelayTypes WHERE DelayTypeDesc = @PartialString) = 0  
  INSERT #DelayTypes (DelayTypeDesc)   
   VALUES (@PartialString)  
END  
-------------------------------------------------------------------------------  
-- Palletizer ProdLineList (see comment for 2002-06-21 Vince King).  
-------------------------------------------------------------------------------  
CREATE TABLE #PalProdLines (  
 PLId    Int Primary Key )  
SELECT @SearchString = LTrim(RTrim(@ProdLinePalList))  
WHILE Len(@SearchString) > 0  
BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
 BEGIN  
  IF IsNumeric(@PartialString) <> 1  
  BEGIN  
   INSERT #ErrorMessages (ErrMsg)  
    VALUES ('Parameter @ProdLinePalList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM #PalProdLines WHERE PLId = Convert(Int, @PartialString)) = 0  
   INSERT #PalProdLines (PLId)   
    VALUES (Convert(Int, @PartialString))  
 END  
END  
  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list.  
-------------------------------------------------------------------------------  
IF (SELECT Count(DelayTypeDesc) FROM #DelayTypes) > 0  
 DELETE FROM #ProdUnits  
  WHERE DelayType NOT IN (SELECT DelayTypeDesc  
       FROM #DelayTypes)  
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
  FROM  Timed_Event_Details ted  
  JOIN  #ProdUnits tpu ON ted.PU_Id = tpu.PUId  
  LEFT JOIN Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
    AND ted.Start_Time = ted2.End_Time  
    AND ted.TEDet_Id <> ted2.TEDet_Id  
  LEFT JOIN Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
    AND ted.End_Time = ted3.Start_Time  
    AND ted.TEDet_Id <> ted3.TEDet_Id  
  WHERE  ted.Start_Time < @EndTime  
  AND  (ted.End_Time >= @StartTime  
    OR ted.End_Time IS NULL)  
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
   FROM  Timed_Event_Details ted  
   JOIN  #ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
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
   FROM  Timed_Event_Details ted  
   JOIN  #ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
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
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('The dataset contains more than 65000 rows.  This exceeds the Excel limit.')  
 GOTO DropTables  
END  
  
  
-------------------------------------------------------------------------------  
-- Get the comment for each Timed_Event_Detail and Timed_Event_Summary record.  
-- WTC_Type = 2 (Comment for Detail record)  
-- WTC_Type = 1 (Comment for Summary record)  
-------------------------------------------------------------------------------  
-- Get comments that are attached to the detail events.  
UPDATE #Delays  
 SET Comment = RTrim(LTrim(Convert(varchar(5000),WTC.Comment_Text)))  
 FROM Waste_n_Timed_Comments WTC   
 WHERE (TEDetId = WTC.WTC_Source_Id) AND (WTC_Type = 2)  
  
-- Get comments that are attached to the summary events.  
Update #Delays    
 set Comment = RTrim(LTrim(Convert(varchar(5000),wtc.Comment_Text)))  
 from Waste_n_Timed_Comments wtc  
  left outer join timed_event_summarys tes on TESum_Id = WTC_Source_Id  
 where #Delays.StartTime = tes.Start_Time and #Delays.PUId = tes.PU_Id  
  and #Delays.Comment is null and WTC_Type = 1  
  
  
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
 JOIN Production_Starts ps ON td.PUId = ps.PU_Id  
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
 JOIN #ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN Crew_Schedule cs ON tpu.ScheduleUnit = cs.PU_Id  
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
     FROM Local_PG_Line_Status LS  
     JOIN Phrase P ON LS.Line_Status_Id = P.Phrase_Id  
     JOIN #ProdUnits pu ON pu.PUId = @@PUId  
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
 JOIN Prod_Events pe ON td.LocationId = pe.PU_Id  
  AND pe.Event_Type = 2  
 JOIN Event_Reason_Tree_Data ertd ON pe.Name_Id = ertd.Tree_Name_Id  
  AND ertd.Event_Reason_Level = 1  
  AND ertd.Event_Reason_Id = td.L1ReasonId  
-------------------------------------------------------------------------------  
-- Level 2.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L2TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L1TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 2  
  AND ertd.Event_Reason_Id = td.L2ReasonId  
-------------------------------------------------------------------------------  
-- Level 3.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L3TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L2TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 3  
  AND ertd.Event_Reason_Id = td.L3ReasonId  
-------------------------------------------------------------------------------  
-- Level 4.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L4TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L3TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 4  
  AND ertd.Event_Reason_Id = td.L4ReasonId  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- lowest point on the tree.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ScheduleId = erc.ERC_Id  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
UPDATE td  
 SET CategoryId = erc.ERC_Id  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @CategoryStr + '%'  
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
 Stops2m    Int,  
 StopsMinor   Int,  
 StopsBreakDowns   Int,  
 StopsProcessFailures  Int,  
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
 SELECT @@PLId = PL_Id FROM Prod_Units WHERE PU_Id = @@PUId  
 SELECT @@LastEndTime = NULL  
 IF (SELECT COUNT(*) FROM #PalProdLines WHERE PLId = @@PLId) > 0  
  BEGIN  
   SELECT @@LastEndTime = Max(EndTime)  
    FROM #Primaries ted  
     LEFT JOIN Prod_Units pu ON @@PUId = pu.PU_Id  
    WHERE PUId In (SELECT PUId FROM #ProdUnits WHERE PLId = @@PLId)  
    AND EndTime <= @@TimeStamp  
    AND EndTime > DateAdd(Month, -1, @@TimeStamp)  
  END  
 ELSE  
  BEGIN   
   SELECT @@LastEndTime = Max(EndTime)  
    FROM #Primaries ted  
    WHERE PUId = @@PUId  
    AND EndTime <= @@TimeStamp  
    AND EndTime > DateAdd(Month, -1, @@TimeStamp)  
  END  
 SELECT @@LastEndTime = CASE WHEN @@LastEndTime IS NULL THEN @StartTime ELSE @@LastEndTime END  
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
-- Calculate the Statistics on the dataset.  
-------------------------------------------------------------------------------  
UPDATE tp  
 SET Stops =   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  Stops2m =  CASE WHEN tp.DownTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsMinor =  CASE WHEN tp.DownTime < 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (tp.CategoryId <> @CatBlockStarvedId OR tp.CategoryId IS NULL)   
       AND (tp.ScheduleId = @SchedUnScheduledId OR tp.ScheduleId IS NULL)  
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
 JOIN #ProdUnits tpu ON tp.PUId = tpu.PUId  
UPDATE tp  
 SET StopsProcessFailures = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND Coalesce(tp.StopsMinor, 0) = 0  
       AND Coalesce(tp.StopsBreakDowns, 0) = 0  
       AND Coalesce(tp.StopsBlockedStarved, 0) = 0  
       AND (tp.ScheduleId = @SchedUnScheduledId OR tp.ScheduleId IS NULL)  
       AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
 FROM #Primaries tp  
 JOIN #ProdUnits tpu ON tp.PUId = tpu.PUId  
UPDATE td  
 SET StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
 FROM #Delays td  
 JOIN #ProdUnits tpu ON td.PUId = tpu.PUId  
UPDATE td  
 SET UpTime = tp.UpTime,  
  ReportUpTime = tp.ReportUpTime,  
  Stops = tp.Stops,  
  Stops2m = tp.Stops2m,  
  StopsMinor = tp.StopsMinor,  
  StopsBreakDowns = tp.StopsBreakDowns,  
  StopsBlockedStarved = tp.StopsBlockedStarved,  
  StopsProcessFailures = tp.StopsProcessFailures,  
  UpTime2m = tp.UpTime2m  
 FROM #Delays td  
 JOIN #Primaries tp ON td.TEDetId = tp.TEDetId  
DROP TABLE #Primaries  
  
--------------------------------------------------------------------------------------------  
--- Add columns to the #Delays and #ProdUnits tables for the maximum number of Unwind Stands.  
--------------------------------------------------------------------------------------------  
DECLARE @LoopCtr  integer  
SELECT @LoopCtr = 1  
 WHILE @LoopCtr <= @MaxNoOfUWS  
BEGIN  
      Select @strSQL = 'ALTER TABLE #Delays ADD [UWS' + RTrim(LTrim(CONVERT(nVarChar(3),@LoopCtr))) + '] VarChar(25) Null'  
      Exec (@strSQL)  
  
      Select @strSQL = 'ALTER TABLE #ProdUnits ADD [UWS' + RTrim(LTrim(CONVERT(nVarChar(3),@LoopCtr))) + '] VarChar(50) Null'  
      Exec (@strSQL)  
  
 SELECT @LoopCtr = @LoopCtr + 1  
END  
   
--------------------------------------------------------------------------------------------  
--- Insert Start_Times, UWS and PRIDs into temporary table.  
--------------------------------------------------------------------------------------------  
  
DECLARE @@MasterPUId Integer,  
 @@UWSPUId Integer,  
 @LastMPUId Integer  
  
SELECT @LoopCtr = 1  
  
DECLARE UWSCursor INSENSITIVE CURSOR FOR  
 (SELECT MasterPUId, UWSPUId  
  FROM #UWS)  
 FOR READ ONLY  
OPEN UWSCursor  
FETCH NEXT FROM UWSCursor INTO @@MasterPUId, @@UWSPUId  
WHILE @@Fetch_Status = 0  
BEGIN  
  SELECT @strSQL = 'UPDATE #ProdUnits SET [UWS' + RTrim(LTrim(@LoopCtr)) + '] = "' +   
     (SELECT PU_Desc FROM Prod_Units WHERE PU_Id = @@UWSPUId) +   
     '" WHERE PUId = ' + RTrim(LTrim(CONVERT(VarChar(10),@@MasterPUId)))  
  EXEC(@strSQL)  
  
  SELECT @LastMPUId = @@MasterPUId  
  FETCH NEXT FROM UWSCursor INTO @@MasterPUId, @@UWSPUId  
  IF @LoopCtr < @MaxNoOfUWS  --@LastMPUId = @@MasterPUId   
   SELECT @LoopCtr = @LoopCtr + 1  
  ELSE  
   SELECT @LoopCtr = 1  
END  
CLOSE UWSCursor  
DEALLOCATE UWSCursor  
--------------------------------------------------------------------------------------------  
--- Insert Start_Times, UWS and PRIDs into temporary table.  
--------------------------------------------------------------------------------------------  
Create Table #PRIDs(  
 Start_Time   datetime,  
 PUID   integer,  
 PRID    varchar(25),  
 UWS    varchar(25)  
 )  
DECLARE ProdUnitsCursor INSENSITIVE CURSOR FOR  
 (SELECT PUId, PUDesc, PRIDVarId, UWSVarId  
  FROM #ProdUnits)  
 FOR READ ONLY  
OPEN ProdUnitsCursor  
FETCH NEXT FROM ProdUnitsCursor INTO @@PUId, @@PUDesc, @@PRIDVarId, @@UWSVarId  
WHILE @@Fetch_Status = 0  
BEGIN  
 Insert Into #PRIDs (Start_Time, PUID, PRID)  
  Select Result_On, @@PUId, result  
  From Tests t   Where (Result_On >= @StartTime And Result_On <= @EndTime)   
   And t.Var_Id = @@PRIDVarId And @@PUDesc Like '%' + @CvtgDTPUStr + '%'  
  
 Insert Into #PRIDs (Start_Time, PUID, PRID)  
  Select Top 10 Result_On, @@PUId, Result  
  From Tests  
  Where (Result_On < @StartTime) And Var_Id = @@PRIDVarId  
   And @@PUDesc Like '%' + @CvtgDTPUStr + '%'  
  Order By Result_On Desc  
  
 Insert Into #PRIDs (Start_Time, PUID, PRID)  
  Select Top 10 Result_On, @@PUId, Result  
  From Tests  
  Where (Result_On > @EndTime) And Var_Id = @@PRIDVarId  
   And @@PUDesc Like '%' + @CvtgDTPUStr + '%'  
  Order By Result_On Desc  
  
 Update #PRIDs  
  Set UWS = result  
  From Tests  
  Where Start_Time = Result_On and Var_Id = @@UWSVarId  
  
 FETCH NEXT FROM ProdUnitsCursor INTO @@PUId, @@PUDesc, @@PRIDVarId, @@UWSVarId  
END  
CLOSE ProdUnitsCursor  
DEALLOCATE ProdUnitsCursor  
--------------------------------------------------------------------------------------------  
--- Update the UWS Columns with the appropriate PRID results.  
--------------------------------------------------------------------------------------------  
SELECT @LoopCtr = 1 WHILE @LoopCtr <= @MaxNoOfUWS  
BEGIN  
 SELECT @strSQL = 'UPDATE #Delays SET [UWS' + RTrim(LTrim(CONVERT(VarChar(10),@LoopCtr))) +   
    '] = (SELECT Top 1 PRID FROM #PRIDs pid   
       LEFT JOIN #ProdUnits pu ON #Delays.PUId = pu.PUId  
    WHERE Start_Time < StartTime  
    AND pu.UWS' + RTrim(LTrim(CONVERT(VarChar(10),@LoopCtr))) + ' LIKE UWS + "%"  
    ORDER BY Start_Time DESC)'   
 EXEC(@strSQL)  
 SELECT @LoopCtr = @LoopCtr + 1  
  
  
END   
DropTables:  
 DROP TABLE #ProdLines  
 DROP TABLE #DelayTypes  
  
--------------------------------------------------------------------------------------------  
--- Build the SELECT statement for the detailed data, which includes the UWS column(s).  
--------------------------------------------------------------------------------------------  
SELECT @LoopCtr = 1  
SELECT @strSQL =   
  'SELECT pl.PL_Desc [Production Line],  
   Convert(nVarChar(25), td.StartTime, 120) [Start Time],  
   Convert(nVarChar(25), td.EndTime, 120) [End Time],  
   pu.PU_Desc [Master Unit],  
   loc.PU_Desc [Location],  
   er1.Event_Reason_Name [Reason Level 1],  
   er2.Event_Reason_Name [Reason Level 2],  
   er3.Event_Reason_Name [Reason Level 3],  
   er4.Event_Reason_Name [Reason Level 4],  
   p.Prod_Desc [Product],  
   tef.TEFault_Name [Fault Desc],  
   td.LineStatus [Line Status],  
   SubString(erc1.ERC_Desc, CharIndex(":", erc1.ERC_Desc) + 1, 50) [Schedule],  
   SubString(erc2.ERC_Desc, CharIndex(":", erc2.ERC_Desc) + 1, 50) [Category],  
   SubString(erc3.ERC_Desc, CharIndex(":", erc3.ERC_Desc) + 1, 50) [SubSystem],  
   SubString(erc4.ERC_Desc, CharIndex(":", erc4.ERC_Desc) + 1, 50) [GroupCause],  
   td.Shift [Shift],  
   td.Crew [Team],  
   tpu.DelayType [Event Location Type],  
   CASE WHEN td.TEDetId = td.PrimaryId THEN "Primary" ELSE "Secondary" END [Event Type],  
   Convert(Int, "1") [Total Causes],  
   td.DownTime/60.0 [Total DownTime],   
   td.ReportDownTime/60.0 [Total Event DownTime],  
   td.UpTime/60.0 [Total UpTime],  
   td.ReportUpTime/60.0 [Total Event UpTime],  
   Coalesce(td.Stops, 0) [Total Stops],  
   Coalesce(td.Stops2m, 0) [Total Stops < 2 Min],  
   Coalesce(td.StopsMinor, 0) [Minor Stops],  
   Coalesce(td.StopsBreakDowns, 0) [Break Downs],  
   Coalesce(td.StopsProcessFailures, 0) [Process Failures],  
   Coalesce(td.StopsBlockedStarved, 0) [Total Blocked Starved],  
   Coalesce(td.UpTime2m, 0) [Total UpTime < 2 Min], '  
  WHILE @LoopCtr <= @MaxNoOfUWS  
  BEGIN  
   SELECT @strSQL = @strSQL + 'td.UWS' + RTrim(LTrim(CONVERT(VarChar(10),@LoopCtr))) + ', '     
   SELECT @LoopCtr = @LoopCtr + 1  
  END  
  SELECT @strSQL = @strSQL + ' Comment   
   FROM  #Delays td  
   JOIN  #ProdUnits tpu ON td.PUId = tpu.PUId  
   JOIN  Prod_Units pu ON td.PUId = pu.PU_Id  
   JOIN  Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   JOIN  Products p ON td.ProdId = p.Prod_Id  
   LEFT JOIN Event_Reason_Catagories erc1 ON td.ScheduleId = erc1.ERC_Id  
   LEFT JOIN Event_Reason_Catagories erc2 ON td.CategoryId = erc2.ERC_Id  
   LEFT JOIN Event_Reason_Catagories erc3 ON td.SubSystemId = erc3.ERC_Id  
   LEFT JOIN Event_Reason_Catagories erc4 ON td.GroupCauseId = erc4.ERC_Id  
   LEFT JOIN Prod_Units loc ON td.LocationId = loc.PU_Id  
   LEFT JOIN Event_Reasons er1 ON td.L1ReasonId = er1.Event_Reason_Id  
   LEFT JOIN Event_Reasons er2 ON td.L2ReasonId = er2.Event_Reason_Id  
   LEFT JOIN Event_Reasons er3 ON td.L3ReasonId = er3.Event_Reason_Id  
   LEFT JOIN Event_Reasons er4 ON td.L4ReasonId = er4.Event_Reason_Id  
   LEFT  JOIN  Timed_Event_Fault tef on (td.TEFaultID = TEF.TEFault_ID)  
   ORDER  BY pl.PL_Desc, td.Starttime'  
ReturnResultSets:  
  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM #ErrorMessages  
   
 -------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 -------------------------------------------------------------------------------  
 EXEC(@strSQL)  
  
 DROP TABLE #ErrorMessages  
 DROP TABLE #ProdUnits  
 DROP TABLE #Delays  
 DROP TABLE #PRIDs  
 DROP TABLE #UWS  
 DROP TABLE  #PalProdLines  
Finished:  
 RETURN  
  
