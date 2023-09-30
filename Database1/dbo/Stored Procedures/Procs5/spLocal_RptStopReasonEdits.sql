  
  
  
  
---------------------------------------------------------------------------------------------------  
-- !!!!!!!!!!!!!!!!!!!!!!!!! TO VIEW THIS SP PLEASE SET TAB SPACING TO 4 !!!!!!!!!!!!!!!!!!!!!!!!!  
---------------------------------------------------------------------------------------------------  
-- Desc:  
-- This stored procedure supports the LocalRptStopReasonEdits ASP.Net report. The purpose of this   
-- report is to return a detail list of all Stop records (Timed_Event_Details) that have not been  
-- edited  
---------------------------------------------------------------------------------------------------  
-- Business Rule:   
-- Calculate the % Reason Edits  
-- There will be two types of % Reason Edits calcs  
-- % Edits Total and % Edits Good Production   
---------------------------------------------------------------------------------------------------  
-- Business rule for the caculation of % Edits Total:  
-- % Edits Total = Edited Records / Total Stops  
-- A record will be considered complete is all required reason levels are full.   
-- The number of required reason levels is determined by the reason tree that is associated with the Source_PUId  
-- Data set will exclude Production Units where PU_Desc like '%Packer%'  
---------------------------------------------------------------------------------------------------  
-- Business rule for the calculation of % Edits Good Production  
-- % Edits Good Production = Edited Records / Total Stops  
-- A record will be considered complete is all required reason levels are full.   
-- The number of required reason levels is determined by the reason tree that is associated with the Source_PUId   
-- Data set will exclude Production Units where PU_Desc like '%Packer%'  
-- Where Line_Statuses = "Scheduled MaINTenance" and "E.O. Shippable"  
-- The Line_Status_Id filter = DEFAULT_Value field in dbo.Report_Type_Parameters where:  
-- Report_Type_Id WHERE Description = "RE_LocalRptStopReasonEdits" in dbo.Report_Types and   
-- RP_Id WHERE RP_Name = "Local_PG_strRptGoodProductionLineStatusIdList"  
---------------------------------------------------------------------------------------------------  
-- Supported filters:   
-- GBU  
-- ReportEndTime  
-- DataFilter ValidValue: RETotal, REGoodProd  
---------------------------------------------------------------------------------------------------  
-- Nested sp:   
-- NONE  
---------------------------------------------------------------------------------------------------  
-- SP sections:  
-- 1. Declare Variables  
-- 2.   Prepare Tables  
-- 3.   Get Data  
-- 4. ResultSet1 >>> Matrix column header list  
-- 5.   ResultSet2 >>> Production Line List  
-- 6.   ResultSet3 >>> Production Unit List  
-- 7. ResultSet4 >>> Location List  
-- 8.  ResultSet5 >>> Detail Stop Records (from Timed_Event_Details table)  
---------------------------------------------------------------------------------------------------  
-- Error codes:  
-- 1   
---------------------------------------------------------------------------------------------------  
-- Edit history:  
-- RPiedmont 06-Apr-2006 SlimSoft 05-P004-PG-BF-UtilizationRpt  
--          Code development  
-- FRio   15-Jun-2007 Get Rid of all Units Not Like '%Converter%'  
-- Galanzini.p 19-Nov-2009 Change for search the Local_PG_Line_Status  
---------------------------------------------------------------------------------------------------  
-- App_Id = 50015  
-- Min_Prompt = 99824001  
-- Max_Prompt = 99825000  
---------------------------------------------------------------------------------------------------  
-- Sample Exec statement:  
/*  
EXEC dbo.spLocal_RptStopReasonEdits  
  @RptGBU   = 'House Hold Care',  
  @RptEndTime  = '2009-11-19 00:00:00.000',  
  @RptDataFilter  = 'RETotal', -- Valid values: RETotal, REGoodProd  
  @RptRSFilter = 0  
*/  
---------------------------------------------------------------------------------------------------  
  
CREATE   PROCEDURE [dbo].[spLocal_RptStopReasonEdits]  
     @RptGBU   VARCHAR(50)  = NULL,  
     @RptEndTime  VARCHAR(25)  = NULL,  
     @RptDataFilter VARCHAR(50)  = NULL,  -- Valid values: RETotal, REGoodProd  
     @RptRSFilter INT    = 0   -- Valid values: 0 returns all result set, 1 returns on RS1, 2 returns RS2, RS3, RS4, RS5  
  
AS  
  
/*  
Example Web:  
http://ak-proficy03/reportserver/AspDotNetReports/DeployLocalRptStopReasonEdits/LocalRptStopReasonEdits.aspx?  
ResultTimeStamp=2008-09-03 22:37:13.000&  
GBU=Fem Care&  
ProficyServer=AK-MESDATABC&  
DataFilter=RETotal  
DECLARE  
     @RptGBU   VARCHAR(50),  
     @RptEndTime  VARCHAR(25),  
     @RptDataFilter VARCHAR(50), -- Valid values: RETotal, REGoodProd  
     @RptRSFilter INT    -- Valid values: 0 returns all result set, 1 returns on RS1, 2 returns RS2, RS3, RS4, RS5  
  
SELECT       
  @RptGBU   = 'House Hold Care',  
  @RptEndTime  = '2009-11-19 00:00:00.000',  
  @RptDataFilter  = 'RETotal', -- Valid values: RETotal, REGoodProd  
  @RptRSFilter = 0  
*/  
  
  
--=================================================================================================  
SET NOCOUNT ON  
--=================================================================================================  
DECLARE @dtmTempDate DateTime,  
  @IntSecNumber INT,  
  @IntFlgPrint INT  
---------------------------------------------------------------------------------------------------  
SET  @dtmTempDate = GetDate()  
SET  @IntFlgPrint = 1  
---------------------------------------------------------------------------------------------------  
SET @IntSecNumber = 1  
IF @IntFlgPrint = 1 PRINT 'SP START ' + Convert(VARCHAR(50), GetDate(), 121) + ' Open Transactions: ' + Convert(VARCHAR, @@TRANCount)   
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - Declare variables '  
--=================================================================================================  
-- Report variables  
-- Note: @c_.... means it is a cursor variable  
---------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Declare report language prompt constants '  
---------------------------------------------------------------------------------------------------  
DECLARE @IntPromptNumberPGFooter    INT,  
  @IntPromptNumberPrepared    INT,  
  @IntPromptNumberExecutionTime   INT,  
  @IntPromptNumberSummary    INT,  
  @IntPromptNumberDetail     INT  
---------------------------------------------------------------------------------------------------  
DECLARE @IntPromptNumberL1PLGroupHdr   INT,  
  @IntPromptNumberL1PLDesc   INT,  
  @IntPromptNumberL1StopRcdTotal  INT,  
  @IntPromptNumberL1StopRcdComplete INT,  
  @IntPromptNumberL1StopRcdIncomplete INT,  
  @IntPromptNumberL1PercentComplete INT  
---------------------------------------------------------------------------------------------------  
DECLARE @IntPromptNumberL2PUGroupHdr   INT,  
  @IntPromptNumberL2PUDesc   INT,  
  @IntPromptNumberL2StopRcdTotal  INT,  
  @IntPromptNumberL2StopRcdComplete INT,  
  @IntPromptNumberL2StopRcdIncomplete INT,  
  @IntPromptNumberL2PercentComplete INT  
---------------------------------------------------------------------------------------------------  
DECLARE @IntPromptNumberL3LocationGroupHdr INT,  
  @IntPromptNumberL3LocationDesc  INT,  
  @IntPromptNumberL3StopRcdTotal  INT,  
  @IntPromptNumberL3StopRcdComplete INT,  
  @IntPromptNumberL3StopRcdIncomplete INT,  
  @IntPromptNumberL3PercentComplete INT  
---------------------------------------------------------------------------------------------------  
DECLARE @IntPromptNumberL4DetailsGroupHdr   INT,  
  @IntPromptNumberL4DetId     INT,  
  @IntPromptNumberL4DelayTreeDesc   INT,  
  @IntPromptNumberL4DelayTreeMaxRLevel INT,  
  @IntPromptNumberL4LineStatusDesc  INT,  
  @IntPromptNumberL4DelayStartTime  INT,  
  @IntPromptNumberL4DelayEndTime   INT,  
  @IntPromptNumberL4DelayUserName   INT,  
  @IntPromptNumberL4Autocause    INT,  
  @IntPromptNumberL4RL1Desc    INT,  
  @IntPromptNumberL4RL2Desc    INT,  
  @IntPromptNumberL4RL3Desc    INT,  
  @IntPromptNumberL4RL4Desc    INT  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Declare miscellaneous variables '  
---------------------------------------------------------------------------------------------------  
DECLARE @RptGoodProductionLineStatusIdList VARCHAR(50) ,  
  @RptTypeName      VARCHAR(100),  
  @RptParamName      VARCHAR(50) ,  
  @vchrTempString      VARCHAR(50)  
---------------------------------------------------------------------------------------------------  
DECLARE @dtmStartTime DATETIME,  
   @dtmEndTime  DATETIME   
---------------------------------------------------------------------------------------------------  
DECLARE @fltRETotal   FLOAT,  
  @fltRECompleteR1 FLOAT,  
  @fltRECompleteR2 FLOAT,  
  @fltRECompleteR3 FLOAT,  
  @fltRECompleteR4 FLOAT  
---------------------------------------------------------------------------------------------------  
DECLARE @i       INT,  
  @ReportTypeId    INT,  
  @RPId      INT,  
  @intMaxLength    INT,  
  @intMaxColCount    INT,  
  @intTempPromptNumber  INT,   
  @intColWidth    INT,  
  @intPLDescLength   INT,  
  @intPUDescLength   INT,  
  @intLocationDescLength  INT,  
  @intDetIdLength    INT,  
  @intDelayTreeDescLength  INT,  
  @intLineStatusDescLength INT,  
  @intUserNameLength   INT,  
  @intAutoCauseLength   INT,  
  @intColWordCount   INT  
---------------------------------------------------------------------------------------------------  
DECLARE @IntCodeSkipFamCare INT  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Declare report table variables '  
---------------------------------------------------------------------------------------------------  
DECLARE @tblPUList TABLE (  
  PLId   INT   ,  
  PUId   INT   ,  
  PUDesc   VARCHAR(50) ,  
  AlternativePUId INT   , -- This PUId will be used if no schedule or line status has been configured for  
          -- the selected PUId  
  LookUpPUId  INT   ) -- Coalesce between PUId and AlternativePUId  
---------------------------------------------------------------------------------------------------  
DECLARE @tblREList TABLE (  
  PLId    INT,  
  PUId    INT,  
  SourcePUId   INT,  
  DelayTreePUId  INT,  
  DelayTreeId   INT,  
  DetId    INT,  
  LineStatusId  INT,  
  DelayStartTime  DATETIME,  
  DelayEndTime  DATETIME,  
  DelayUserId   INT,  
  TEFaultId   INT,  
  RL1Id    INT,  
  RL2Id    INT,  
  RL3Id    INT,  
  RL4Id    INT,  
  FlagRcdComplete  INT DEFAULT 0, -- 1 = complete; 0 = in-complete  
  FlagGoodProduction INT DEFAULT 0) -- 1 = complete; 0 = in-complete  
---------------------------------------------------------------------------------------------------  
DECLARE @tblReasonTreeList TABLE (  
  DelayTreeId   INT,  
  DelayTreeMaxRLevel INT)  
---------------------------------------------------------------------------------------------------  
DECLARE @tblLanguagePromptDefaultValues TABLE (  
  RcdId      INT Identity (1,1) ,  
  PromptNumber    INT     ,  
  DefaultPromptString   VARCHAR(200)  ,  
  PromptString    VARCHAR(200)  ,  
  RptPromptString    VARCHAR(200)  ,  
  RptColGroupFlag    INT DEFAULT 0  , -- 1= Prompt is a report column group, 0 = no  
  RptColFlag     INT DEFAULT 0  , -- 1= Prompt is a report column, 0 = no  
  RptColDataType    INT DEFAULT 3  ,  
  RptColLevelNumber   INT     ,  
  RptColIdx     INT     , -- Order the columns will appear in the report  
  RptColPrecision    INT     ,  
  RptColEngUnits    VARCHAR(50)   ,  
  RptColPLGroupHdrFlag  INT DEFAULT 0  ,  
  RptColPUGroupHdrFlag  INT DEFAULT 0  , -- 1= Column is grouped with Alarm Details, 0 = no  
  RptColLocationGroupHdrFlag INT DEFAULT 0  , -- 1= Column is grouped with Alarm Values, 0 = no  
  RptColDetailsGroupHdrFlag INT DEFAULT 0  ) -- 1= Column is grouped with Alarm Values, 0 = no  
---------------------------------------------------------------------------------------------------  
DECLARE @tblMatrixColHdrList TABLE (  
  RcdIdx    INT Identity (1,1),   
  ColIdx    INT   ,  
  LevelNumber   INT   ,  
  PromptNumber  INT   ,  
  ColDesc1   VARCHAR(50) ,  
  ColDesc2   VARCHAR(50) ,  
  ColDesc2WordCount INT   ,  
  ColDataType   VARCHAR(50) ,  
  ColPrecision  INT   ,  
  ColEngUnits   VARCHAR(50) ,  
  ColWidth   INT   )  
---------------------------------------------------------------------------------------------------  
DECLARE @tblProductionLineList TABLE (  
  RcdIdx    INT Identity (1,1),  
  PLId    INT   ,  
  PLDesc    VARCHAR(50) ,  
  StopRcdTotal  INT   ,  
  StopRcdComplete  INT   ,  
  StopRcdIncomplete INT   ,  
  PercentComplete  FLOAT  )  
---------------------------------------------------------------------------------------------------  
DECLARE @tblProductionUnitList TABLE (  
  RcdIdx    INT Identity (1,1),  
  PLId    INT   ,  
  PUId    INT   ,  
  PUDesc    VARCHAR(50) ,  
  StopRcdTotal  INT   ,  
  StopRcdComplete  INT   ,  
  StopRcdIncomplete INT   ,  
  PercentComplete  FLOAT  )  
---------------------------------------------------------------------------------------------------  
DECLARE @tblLocationList TABLE (  
  RcdIdx    INT Identity (1,1),  
  PLId    INT   ,  
  PUId    INT   ,  
  SourcePUId   INT   ,  
  SourcePUDesc  VARCHAR(50) ,  
  StopRcdTotal  INT   ,  
  StopRcdComplete  INT   ,  
  StopRcdIncomplete INT   ,  
  PercentComplete  FLOAT  )  
---------------------------------------------------------------------------------------------------  
DECLARE @tblStopRcdIncompleteList TABLE (  
  DetRcdGroupId  INT   ,  
  RcdIdx    INT Identity(1,1),  
  PLId    INT   ,  
  PUId    INT   ,  
  SourcePUId   INT   ,  
   DetId    INT   ,  
   DelayTreeId   INT   ,  
  DelayTreeDesc  VARCHAR(50) ,  
   DelayTreeMaxRLevel INT   ,  
   LineStatusId  INT   ,  
  LineStatusDesc  VARCHAR(50) ,  
   DelayStartTime  DATETIME ,  
   DelayEndTime  DATETIME ,  
  DelayUserId   INT   ,  
   DelayUserName  VARCHAR(50) ,  
   TEFaultId   INT   ,  
  Autocause   VARCHAR(100),  
   RL1Id    INT   ,  
  RL1Desc    VARCHAR(100),  
   RL2Id    INT   ,  
  RL2Desc    VARCHAR(100),  
  RL3Id    INT   ,  
  RL3Desc    VARCHAR(100),  
   RL4Id    INT   ,   
  RL4Desc    VARCHAR(100))  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrINT = 1 PRINT '  . Declare temporary tables '  
---------------------------------------------------------------------------------------------------  
CREATE TABLE #LineStatusFilter (  
    RcdId   INT,  
    LineStatusId INT)  
---------------------------------------------------------------------------------------------------  
CREATE TABLE #TempString (  
    RcdId  INT,  
    TempString VARCHAR(100))  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
SET @dtmTempDate = GetDate()  
SET @IntSecNumber  = @IntSecNumber + 1  
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - Set reporting period '  
--=================================================================================================  
-- End Time  
---------------------------------------------------------------------------------------------------  
IF LEN(COALESCE(@RptEndTime, '')) = 0  
BEGIN  
 SELECT @dtmEndTime = CONVERT(VARCHAR(25), GETDATE(), 120)  
END  
ELSE  
BEGIN  
 SELECT @dtmEndTime = @RptEndTime  
END  
---------------------------------------------------------------------------------------------------  
-- Start Time  
---------------------------------------------------------------------------------------------------  
SELECT @dtmStartTime  = DATEADD(DAY, -30, @dtmEndTime)  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT ' - Set language prompt constants constants '  
---------------------------------------------------------------------------------------------------  
SET @IntPromptNumberPGFooter    = 99824001  
SET @IntPromptNumberPrepared    = 99824002  
SET @IntPromptNumberExecutionTime   = 99824003  
SET @IntPromptNumberSummary    = 99824004  
SET @IntPromptNumberDetail     = 99824005  
---------------------------------------------------------------------------------------------------  
SET @IntPromptNumberL1PLGroupHdr   = 99824006  
SET @IntPromptNumberL1PLDesc   = 99824007  
SET @IntPromptNumberL1StopRcdTotal  = 99824008  
SET @IntPromptNumberL1StopRcdComplete = 99824009  
SET @IntPromptNumberL1StopRcdIncomplete = 99824010  
SET @IntPromptNumberL1PercentComplete = 99824011  
---------------------------------------------------------------------------------------------------  
SET @IntPromptNumberL2PUGroupHdr   = 99824012  
SET @IntPromptNumberL2PUDesc   = 99824013  
SET @IntPromptNumberL2StopRcdTotal  = 99824014  
SET @IntPromptNumberL2StopRcdComplete = 99824015  
SET @IntPromptNumberL2StopRcdIncomplete = 99824016  
SET @IntPromptNumberL2PercentComplete = 99824017  
---------------------------------------------------------------------------------------------------  
SET @IntPromptNumberL3LocationGroupHdr  = 99824018  
SET @IntPromptNumberL3LocationDesc  = 99824019  
SET @IntPromptNumberL3StopRcdTotal  = 99824020  
SET @IntPromptNumberL3StopRcdComplete = 99824021  
SET @IntPromptNumberL3StopRcdIncomplete = 99824022  
SET @IntPromptNumberL3PercentComplete = 99824023  
---------------------------------------------------------------------------------------------------  
SET @IntPromptNumberL4DetailsGroupHdr   = 99824024  
SET @IntPromptNumberL4DetId     = 99824025  
SET @IntPromptNumberL4DelayTreeDesc   = 99824026  
SET @IntPromptNumberL4DelayTreeMaxRLevel = 99824027  
SET @IntPromptNumberL4LineStatusDesc  = 99824028  
SET @IntPromptNumberL4DelayStartTime  = 99824029  
SET @IntPromptNumberL4DelayEndTime   = 99824030  
SET @IntPromptNumberL4DelayUserName   = 99824031  
SET @IntPromptNumberL4Autocause    = 99824032  
SET @IntPromptNumberL4RL1Desc    = 99824033  
SET @IntPromptNumberL4RL2Desc    = 99824034  
SET @IntPromptNumberL4RL3Desc    = 99824035  
SET @IntPromptNumberL4RL4Desc    = 99824036  
---------------------------------------------------------------------------------------------------  
-- Code Skip Flag will skip code when @RptGBU = Family Care  
---------------------------------------------------------------------------------------------------  
SELECT @IntCodeSkipFamCare =  CASE WHEN CHARINDEX('Fam', @RptGBU) > 0  
          THEN 1  
          ELSE 0  
        END  
---------------------------------------------------------------------------------------------------  
-- RE Report Type Name and Parameter Name to look up LineStatus Filter for Good Production  
---------------------------------------------------------------------------------------------------  
SET @RptTypeName  = 'RE_LocalRptStopReasonEdits'  
SET @RptParamName = 'Local_PG_strRptGoodProductionLineStatusIdList'  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
SET @dtmTempDate = GetDate()  
SET @IntSecNumber  = @IntSecNumber + 1  
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - Prepare Tables '  
--=================================================================================================  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Language Prompt DEFAULTs'  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString) VALUES (@IntPromptNumberPGFooter, 'for Procter and Gamble Internal Use Only')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString) VALUES (@IntPromptNumberPrepared, 'Prepared')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString) VALUES (@IntPromptNumberExecutionTime, 'Execution Time')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString) VALUES (@IntPromptNumberSummary, 'Summary')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString) VALUES (@IntPromptNumberDetail, 'Detail')  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColPLGroupHdrFlag, RptColLevelNumber) VALUES (@IntPromptNumberL1PLGroupHdr, 'RE Total by Production Line', 1, 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPLGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL1PLDesc, 'Production Line', 1, 1, 1, 2)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPLGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL1StopRcdTotal, 'Total', 1, 1, 1, 3, '#', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPLGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL1StopRcdComplete, 'Complete', 1, 1, 1, 4, '#', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPLGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL1StopRcdIncomplete, 'Incomplete', 1, 1, 1, 5, '#', 1) 
 
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPLGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType, RptColPrecision) VALUES (@IntPromptNumberL1PercentComplete, 'Percent Complete',
 1, 1, 1, 6, '%',2, 2)  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColPUGroupHdrFlag, RptColLevelNumber) VALUES (@IntPromptNumberL2PUGroupHdr, 'RE Total by Production Unit', 1, 2)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPUGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL2PUDesc, 'Production Unit', 1, 1, 2, 3)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPUGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdTotal, 'Total', 1, 1, 2, 4, '#', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPUGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdComplete, 'Complete', 1, 1, 2, 5, '#', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPUGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdIncomplete, 'Incomplete', 1, 1, 2, 6, '#', 1) 
 
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColPUGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType, RptColPrecision) VALUES (@IntPromptNumberL2PercentComplete, 'Percent Complete',
 1, 1, 2, 7, '%',2, 2)  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColLocationGroupHdrFlag, RptColLevelNumber) VALUES (@IntPromptNumberL3LocationGroupHdr, 'RE Total by Location', 1, 3)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColLocationGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL3LocationDesc, 'Location', 1, 1, 3, 4)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColLocationGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdTotal, 'Total', 1, 1, 3, 5, '#', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColLocationGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdComplete, 'Complete', 1, 1, 3, 6, '#', 1
)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColLocationGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType) VALUES (@IntPromptNumberL2StopRcdIncomplete, 'Incomplete', 1, 1, 3, 7, '#
', 1)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColLocationGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits, RptColDataType, RptColPrecision) VALUES (@IntPromptNumberL2PercentComplete, 'Percent Comp
lete', 1, 1, 3, 8, '%',2, 2)  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColDetailsGroupHdrFlag, RptColLevelNumber) VALUES (@IntPromptNumberL4DetailsGroupHdr, 'RE Incomplete Record Details', 1, 4)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4DetId, 'DetId', 1, 1, 4, 5)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4DelayTreeDesc, 'Reason Tree', 1, 1, 4, 6)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4DelayTreeMaxRLevel, 'Max Level', 1, 1, 4, 7)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4LineStatusDesc, 'Line Status', 1, 1, 4, 8)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits) VALUES (@IntPromptNumberL4DelayStartTime, 'Start Time', 1, 1, 4, 9, 'yyyy-mm-dd')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx, RptColEngUnits) VALUES (@IntPromptNumberL4DelayStartTime, 'End Time', 1, 1, 4, 10, 'yyyy-mm-dd')  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4DelayUserName, 'User Name', 1, 1, 4, 11)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4Autocause, 'Autocause', 1, 1, 4, 12)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4RL1Desc, 'RL1', 1, 1, 4, 13)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4RL2Desc, 'RL2', 1, 1, 4, 14)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4RL3Desc, 'RL3', 1, 1, 4, 15)  
INSERT INTO @tblLanguagePromptDefaultValues (PromptNumber, DefaultPromptString, RptColFlag, RptColDetailsGroupHdrFlag, RptColLevelNumber, RptColIdx) VALUES (@IntPromptNumberL4RL4Desc, 'RL4', 1, 1, 4, 16)  
---------------------------------------------------------------------------------------------------  
-- Use DEFAULT string is Prompt String is not present  
---------------------------------------------------------------------------------------------------  
UPDATE @tblLanguagePromptDefaultValues  
  SET RptPromptString = Coalesce(PromptString, DefaultPromptString)  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . RE Report Column List'  
---------------------------------------------------------------------------------------------------  
-- Report level 1 headers  
---------------------------------------------------------------------------------------------------  
SELECT @vchrTempString = RptPromptString  
  FROM @tblLanguagePromptDefaultValues  
  WHERE PromptNumber = @IntPromptNumberL1PLGroupHdr  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblMatrixColHdrList (  
   ColIdx  ,  
   LevelNumber  ,  
    ColDesc1  ,  
    ColDesc2  ,  
    ColDataType  ,  
    ColPrecision ,  
    ColEngUnits  ,  
   PromptNumber )  
  SELECT RptColIdx   ,  
   RptColLevelNumber ,  
   @vchrTempString  ,  
    RptPromptString  ,  
    RptColDataType  ,  
    RptColPrecision  ,  
    RptColEngUnits  ,  
   PromptNumber  
  FROM @tblLanguagePromptDefaultValues  
  WHERE RptColFlag = 1  
  AND  RptColPLGroupHdrFlag = 1  
ORDER BY RcdId  
---------------------------------------------------------------------------------------------------  
-- Report level 2 headers  
---------------------------------------------------------------------------------------------------  
SELECT @vchrTempString = RptPromptString  
  FROM @tblLanguagePromptDefaultValues  
  WHERE PromptNumber = @IntPromptNumberL2PUGroupHdr  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblMatrixColHdrList (  
   ColIdx  ,  
   LevelNumber  ,  
    ColDesc1  ,  
    ColDesc2  ,  
    ColDataType  ,  
    ColPrecision ,  
    ColEngUnits  ,  
   PromptNumber )  
  SELECT RptColIdx   ,  
   RptColLevelNumber ,  
   @vchrTempString  ,  
    RptPromptString  ,  
    RptColDataType  ,  
    RptColPrecision  ,  
    RptColEngUnits  ,  
   PromptNumber  
  FROM @tblLanguagePromptDefaultValues  
  WHERE RptColFlag = 1  
  AND  RptColPUGroupHdrFlag = 1  
ORDER BY RcdId  
---------------------------------------------------------------------------------------------------  
-- Report level 3 headers  
---------------------------------------------------------------------------------------------------  
SELECT @vchrTempString = RptPromptString  
  FROM @tblLanguagePromptDefaultValues  
  WHERE PromptNumber = @IntPromptNumberL3LocationGroupHdr  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblMatrixColHdrList (  
   ColIdx  ,  
   LevelNumber  ,  
    ColDesc1  ,  
    ColDesc2  ,  
    ColDataType  ,  
    ColPrecision ,  
    ColEngUnits  ,  
   PromptNumber )  
  SELECT RptColIdx   ,  
   RptColLevelNumber ,  
   @vchrTempString  ,  
    RptPromptString  ,  
    RptColDataType  ,  
    RptColPrecision  ,  
    RptColEngUnits  ,  
   PromptNumber  
  FROM @tblLanguagePromptDefaultValues  
  WHERE RptColFlag = 1  
  AND  RptColLocationGroupHdrFlag = 1  
ORDER BY RcdId  
---------------------------------------------------------------------------------------------------  
-- Report level 4 headers  
---------------------------------------------------------------------------------------------------  
SELECT @vchrTempString = RptPromptString  
  FROM @tblLanguagePromptDefaultValues  
  WHERE PromptNumber = @IntPromptNumberL4DetailsGroupHdr  
---------------------------------------------------------------------------------------------------  
INSERT INTO @tblMatrixColHdrList (  
   ColIdx  ,  
   LevelNumber  ,  
    ColDesc1  ,  
    ColDesc2  ,  
    ColDataType  ,  
    ColPrecision ,  
    ColEngUnits  ,  
   PromptNumber )  
  SELECT RptColIdx   ,  
   RptColLevelNumber ,  
   @vchrTempString  ,  
    RptPromptString  ,  
    RptColDataType  ,  
    RptColPrecision  ,  
    RptColEngUnits  ,  
   PromptNumber  
  FROM @tblLanguagePromptDefaultValues  
  WHERE RptColFlag = 1  
  AND  RptColDetailsGroupHdrFlag = 1  
ORDER BY RcdId  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Get Line Statust Filter for Good Production'  
---------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------  
-- Business rule for the calculation of % Edits Good Production  
-- % Edits Good Production = Edited Records / Total Stops  
-- A record will be considered complete is all required reason levels are full.   
-- The number of required reason levels is determined by the reason tree that is associated with the Source_PUId   
-- Data set will exclude Production Units where PU_Desc like '%Packer%'  
-- Where Line_Statuses = "Scheduled MaINTenance" and "E.O. Shippable"  
-- The Line_Status_Id filter = Default_Value field in dbo.Report_Type_Parameters where:  
-- Report_Type_Id WHERE Description = "RE_LocalRptStopReasonEdits" in dbo.Report_Types and   
-- RP_Id WHERE RP_Name = "Local_PG_strRptGoodProductionLineStatusIdList"  
---------------------------------------------------------------------------------------------------  
-- Get Report Type Id  
---------------------------------------------------------------------------------------------------  
SELECT @ReportTypeId = Report_Type_Id  
 FROM dbo.Report_Types  
 WHERE Description = @RptTypeName  
---------------------------------------------------------------------------------------------------  
-- Get Report Type Parameter Id  
---------------------------------------------------------------------------------------------------  
SELECT @RPId = RP_Id  
 FROM dbo.Report_Parameters  
 WHERE RP_Name = @RptParamName  
---------------------------------------------------------------------------------------------------  
-- Get Report Type Parameter Value  
---------------------------------------------------------------------------------------------------  
SELECT @RptGoodProductionLineStatusIdList = COALESCE(Default_Value, '1|2')  
 FROM dbo.Report_Type_Parameters  
 WHERE Report_Type_Id  =  @ReportTypeId  
 AND  RP_Id   = @RPId  
  
IF @IntFlgPrint = 1 PRINT '  . @RptGoodProductionLineStatusIdList ' + @RptGoodProductionLineStatusIdList  
---------------------------------------------------------------------------------------------------  
-- Set default value if parameter is not found  
---------------------------------------------------------------------------------------------------  
IF LEN(@RptGoodProductionLineStatusIdList) = 0  
BEGIN  
 SET @RptGoodProductionLineStatusIdList = '1|2'  
END  
---------------------------------------------------------------------------------------------------  
INSERT INTO #LineStatusFilter (RcdId, LineStatusId)  
EXEC  spCmn_ReportCollectionParsing  
  @PRMCollectionString = @RptGoodProductionLineStatusIdList,   
  @PRMFieldDelimiter = NULL,   
  @PRMRecordDelimiter = '|',  
  @PRMDataType01 = 'Int'  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Get Production Unit List'  
---------------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------------  
-- Get all the production units available  
-- Note: sometimes crew scheduled and line status schedules are not configured on all production  
-- units. Units that do not have crew schedules and line status schedules configured will poINT to  
-- a production units that does via "STLS=" key word on the production units extended info field  
---------------------------------------------------------------------------------------------------  
DELETE @tblPUList  
INSERT INTO @tblPUList (  
   PUId ,  
   PUDesc ,  
   AlternativePUId)  
 SELECT pu.PU_Id ,  
   pu.PU_Desc ,  
   CASE WHEN (CHARINDEX ('STLS=', pu.Extended_Info, 1)) > 0  
     THEN SUBSTRING ( pu.Extended_Info,  
       ( CHARINDEX ('STLS=', pu.Extended_Info, 1) + 5),  
        CASE  WHEN  (CHARINDEX(';', pu.Extended_Info, CHARINDEX('STLS=', pu.Extended_Info, 1))) > 0  
          THEN  (CHARINDEX(';', pu.Extended_Info, CHARINDEX('STLS=', pu.Extended_Info, 1)) - (CHARINDEX('STLS=', pu.Extended_Info, 1) + 5))   
          ELSE  LEN(pu.Extended_Info)  
        END )  
   END  
 FROM dbo.Prod_Units pu  WITH (NOLOCK)  
 JOIN dbo.Prod_Lines pl  WITH (NOLOCK)  
        ON pl.PL_Id = pu.PL_Id  
 WHERE PU_Id > 0  
 AND  (@RptGBU IS NULL  
 OR  CHARINDEX('GBU=', pl.Extended_Info) = 0  
 OR  CHARINDEX('GBU=' + @RptGBU, pl.Extended_Info) > 0)  
---------------------------------------------------------------------------------------------------  
-- Note: the LookUpPUId is the PUId that is need to look up the line status for the delay record  
---------------------------------------------------------------------------------------------------  
UPDATE @tblPUList  
 SET LookupPUId = Coalesce(AlternativePUId, PUId)  
---------------------------------------------------------------------------------------------------  
-- Eliminate the '%Packer%' production units  
---------------------------------------------------------------------------------------------------  
DELETE @tblPUList  
 WHERE PUDesc Like '%Packer%'  
DELETE @tblPUList  
 WHERE PUDesc Like '%Stacker%'  
DELETE @tblPUList  
 WHERE PUDesc Like '%Wrapper%'  
DELETE @tblPUList  
 WHERE PUDesc Like '%ACP%'  
  
-- DELETE @tblPUList  
-- WHERE PUDesc NOT Like '%Converter%'  
  
--SELECT '@tblPUList', COUNT(*) FROM @tblPUList  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT '  . Get Stop Records'  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2  
BEGIN  
 IF @IntCodeSkipFamCare = 0  
 BEGIN  
  IF @RptDataFilter = 'REGoodProd'  
  BEGIN  
   INSERT INTO @tblREList  (  
      PLId   ,  
      PUId   ,  
      SourcePUId  ,  
      DelayTreePUId ,  
      DetId   ,  
--      LineStatusId ,  
      DelayStartTime ,  
      DelayEndTime ,  
      DelayUserId  ,  
      TEFaultId  ,  
      RL1Id   ,  
      RL2Id   ,  
      RL3Id   ,  
      RL4Id   )  
    SELECT  pu.PL_Id   ,  
      ted.PU_Id   ,  
      COALESCE(ted.Source_PU_Id, 0)   ,  
      COALESCE(ted.Source_PU_Id, ted.PU_Id) ,  
      ted.TEDet_Id  ,  
--      ls.Line_Status_Id ,  
      ted.Start_Time  ,  
      ted.End_Time  ,  
      ted.User_Id   ,  
      ted.TEFault_Id  ,  
      ted.Reason_Level1 ,  
      ted.Reason_Level2 ,  
      ted.Reason_Level3 ,  
      ted.Reason_Level4   
    FROM  dbo.Timed_Event_Details  ted WITH (NOLOCK)  
    JOIN @tblPUList     pul ON pul.PUId = ted.PU_Id  
    JOIN dbo.Prod_Units    pu WITH (NOLOCK)  
              ON pul.PUId = pu.PU_Id  
/*  
    JOIN dbo.Local_PG_Line_Status  ls WITH (NOLOCK)  
              ON pul.LookUpPUId = ls.Unit_Id  
              AND ted.Start_Time  >= ls.Start_DateTime  
              AND (ted.Start_Time <  ls.End_DateTime  
              OR ls.End_DateTime IS NULL)  
    JOIN #LineStatusFilter   lsf ON lsf.LineStatusId = ls.Line_Status_Id  
*/  
    WHERE  ted.Start_Time >= @dtmStartTime   
    AND  ted.Start_Time <  @dtmEndTime  
  
    -- Find Line_Status  
    UPDATE  re  
     SET  re.LineStatusId = ls.Line_Status_Id  
     FROM  @tblREList     re  
     JOIN  dbo.Timed_Event_Details  ted WITH (NOLOCK)   
               ON re.DetId = ted.TEDet_Id  
     JOIN @tblPUList     pul ON pul.PUId = ted.PU_Id  
     JOIN dbo.Prod_Units    pu WITH (NOLOCK)  
               ON pul.PUId = pu.PU_Id  
     JOIN dbo.Local_PG_Line_Status  ls WITH (NOLOCK)  
               ON pul.LookUpPUId = ls.Unit_Id  
               AND ted.Start_Time  >= ls.Start_DateTime  
               AND (ted.Start_Time <  ls.End_DateTime  
               OR ls.End_DateTime IS NULL)  
     JOIN #LineStatusFilter   lsf ON lsf.LineStatusId = ls.Line_Status_Id  
  
  END  
  ELSE  
  BEGIN  
   INSERT INTO @tblREList  (  
      PLId   ,  
      PUId   ,  
      SourcePUId  ,  
      DelayTreePUId ,  
      DetId   ,  
--      LineStatusId ,  
      DelayStartTime ,  
      DelayEndTime ,  
      DelayUserId  ,  
      TEFaultId  ,  
      RL1Id   ,  
      RL2Id   ,  
      RL3Id   ,  
      RL4Id   )  
    SELECT  pu.PL_Id   ,  
      ted.PU_Id   ,  
      COALESCE(ted.Source_PU_Id, 0)   ,  
      COALESCE(ted.Source_PU_Id, ted.PU_Id) ,  
      ted.TEDet_Id  ,  
--      ls.Line_Status_Id ,  
      ted.Start_Time  ,  
      ted.End_Time  ,  
      ted.User_Id   ,  
      ted.TEFault_Id  ,  
      ted.Reason_Level1 ,  
      ted.Reason_Level2 ,  
      ted.Reason_Level3 ,  
      ted.Reason_Level4   
    FROM  dbo.Timed_Event_Details  ted WITH (NOLOCK)  
    JOIN @tblPUList     pul ON pul.PUId = ted.PU_Id  
    JOIN dbo.Prod_Units    pu WITH (NOLOCK)  
              ON pul.PUId = pu.PU_Id  
/*  
    JOIN dbo.Local_PG_Line_Status  ls WITH (NOLOCK)  
              ON pul.LookUpPUId = ls.Unit_Id  
              AND ted.Start_Time  >= ls.Start_DateTime  
              AND (ted.Start_Time <  ls.End_DateTime  
              OR ls.End_DateTime IS NULL)  
*/  
    WHERE  ted.Start_Time >= @dtmStartTime   
    AND  ted.Start_Time <  @dtmEndTime  
  
    -- Find Line_Status  
    UPDATE   re  
     SET  re.LineStatusId = ls.Line_Status_Id  
     FROM  @tblREList     re  
     JOIN  dbo.Timed_Event_Details  ted WITH (NOLOCK)   
               ON re.DetId = ted.TEDet_Id  
     JOIN @tblPUList     pul ON pul.PUId = ted.PU_Id  
     JOIN dbo.Prod_Units    pu WITH (NOLOCK)  
               ON pul.PUId = pu.PU_Id  
     JOIN dbo.Local_PG_Line_Status  ls WITH (NOLOCK)  
               ON pul.LookUpPUId = ls.Unit_Id  
               AND ted.Start_Time  >= ls.Start_DateTime  
               AND (ted.Start_Time <  ls.End_DateTime  
               OR ls.End_DateTime IS NULL)  
  END  
 END  
 ELSE  
 BEGIN  
  INSERT INTO @tblREList  (  
     PLId   ,  
     PUId   ,  
     SourcePUId  ,  
     DelayTreePUId ,  
     DetId   ,  
     DelayStartTime ,  
     DelayEndTime ,  
     DelayUserId  ,  
     TEFaultId  ,  
     RL1Id   ,  
     RL2Id   ,  
     RL3Id   ,  
     RL4Id   )  
   SELECT  pu.PL_Id   ,  
     ted.PU_Id   ,  
     COALESCE(ted.Source_PU_Id, 0)   ,  
     COALESCE(ted.Source_PU_Id, ted.PU_Id) ,  
     ted.TEDet_Id  ,  
     ted.Start_Time  ,  
     ted.End_Time  ,  
     ted.User_Id   ,  
     ted.TEFault_Id  ,  
     ted.Reason_Level1 ,  
     ted.Reason_Level2 ,  
     ted.Reason_Level3 ,  
     ted.Reason_Level4   
   FROM  dbo.Timed_Event_Details  ted WITH (NOLOCK)  
   JOIN @tblPUList     pul ON pul.PUId = ted.PU_Id  
   JOIN dbo.Prod_Units    pu WITH (NOLOCK)  
             ON pul.PUId = pu.PU_Id  
   WHERE  ted.Start_Time >= @dtmStartTime   
   AND  ted.Start_Time <  @dtmEndTime  
 END  
 -----------------------------------------------------------------------------------------------  
 -- Get the max reason level for each tree  
 -----------------------------------------------------------------------------------------------  
 UPDATE   re  
    SET  DelayTreeId = pe.Name_Id  
    FROM @tblREList   re  
    JOIN  dbo.Prod_Events pe  WITH (NOLOCK)  
           ON re.DelayTreePUId = pe.PU_Id  
    WHERE pe.Event_Type = 2 -- Event_type = 2 (Delay)  
 -----------------------------------------------------------------------------------------------  
 -- Get the maximum reason level for each reason tree  
 -- the join to dbo.Event_Reason_Tree_Data made the sp very slow, so this table just finds the  
 -- Max reason level for every tree configured  
 -----------------------------------------------------------------------------------------------  
 INSERT INTO @tblReasonTreeList (  
     DelayTreeId   ,  
     DelayTreeMaxRLevel )  
   SELECT ertd.Tree_Name_Id   ,  
     Max(ertd.Event_Reason_Level)  
   FROM dbo.Event_Reason_Tree_Data ertd   
  GROUP BY ertd.Tree_Name_Id  
 -----------------------------------------------------------------------------------------------  
 IF @IntFlgPrint = 1 PRINT '  . Flag Completed Records'  
 -----------------------------------------------------------------------------------------------  
 -- Flag completed records for reason trees that only have 1 level of reasons  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblREList  
  SET  FlagRcdComplete = 1  
  FROM @tblREList   re   
  JOIN @tblReasonTreeList rtl ON rtl.DelayTreeId = re.DelayTreeId  
  WHERE DelayTreeMaxRLevel  = 1   
  AND  re.RL1Id > 0  
 -----------------------------------------------------------------------------------------------  
 -- Flag completed records for reason trees that only have 2 level of reasons  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblREList  
  SET  FlagRcdComplete = 1  
  FROM @tblREList   re   
  JOIN @tblReasonTreeList rtl ON rtl.DelayTreeId = re.DelayTreeId  
  WHERE DelayTreeMaxRLevel  = 2   
  AND  re.RL2Id > 0  
 -----------------------------------------------------------------------------------------------  
 -- Flag completed records for reason trees that only have 3 level of reasons  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblREList  
  SET  FlagRcdComplete = 1  
  FROM @tblREList   re   
  JOIN @tblReasonTreeList rtl ON rtl.DelayTreeId = re.DelayTreeId  
  WHERE DelayTreeMaxRLevel  = 3   
  AND  re.RL3Id > 0  
 -----------------------------------------------------------------------------------------------  
 -- Flag completed records for reason trees that only have 4 level of reasons  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblREList  
  SET  FlagRcdComplete = 1  
  FROM @tblREList   re   
  JOIN @tblReasonTreeList rtl ON rtl.DelayTreeId = re.DelayTreeId  
  WHERE DelayTreeMaxRLevel  = 4   
  AND  re.RL4Id > 0  
END  
  
-- SELECT '@tblREList', COUNT(*) FROM @tblREList  
  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
SET @dtmTempDate  = GetDate()  
SET @IntSecNumber  = @IntSecNumber + 1  
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - Get Data '  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT '  . Prepare RS2 Production Line List '  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2  
BEGIN  
 INSERT INTO @tblProductionLineList (  
    PLId   ,  
    PLDesc   ,  
    StopRcdTotal ,  
    StopRcdComplete )  
  SELECT rel.PLId  ,  
    pl.PL_Desc  ,  
    COUNT(DetId) ,  
    SUM(FlagRcdComplete)  
  FROM @tblREList  rel  
  JOIN dbo.Prod_Lines pl WITH (NOLOCK)  
         ON rel.PLId = pl.PL_Id  
 GROUP BY rel.PLId, pl.PL_Desc   
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblProductionLineList  
  SET StopRcdIncomplete = StopRcdTotal - StopRcdComplete  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblProductionLineList  
  SET  PercentComplete = ((StopRcdComplete * 1.0) / (StopRcdTotal * 1.0)) * 100.0  
  WHERE StopRcdTotal > 0  
  
-- SELECT '@tblProductionLineList', COUNT(*) FROM @tblProductionLineList  
 -----------------------------------------------------------------------------------------------  
 IF @IntFlgPrint = 1 PRINT '  . Prepare RS3 Production Unit List '  
 -----------------------------------------------------------------------------------------------  
 INSERT INTO @tblProductionUnitList (  
    PLId   ,  
    PUId   ,  
    PUDesc   ,  
    StopRcdTotal ,  
    StopRcdComplete )  
  SELECT rel.PLId  ,  
    rel.PUId  ,  
    pu.PU_Desc  ,  
    COUNT(DetId) ,  
    SUM(FlagRcdComplete)  
  FROM @tblREList  rel  
  JOIN dbo.Prod_Units pu WITH (NOLOCK)  
         ON rel.PUId = pu.PU_Id  
 GROUP BY rel.PLId, rel.PUId, pu.PU_Desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblProductionUnitList  
  SET StopRcdIncomplete = StopRcdTotal - StopRcdComplete  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblProductionUnitList  
  SET  PercentComplete = ((StopRcdComplete * 1.0) / (StopRcdTotal * 1.0)) * 100.0  
  WHERE StopRcdTotal > 0  
 -----------------------------------------------------------------------------------------------  
 IF @IntFlgPrint = 1 PRINT '  . Prepare RS4 Location List '  
 -----------------------------------------------------------------------------------------------  
 INSERT INTO @tblLocationList (  
    PLId    ,  
    PUId    ,  
    SourcePUId   ,  
    SourcePUDesc  ,  
    StopRcdTotal  ,  
    StopRcdComplete  )  
  SELECT rel.PLId  ,  
    rel.PUId  ,  
    rel.SourcePUId ,  
    CASE WHEN rel.SourcePUId = 0  
      THEN '<< BLANK >>'  
      ELSE pu.PU_Desc  
    END    ,      
    COUNT(DetId) ,  
    SUM(FlagRcdComplete)  
  FROM @tblREList  rel  
  JOIN dbo.Prod_Units pu WITH (NOLOCK)  
         ON rel.SourcePUId = pu.PU_Id  
 GROUP BY rel.PLId, rel.PUId, rel.SourcePUId, pu.PU_Desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblLocationList  
  SET StopRcdIncomplete = StopRcdTotal - StopRcdComplete  
 -----------------------------------------------------------------------------------------------  
 UPDATE @tblLocationList  
  SET  PercentComplete = ((StopRcdComplete * 1.0) / (StopRcdTotal * 1.0)) * 100.0  
  WHERE StopRcdTotal > 0  
 -----------------------------------------------------------------------------------------------  
 IF @IntFlgPrint = 1 PRINT '  . Prepare RS5 Non-edited Record List '  
 -----------------------------------------------------------------------------------------------  
 INSERT INTO @tblStopRcdIncompleteList (  
    PLId   ,  
    PUId   ,  
    SourcePUId  ,  
     DetId   ,  
     DelayTreeId  ,  
     LineStatusId ,  
    DelayStartTime ,  
    DelayEndTime ,  
    DelayUserId  ,  
     TEFaultId  ,  
     RL1Id   ,  
     RL2Id   ,  
    RL3Id   ,  
     RL4Id   )   
  SELECT PLId   ,  
    PUId   ,  
    SourcePUId  ,  
    DetId   ,  
    DelayTreeId  ,  
    LineStatusId ,  
    DelayStartTime ,  
    DelayEndTime ,  
    DelayUserId  ,  
    TEFaultId  ,  
    RL1Id   ,  
    RL2Id   ,  
    RL3Id   ,  
    RL4Id     
  FROM @tblREList  
  WHERE FlagRcdComplete = 0  
 -----------------------------------------------------------------------------------------------  
 -- Update Reason Tree Name  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.DelayTreeDesc   = ert.Tree_Name,  
   ril.DelayTreeMaxRLevel  = rtl.DelayTreeMaxRLevel  
  FROM @tblStopRcdIncompleteList ril   
  JOIN @tblReasonTreeList   rtl ON rtl.DelayTreeId  = ril.DelayTreeId  
  JOIN dbo.Event_Reason_Tree  ert WITH (NOLOCK)  
            ON ert.Tree_Name_Id  = rtl.DelayTreeId  
 -----------------------------------------------------------------------------------------------  
 -- Update Line Status Desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.LineStatusDesc  = p.Phrase_Value  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Phrase     p WITH (NOLOCK)  
            ON p.Phrase_Id = ril.LineStatusId  
 -----------------------------------------------------------------------------------------------  
 -- Update Delay User Name  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.DelayUserName = u.UserName  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Users     u WITH (NOLOCK)  
            ON u.User_Id = ril.DelayUserId  
 -----------------------------------------------------------------------------------------------  
 -- Update TE_Fault desc (Autocause)  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.Autocause = TEFault_Name  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Timed_Event_Fault  tef WITH (NOLOCK)    
            ON tef.TEFault_Id = ril.TEFaultId  
 -----------------------------------------------------------------------------------------------  
 -- Update reason level 1 desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.RL1Desc = re.Event_Reason_Name  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Event_Reasons   re WITH (NOLOCK)    
            ON re.Event_Reason_Id = ril.RL1Id  
 -----------------------------------------------------------------------------------------------  
 -- Update reason level 2 desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.RL2Desc = re.Event_Reason_Name  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Event_Reasons   re WITH (NOLOCK)    
            ON re.Event_Reason_Id = ril.RL2Id  
 -----------------------------------------------------------------------------------------------  
 -- Update reason level 3 desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.RL3Desc = re.Event_Reason_Name  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Event_Reasons   re WITH (NOLOCK)    
            ON re.Event_Reason_Id = ril.RL3Id  
 -----------------------------------------------------------------------------------------------  
 -- Update reason level 4 desc  
 -----------------------------------------------------------------------------------------------  
 UPDATE ril  
  SET ril.RL4Desc = re.Event_Reason_Name  
  FROM @tblStopRcdIncompleteList ril   
  JOIN dbo.Event_Reasons   re WITH (NOLOCK)    
            ON re.Event_Reason_Id = ril.RL4Id  
 -----------------------------------------------------------------------------------------------  
 -- Update DetRcdGroupId  
 -----------------------------------------------------------------------------------------------  
 UPDATE sil  
  SET sil.DetRcdGroupId = ll.RcdIdx  
  FROM @tblStopRcdIncompleteList  sil  
  JOIN @tblLocationList   ll ON  ll.PLId = sil.PLId  
            AND ll.PUId = sil.PUId  
            AND ll.SourcePUId = sil.SourcePUId  
END  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
SET @dtmTempDate  = GetDate()  
SET @IntSecNumber  = @IntSecNumber + 1  
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - Result sets'  
--=================================================================================================  
-- RS1: Column List  
---------------------------------------------------------------------------------------------------  
-- NOTE: WEB pages dont like NULL values, so use "!NULL" to identify a NULL cell and have the VB  
-- code filter it out  
---------------------------------------------------------------------------------------------------  
SET @i = 1  
SELECT @intMaxColCount = COUNT(ColIdx)  
 FROM @tblMatrixColHdrList  
WHILE @i <= @intMaxColCount  
BEGIN  
 SELECT @intTempPromptNumber = PromptNumber  
  FROM @tblMatrixColHdrList  
  WHERE RcdIdx = @i  
 -----------------------------------------------------------------------------------------------  
 SELECT @vchrTempString = REPLACE(ColDesc2, ' ', '|')   
  FROM @tblMatrixColHdrList   
  WHERE PromptNumber = @intTempPromptNumber  
  
  
 -----------------------------------------------------------------------------------------------   
 DELETE #TempString  
 INSERT INTO #TempString (RcdId, TempString)  
 EXEC  spCmn_ReportCollectionParsing  
   @PRMCollectionString = @vchrTempString,   
   @PRMFieldDelimiter = NULL,   
   @PRMRecordDelimiter = '|',  
   @PRMDataType01 = 'VARCHAR(100)'  
 -----------------------------------------------------------------------------------------------   
 -- Column width for the report is the length of the longest word in the string  
 -----------------------------------------------------------------------------------------------   
 SELECT @intMaxLength = MAX(LEN(TempString))  
  FROM #TempString  
 -----------------------------------------------------------------------------------------------   
 -- The word count determines the height of the header row in the report  
 -----------------------------------------------------------------------------------------------   
 SELECT @intColWordCount = COUNT(RcdId)  
  FROM #TempString  
 -----------------------------------------------------------------------------------------------   
 UPDATE @tblMatrixColHdrList   
  SET ColWidth    =  CASE WHEN @intMaxLength < 4  
           THEN @intMaxLength * 12  
           ELSE @intMaxLength * 10  
         END,   
   ColDesc2WordCount = @intColWordCount  
  WHERE PromptNumber = @intTempPromptNumber  
 -----------------------------------------------------------------------------------------------   
 SET @i = @i + 1  
END  
  
---------------------------------------------------------------------------------------------------  
-- Find the longest description string of the 3 levels  
---------------------------------------------------------------------------------------------------  
SELECT @intPLDescLength = MAX(LEN(PL_Desc)) * 10  
 FROM dbo.Prod_Lines WITH (NOLOCK)  
---------------------------------------------------------------------------------------------------  
SELECT @intPUDescLength = MAX(LEN(PU_Desc)) * 10  
 FROM dbo.Prod_Units pu WITH (NOLOCK)  
 JOIN dbo.Prod_Events pe WITH (NOLOCK)  
        ON pu.PU_Id = pe.PU_Id  
        AND pe.Event_Type = 2   
 WHERE pu.Master_Unit IS NULL  
---------------------------------------------------------------------------------------------------  
SELECT @intLocationDescLength = MAX(LEN(PU_Desc)) * 10  
 FROM dbo.Prod_Units pu WITH (NOLOCK)  
 JOIN dbo.Prod_Events pe WITH (NOLOCK)  
        ON pu.Master_Unit = pe.PU_Id  
        AND pe.Event_Type = 2   
---------------------------------------------------------------------------------------------------  
-- Compare lengths to ColWidth to ensure the title still fits the column  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL1PLDesc  
---------------------------------------------------------------------------------------------------  
IF @intColWidth > @intPLDescLength  
BEGIN  
 SET @intPLDescLength = @intColWidth  
END  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL2PUDesc  
---------------------------------------------------------------------------------------------------  
IF @intColWidth > @intPUDescLength  
BEGIN  
 SET @intPUDescLength = @intColWidth  
END  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL3LocationDesc  
---------------------------------------------------------------------------------------------------  
IF @intColWidth > @intLocationDescLength  
BEGIN  
 SET @intLocationDescLength = @intColWidth  
END  
  
---------------------------------------------------------------------------------------------------  
-- Get the maximum length for location  
---------------------------------------------------------------------------------------------------  
IF @intLocationDescLength < @intPUDescLength  
BEGIN  
 SET @intLocationDescLength = @intPUDescLength  
END  
---------------------------------------------------------------------------------------------------  
IF @intLocationDescLength < @intPLDescLength  
BEGIN  
 SET @intLocationDescLength = @intPLDescLength  
END  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L3 Location  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = @intLocationDescLength   
 WHERE PromptNumber = @IntPromptNumberL3LocationDesc  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L1 Production Lines  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = @intLocationDescLength + 40  
 WHERE PromptNumber = @IntPromptNumberL1PLDesc  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L2 Production Units  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = @intLocationDescLength + 20  
 WHERE PromptNumber = @IntPromptNumberL2PUDesc  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 DetId  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL4DetId  
---------------------------------------------------------------------------------------------------  
SELECT @intDetIdLength = MAX(LEN(TEDet_Id)) * 10  
 FROM dbo.Timed_Event_Details WITH (NOLOCK)  
---------------------------------------------------------------------------------------------------  
IF @intColWidth < @intDetIdLength  
BEGIN  
 UPDATE @tblMatrixColHdrList  
  SET ColWidth = @intDetIdLength   
  WHERE PromptNumber = @IntPromptNumberL4DetId  
END  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 Tree Desc  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL4DelayTreeDesc  
---------------------------------------------------------------------------------------------------  
SELECT @intDelayTreeDescLength = MAX(LEN(Tree_Name)) * 10  
 FROM dbo.Event_Reason_Tree WITH (NOLOCK)  
---------------------------------------------------------------------------------------------------  
IF @intColWidth < @intDelayTreeDescLength  
BEGIN  
 UPDATE @tblMatrixColHdrList  
  SET ColWidth = @intDelayTreeDescLength / 2  
  WHERE PromptNumber = @IntPromptNumberL4DelayTreeDesc  
END  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 Line Status  
---------------------------------------------------------------------------------------------------  
IF @IntCodeSkipFamCare = 0  
BEGIN  
 SELECT @intColWidth = ColWidth  
  FROM @tblMatrixColHdrList   
  WHERE PromptNumber = @IntPromptNumberL4LineStatusDesc  
 ---------------------------------------------------------------------------------------------------  
 SELECT @intLineStatusDescLength = MAX(LEN(Phrase_Value)) * 10  
  FROM dbo.Phrase     p WITH (NOLOCK)  
  JOIN dbo.Local_PG_Line_Status ls WITH (NOLOCK)  
            ON p.Phrase_Id = ls.Line_Status_Id  
 ---------------------------------------------------------------------------------------------------  
 IF @intColWidth < @intLineStatusDescLength  
 BEGIN  
  UPDATE @tblMatrixColHdrList  
   SET ColWidth = @intLineStatusDescLength / 2  
   WHERE PromptNumber = @IntPromptNumberL4LineStatusDesc  
 END  
END  
  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 Start Time and End Time  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 90  
 WHERE PromptNumber = @IntPromptNumberL4DelayStartTime  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 90  
 WHERE PromptNumber = @IntPromptNumberL4DelayEndTime  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 User  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL4DelayUserName  
---------------------------------------------------------------------------------------------------  
SELECT @intUserNameLength = MAX(LEN(ISNULL(User_Desc,''))) * 10  
 FROM dbo.Users WITH (NOLOCK)  
---------------------------------------------------------------------------------------------------  
IF @intColWidth < @intUserNameLength  
BEGIN  
 UPDATE @tblMatrixColHdrList  
  SET ColWidth = @intUserNameLength / 2  
  WHERE PromptNumber = @IntPromptNumberL4DelayUserName  
END  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 Autocause  
---------------------------------------------------------------------------------------------------  
SELECT @intColWidth = ColWidth  
 FROM @tblMatrixColHdrList   
 WHERE PromptNumber = @IntPromptNumberL4Autocause  
---------------------------------------------------------------------------------------------------  
SELECT @intAutoCauseLength = MAX(LEN(TEFault_Name)) * 10  
 FROM dbo.Timed_Event_Fault WITH (NOLOCK)    
---------------------------------------------------------------------------------------------------  
IF @intColWidth < @intAutoCauseLength  
BEGIN  
 UPDATE @tblMatrixColHdrList  
  SET ColWidth = @intAutoCauseLength / 2  
  WHERE PromptNumber = @IntPromptNumberL4Autocause  
END  
---------------------------------------------------------------------------------------------------  
-- Set a minimum width for L4 Reason Levels  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 150  
 WHERE PromptNumber = @IntPromptNumberL4RL1Desc  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 150  
 WHERE PromptNumber = @IntPromptNumberL4RL2Desc  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 150  
 WHERE PromptNumber = @IntPromptNumberL4RL3Desc  
---------------------------------------------------------------------------------------------------  
UPDATE @tblMatrixColHdrList  
 SET ColWidth = 150  
 WHERE PromptNumber = @IntPromptNumberL4RL4Desc  
---------------------------------------------------------------------------------------------------  
-- Return result set  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 1  
BEGIN  
 SELECT RcdIdx    ,  
   ColIdx    ,  
   LevelNumber   ,  
   ColDesc1   ,  
   ColDesc2   ,  
   ColDesc2WordCount  ,  
   ColDataType   ,   
   ColPrecision  ,  
   ColEngUnits   ,  
   ColWidth    
  FROM @tblMatrixColHdrList  
 ORDER BY RcdIdx, ColIdx, LevelNumber  
END  
---------------------------------------------------------------------------------------------------  
-- RS2: Production Line List  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2  
BEGIN  
 SELECT RcdIdx    ,  
   PLId    ,  
   PLDesc    ,  
   StopRcdTotal  ,  
   StopRcdComplete  ,  
   StopRcdIncomplete ,  
   PercentComplete    
 FROM @tblProductionLineList  
 ORDER BY PercentComplete ASC  
END  
---------------------------------------------------------------------------------------------------  
-- RS3: Production Unit List  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2   
BEGIN  
 SELECT RcdIdx    ,  
   PLId    ,  
   PUId    ,  
   PUDesc    ,  
   StopRcdTotal  ,  
   StopRcdComplete  ,  
   StopRcdIncomplete ,  
   PercentComplete    
 FROM @tblProductionUnitList  
 ORDER BY PercentComplete ASC  
END  
---------------------------------------------------------------------------------------------------  
-- RS4: Location List  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2  
BEGIN  
 SELECT RcdIdx    ,  
   PLId    ,  
   PUId    ,  
   SourcePUId   ,  
   SourcePUDesc  ,  
   StopRcdTotal  ,  
   StopRcdComplete  ,  
   StopRcdIncomplete ,  
   PercentComplete    
 FROM @tblLocationList  
 ORDER BY PercentComplete ASC  
END  
---------------------------------------------------------------------------------------------------  
-- RS5: Detail Stop Records  
---------------------------------------------------------------------------------------------------  
IF @RptRSFilter = 0  
OR @RptRSFilter = 2  
BEGIN  
 SELECT DetRcdGroupId  ,    
   RcdIdx    ,  
   PLId    ,  
   PUId    ,  
   SourcePUId   ,  
    DetId    ,  
   DelayTreeDesc  ,  
    DelayTreeMaxRLevel ,  
   LineStatusDesc  ,  
    CONVERT(VARCHAR, DelayStartTime, 120)  DelayStartTime ,  
    CONVERT(VARCHAR, DelayEndTime, 120)  DelayEndTime ,  
    DelayUserName  ,  
   Autocause   ,  
   RL1Desc    ,  
   RL2Desc    ,  
   RL3Desc    ,  
   RL4Desc      
 FROM  @tblStopRcdIncompleteList sil  
END  
  
--=================================================================================================  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
SET @dtmTempDate  = GetDate()  
SET @IntSecNumber  = @IntSecNumber + 1  
IF @IntFlgPrint = 1 PRINT '--------------------------------------------------------------------------------------------'  
IF @IntFlgPrint = 1 PRINT 'START SECTION : '+ Convert(VARCHAR, @IntSecNumber)  
IF @IntFlgPrint = 1 PRINT ' - List of tables for debug'  
--=================================================================================================  
-- Select from tables -- used for debugging only comment before installation  
---------------------------------------------------------------------------------------------------  
--  SELECT '@tblPUList'      , * FROM @tblPUList   
--  SELECT '@tblREList'      , * FROM @tblREList   
--  SELECT '@tblReasonTreeList'    , * FROM @tblReasonTreeList  
--  SELECT '@tblLanguagePromptDefaultValues', * FROM @tblLanguagePromptDefaultValues  
--  SELECT '@tblMatrixColHdrList'   , * FROM @tblMatrixColHdrList   
--  SELECT '@tblProductionLineList'   , * FROM @tblProductionLineList  
--  SELECT '@tblProductionUnitList'   , * FROM @tblProductionUnitList  WHERE PLId = 3  
--  SELECT '@tblLocationList'    , * FROM @tblLocationList   WHERE PLId = 3 AND PUId = 3  
--  SELECT '@tblStopRcdIncompleteList'  , * FROM @tblStopRcdIncompleteList WHERE PLId = 3 AND PUId = 3 AND SourcePUId = 7  
--  SELECT '#LineStatusFilter'    , * FROM #LineStatusFilter  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT ' - Drop tables'  
---------------------------------------------------------------------------------------------------  
DROP TABLE #LineStatusFilter  
DROP TABLE #TempString  
---------------------------------------------------------------------------------------------------  
IF @IntFlgPrint = 1 PRINT 'END SECTION : ' + Convert(VARCHAR, @IntSecNumber) + ' - TOTAL TIME (sec): ' + Convert(VARCHAR(100), DateDiff(Second, @dtmTempDate, GetDate()))   
---------------------------------------------------------------------------------------------------  
--=================================================================================================  
SET NOCOUNT OFF  
--=================================================================================================   
RETURN  
  
  
  
  
  
  
