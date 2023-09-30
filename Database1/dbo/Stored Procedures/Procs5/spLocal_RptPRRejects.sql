 --Last Modified: 2006-Jun-29 Namho Kim Rev2.1  
/*  
---------------------------------------------------------------------------------------------------------------------------------------  
Updated By : Normand Carbonneau (System Technologies for Industry Inc)  
Date   : 2005-06-29  
Version  : 2.0.0  
Purpose  :  P4 Migration  
     This Stored Procedure was verified to be conform with P4.  
     Joins on Event_Details table were removed at four places. Search for 'Removed P4' text to find corresponding code.  
---------------------------------------------------------------------------------------------------------------------------------------  
--   
-- The intent of this SP is to provide converting and papermaking with Parent Roll data.  
-- The converting result set is returning all Parent Rolls ran on the configured converting lines  
-- for the report period.  The result set is returned to the template and used to create a pivot table.  
-- The papermaking result set is returning only rejected parent rolls (rejected by papermaking!).  
--  
-- 2002-12-13 Vince King  
--  - Changed some of the column names per Paula Pardoe and Kim Rafferty.   
--   Event Number => PRoll ULID  
--   Turnover Position => PRoll Position  
--   Pmkg event data, Cvtg Roll Status => Pmkg Roll Status (had wrong column name).  
--  
-- 2002-12-20 Vince King  
--  - Added two new result sets to help Line Supply ensure that they are reviewing all rejects.    
--    All data is returned for these results sets, then the data is filtered in Excel using an  
--    AutoFilter.  
--   1) Return cvtg data for rows with [LSP T# and Initials] = NULL.  
--   2) Return pmkg data for rows with [LSP T# and Intitals] = NULL.  
--  
-- 2003-02-05 Vince King  
--  - Changed the variable desc LSP T# and Initials to RTCIS Reject Work Complete?.  
--  
-- 2004-02-26 Jeff Jaeger  Revision 1.1  
--  - Moved all create statements to the top of the procedure.  
--  - Added drop table statements for all temp tables.  
--  - Added additional control flow, so that only the #ErrorMessages will be returned if there is   
--    a problem with the parameters.  
--  - Added validation checks for the input parameters.  
--  - Added 'Initial Slab Radius 1', 'Final Slab Radius 1', 'Initial Slab Radius 2', 'Final Slab Radius 2',  
--    'Initial Slab Radius 3', 'Final Slab Radius 3', 'Roll Slab Weight', 'Slab Weight', 'Paper Defect Cause'  
--    test variables and related code, to display these values in result sets.  
--  - Changed the first two heards in the Cvtg LSP result set.  
--  - Converted look-up that use the variable description to use the Global Description in the variable   
--    extended_info field.  
--  - Added code for multi-lingual capability.  
--  - Added a check for valid Prod PU Desc before attempting to get variable IDs.  
--  - Where appropriate, converted the code to use fnLocal stored procedures written by Matt Wells.  
--  
-- 2004-03-16 Jeff Jaeger  Revision 1.2  
--  - added pl_id checks to the inserts to #tests in the ProdLinesCursor.  
--  - added the ' > 65000 ' check and zero records checks to all the result sets.  
--    this includes the variables used to define the return messages, and the calls for translating them.  
  
-- 2004-MAR-19 Langdon Davis  Rev1.3  
--  - Standardized Pmkg LSP worksheet headers with corresponding Cvtg LSP headers.  
--  - Changed numeric fields in the tables formed for the results sets to numeric data  
--    types--they were all varchar and as a result, not fitting with the pivot table operations.  
  
-- 2004-MAR-22 Langdon Davis  Rev1.4  
--  - Added the user_name parameter.  
--  
-- 2004-MAY-10 Matthew Wells  Rev1.5  
--  - Fixed the join for the PR comments  
  
-- 2004-May-11  Jeff Jaeger  Rev1.6  
--  - Added an update to result sets to replace carriage returns in comment fields with an empty space.  
--  - Updated the first result set to remove an empty space from header for [Initial Slab Radius 2].  
--  - Removed unused code.  
  
-- 2004-May-13  Matthew Wells  Rev1.7  
--  - Converted temp tables to table variables  
--  - Removed cursors  
--  - Reformatted sp to make it easier to read  
--  - Removed some unused declared variables  
--  - Added grand parent variables  
--  - Fixed substrate (formerly always NULL)  
--  - Added argument and 4 result sets for Intermediates  
  
-- 2004-12-10 Jeff Jaeger Rev1.8  
--  - removed some unused code  
--  - brought this sp up to date with Checklist 110804  
  
-- 2005-JAN-21 Langdon Davis Rev1.90  
--  - Made VN changes to support/correct for change to the 3-stage geneaology  
--    model.  
--  - Corrected errors where grand parent PRID and RollLabelDesc var_id variables  
--    were using parent variable names in the look-up/assignment.  
--  - Corrected bug where Winder Product in #CvtgPRollsTemp was defined as only   
--    varchar(50).  It needs to be varchar(75) since it is the concatenation of   
--    two Proficy fields of 50 and 25.  
  
-- 2005-FEB-17 Langdon Davis Rev1.91  
--  - Split Roll GCAS and PRID VN's out into separate variables for produced rolls [Pmkg  
--    and INTR] and consumed rolls [Cvtg and INTR] because changes made with the 3-stage   
--    genealogy model no longer have these with the same name.  
--  
--2005-09-01 Jeff Jaeger  Rev1.92  
--  - Removed Good Status and Fire Status related variables, as they are not used.  
--2006-JUN-29 Namho Kim Rev2.1  
--  - Making a Code Flexible to Work with BOTH 3.x and 4.x  
  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE  PROCEDURE dbo.spLocal_RptPRRejects  
--declare  
   @StartTime   DateTime,  -- Beginning period for the data.  
  @EndTime   DateTime,  -- Ending period for the data.  
  @CvtgPLIdList   nVarChar(1000),  -- List of Prod_Lines.PL_Ids for Converting. Separated by '|'.  
  @PmkgPLIdList   nVarChar(1000),  -- List of Prod_Lines.PL_Ids for Papermaking.  Separated by '|'.  
  @IntrPLIdList   varchar(1000),  -- List of Prod_Lines.PL_Ids for Intermediates.  Separated by '|'.  
  @UserName   varchar(30)  -- User calling this report  
AS  
  
--/*  Test values:  Cape  
  
--select  
  
--Cape  
--@StartTime = '02/24/04 07:30:00',  
--@EndTime = '02/25/04 07:30:00',  
--@CvtgPLIDList = '3|5|142|143|174|155|151|146',  
--@PmkgPLIDList = '38|2'  
  
--AZ  
--@StartTime = '2004-01-21 00:00:00',   
--@EndTime = '2004-01-25 00:00:00',   
--@CvtgPLIdList = ' ',   
--@PmkgPLIdList = '3|4'  
  
--AY  
--@StartTime = '2004-10-21 00:00:00',   
--@EndTime = '2004-10-25 00:00:00',   
--@CvtgPLIdList = '32|38|40|35|64|62|48|46|45|43|60|58|81|82|78|79|68|69|74|75|76',   
--@PmkgPLIdList = '28|37|53|67|42|73',  
--@IntrPLIdList = '',  
--@UserName = 'ComXClient'  
  
--MP  
--@StartTime = '2004-01-21 00:00:00',   
--@EndTime = '2004-01-25 00:00:00',   
--@CvtgPLIdList = '68|72|73|74|75|119|136|135|145|108|158|161|159|160|152|153|156|157|164|165|173|174|175|178|179|181|182|183|184',   
--@PmkgPLIdList = '29|109|146|67|147|107|154|163|168'  
  
--NEU  
--@StartTime = '2004-01-21 00:00:00',   
--@EndTime = '2004-01-25 00:00:00',   
--@CvtgPLIdList = '2|5|12',   
--@PmkgPLIdList = '42|49|50|79|80|81'  
  
  
  
  
-----------------------------------------------------------------------------------  
--  Create temporary tables used in the Stored Procedure.  
-----------------------------------------------------------------------------------  
-- @ErrorMessages used to capture an errors from the stored procedure.  These can  
-- be then passed to the template and reported in the report.  
DECLARE @ErrorMessages TABLE (  
 ErrMsg    varchar(255) )  
  
-- @CvtgPRolls used to store Event data for converting (Parent Rolls Ran).  
DECLARE @CvtgPRolls TABLE (  
  EventId   int, -- PRIMARY KEY,  
  EventTime  datetime,  
  StatusTime  datetime,  
  Team   varchar(10),  
  Shift   varchar(10),  
  PUId   int,  
  PLId   int,  
  ProdId   int,  
  RollStatus  varchar(50),  
  RollLabelDesc  varchar(50),  
  EventNumber  varchar(50),  
  PRIMARY KEY (PUId, EventTime)  
  )  
  
-- @PmkgPRolls used to store Event data for papermaking (Parent Rolls created).  
DECLARE @PmkgPRolls TABLE (  
  EventId   int PRIMARY KEY,  
  EventTime  datetime,  
  StatusTime  datetime,  
  Team   varchar(10),  
  Shift   varchar(10),  
  PUId   int,  
  PLId   int,  
  ProdId   int,  
  RollStatus  varchar(50),  
  EventNumber  varchar(50),  
  PRComment  varchar(1000)  
  )  
  
-- Rev1.7 - @IntrPRolls used to store Event data for intermediates (Parent Rolls created).  
DECLARE @IntrPRolls TABLE (  
  EventId   int PRIMARY KEY,  
  EventTime  datetime,  
  StatusTime  datetime,  
  Team   varchar(10),  
  Shift   varchar(10),  
  PUId   int,  
  PLId   int,  
  ProdId   int,  
  RollStatus  varchar(50),  
  EventNumber  varchar(50),  
  PRComment  varchar(1000)  
  )  
  
DECLARE @IntrPRolls2 TABLE (  
  EventId   int, -- PRIMARY KEY,  
  EventTime  datetime,  
  StatusTime  datetime,  
  Team   varchar(10),  
  Shift   varchar(10),  
  PUId   int,  
  PLId   int,  
  ProdId   int,  
  RollStatus  varchar(50),  
  RollLabelDesc  varchar(50),  
  EventNumber  varchar(50),  
  PRIMARY KEY (PUId, EventTime)  
  )  
  
-- @CvtgProdLines used for cvtg production lines and associated data.  
DECLARE @CvtgProdLines TABLE (  
  Id   int IDENTITY,  -- Rev1.7  
  PLId   int PRIMARY KEY,  
  ScheduleUnit  int,  
  CVPRRejRadiusId  int,   
  CVPRRejWeightId  int,   
  CVTGTNoInitialsId int,  
  DefectAcrossRollId int,   
  DefectInRollId  int,   
  LSPTNoInitialsId int,   
  PmkgDefectCauseId int,  
  PmkgTNoInitialsId int,   
  TimePmkgNotifiedId int,  
  RollLabelDescId  int,  
  PRIDId   int,  
  InitialSlabRadius1Id int,  
  FinalSlabRadius1Id int,  
  InitialSlabRadius2Id int,  
  FinalSlabRadius2Id int,  
  InitialSlabRadius3Id int,  
  FinalSlabRadius3Id int,  
  RollSlabWeightId int,  
  SlabWeightId  int,  
  PaperDefectCauseId int,  
  RollCreationId  int,  
  GPPRIDId  int,   -- Rev1.7  
  GPRollLabelDescId int,   -- Rev1.7  
  GPRollCreationId int   -- Rev1.7  
  )  
  
-- @PmkgProdLines used for pmkg production lines and associated data.  
DECLARE @PmkgProdLines TABLE (  
  Id   int IDENTITY,  -- Rev1.7  
  PLId   int PRIMARY KEY,  
  ScheduleUnit  int,  
  LSPTNoInitialsId int,   
  PmkgTNoInitialsId int,   
  PmkgPRollRejectCauseId  int,  
  PRIDId   int,  
  RollGCASId  int,  
  TonsRejectId  int  
  )  
  
--Rev1.7 @IntrProdLines used for pmkg production lines and associated data.  
DECLARE @IntrProdLines TABLE (  
  Id   int IDENTITY,  -- Rev1.7  
  PLId   int PRIMARY KEY,  
  ScheduleUnit  int,  
  --Production variables  
  LSPTNoInitialsId int,   
  IntrTNoInitialsId int,   
  IntrPRollRejectCauseId  int,  
  PRIDId   int,  
  RollGCASId  int,  
  TonsRejectId  int,  
  --UWS variables  
  CVPRRejRadiusId  int,   
  CVPRRejWeightId  int,   
  CVTGTNoInitialsId int,  
  DefectAcrossRollId int,   
  DefectInRollId  int,   
  PLSPTNoInitialsId int,   
  PmkgDefectCauseId int,  
  PmkgTNoInitialsId int,   
  TimePmkgNotifiedId int,  
  RollLabelDescId  int,  
  PPRIDId   int,  
  InitialSlabRadius1Id int,  
  FinalSlabRadius1Id int,  
  InitialSlabRadius2Id int,  
  FinalSlabRadius2Id int,  
  InitialSlabRadius3Id int,  
  FinalSlabRadius3Id int,  
  RollSlabWeightId int,  
  SlabWeightId  int,  
  PaperDefectCauseId int,  
  RollCreationId  int,  
  GPPRIDId  int,   -- Rev1.7  
  GPRollLabelDescId int,   -- Rev1.7  
  GPRollCreationId int   -- Rev1.7  
  )  
  
-- @Tests table is used to capture test values (variables) required for the report.  
DECLARE @Tests TABLE (  
 TestId   int,  
 VarId   int,  
 PLId   int,  
 Value   varchar(25),  
 StartTime  datetime,  
 CommentId  int,  
 PRIMARY KEY (VarId, StartTime) )  
  
-------------------------------------------------------------------------------------  
-- Validate the input parameters  
-------------------------------------------------------------------------------------  
  
IF IsDate(@StartTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF IsDate(@EndTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@Report_End_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
-----------------------------------------------------------------------------------  
-- DECLARE Variables for SP.  
-----------------------------------------------------------------------------------  
DECLARE -- General  
 @SearchString   varchar(1000),  
 @Position   int,  
 @PartialString   varchar(1000),  
 @@Id    int,   
 @Row    int,   --Rev1.7  
 @NoDataMsg   varchar(50),  
 @TooMuchDataMsg   varchar(50),  
  
 -- Language variables  
 @LanguageId   int,  
 @UserId    int,  
 @LanguageParmId   int,  
 @sql    varchar(8000),  
  
 -- Statuses  
 @StatusRejectDesc  varchar(50),  
-- @StatusGoodDesc   varchar(50),  
 @StatusHoldDesc   varchar(50),  
-- @StatusFireDesc   varchar(50),  
 @StatusRejectId   int,  
--  @StatusGoodId   int,  
 @StatusHoldId   int,  
-- @StatusFireId   int,  
  
 -- Global variables  
 @nCvtgProdLines   int,   --Rev1.7  
 @nPmkgProdLines   int,   --Rev1.7  
 @nIntrProdLines   int,   --Rev1.7  
 @PmkgRollsDesc   varchar(50),  
 @CvtgProdDesc   varchar(50),  
 @CvtgPUCompareStr  varchar(100),  
 @PmkgPUCompareStr  varchar(100),  
 @PUScheduleUnitStr  varchar(100),  
 @IntrRollsDesc   varchar(50),  --Rev1.7  
 @IntrReliabilityDesc  varchar(100),  --Rev1.7  
 @IntrUWSDesc   varchar(100),  --Rev1.7  
  
 -- Common configuration variables  
 @@PUId   int,  
 @@ExtendedInfo   varchar(1000),  
 @@ScheduleUnit   int,  
  
 -- Pmkg/Cvtg/Intr Configuration variables  
 @CVPRRejRadiusVN  varchar(50),  
 @CVPRRejWeightVN  varchar(50),  
 @CVTGTNoInitialsVN  varchar(50),  
 @DefectAcrossRollVN  varchar(50),  
 @DefectInRollVN   varchar(50),  
 @LSPTNoInitialsVN  varchar(50),  
 @PmkgDefectCauseVN  varchar(50),  
 @PmkgTNoInitialsVN  varchar(50),  
 @TimePmkgNotifiedVN  varchar(50),  
 @ProducedPRIDVN   varchar(50),  
 @ConsumedPRIDVN   varchar(50),  
 @RollLabelDescVN  varchar(50),  
 @CvtgInitialSlabRadius1VN varchar(50),  
 @CvtgFinalSlabRadius1VN  varchar(50),  
 @CvtgInitialSlabRadius2VN varchar(50),  
 @CvtgFinalSlabRadius2VN  varchar(50),  
 @CvtgInitialSlabRadius3VN varchar(50),  
 @CvtgFinalSlabRadius3VN  varchar(50),  
 @CvtgRollSlabWeightVN  varchar(50),  
 @CvtgSlabWeightVN  varchar(50),  
 @CvtgPaperDefectCauseVN  varchar(50),  
 @ProducedRollGCASVN  varchar(50),  --Rev1.91  
 @ConsumedRollGCASVN  varchar(50),  --Rev1.91  
 @PmkgPRollRejectCauseVN  varchar(50),    
 @TonsRejectVN   varchar(50),  
 @RollCreationVN   varchar(50),  --Rev1.7  
 @GPPRIDVN   varchar(50),  --Rev1.7  
 @GPRollLabelDescVN  varchar(50),  --Rev1.7  
 @GPRollCreationVN  varchar(50),  --Rev1.7  
 @IntrTNoInitialsVN  varchar(50),  --Rev1.7  
 @IntrPRollRejectCauseVN  varchar(50),  --Rev1.7  
 @@CVPRRejRadiusId  int,  
 @@CVPRRejWeightId  int,  
 @@CVTGTNoInitialsId  int,  
 @@DefectAcrossRollId  int,  
 @@DefectInRollId  int,  
 @@LSPTNoInitialsId  int,  
 @@PmkgDefectCauseId  int,  
 @@PmkgTNoInitialsId  int,  
 @@TimePmkgNotifiedId  int,  
 @@PRIDId   int,  
 @@RollLabelDescId  int,  
 @@CvtgInitialSlabRadius1Id int,  
 @@CvtgFinalSlabRadius1Id int,  
 @@CvtgInitialSlabRadius2Id int,  
 @@CvtgFinalSlabRadius2Id int,  
 @@CvtgInitialSlabRadius3Id int,  
 @@CvtgFinalSlabRadius3Id int,  
 @@CvtgRollSlabWeightId  int,  
 @@CvtgSlabWeightId  int,  
 @@CvtgPaperDefectCauseId int,    
 @@RollGCASId   int,  
 @@PmkgPRollRejectCauseId int,  
 @@TonsRejectId   int,  
 @@RollCreationId  int,   --Rev1.7  
 @@GPPRIDId   int,   --Rev1.7  
 @@GPRollLabelDescId  int,   --Rev1.7  
 @@GPRollCreationId  int,   --Rev1.7  
 @@IntrTNoInitialsId  int,   --Rev1.7  
 @@IntrPRollRejectCauseId int,   --Rev1.7  
 @@PPRIDId   int,   --Rev1.7  
 @@PLSPTNoInitialsId  int,   --Rev1.7  
 @DBVersion   Varchar(10) --Namho Kim Rev2.1 Flag used to control whether to execute Proficy version specific code.  
  
-----------------------------------------------------------------------------------  
--  Set the Status and Variable Descriptions, string constants.  
-----------------------------------------------------------------------------------  
SELECT -- Statuses  
 @StatusRejectDesc  = 'Reject',  
-- @StatusGoodDesc   = 'Good',  
 @StatusHoldDesc   = 'Hold',  
-- @StatusFireDesc   = 'Fire',  
  
 -- Pmkg/Cvtg Unit Descriptions  
 @CvtgProdDesc   = '%Converter Production',  
 @CvtgPUCompareStr  = '%Converter Production%',  
 @PmkgRollsDesc   = '%Rolls',  
 @PmkgPUCompareStr  = '%Reliability%',  
 @IntrRollsDesc   = '%Rolls',  
 @IntrReliabilityDesc  = '%Reliability%',  
 @IntrUWSDesc   = '%UWS Production',  
  
 -- Pmkg/Cvtg/Intr Variables  
 @CVPRRejRadiusVN  = 'CV PRoll Reject Radius',  
 @CVPRRejWeightVN  = 'CV PRoll Reject Weight',  
 @CVTGTNoInitialsVN  = 'Cvtg T# and Initials',  
 @DefectAcrossRollVN  = 'Location of Defect Across Roll',  
 @DefectInRollVN   = 'Location of Defect in Roll',  
 @LSPTNoInitialsVN  = 'RTCIS Reject Work Complete?',  
 @PmkgDefectCauseVN  = 'Paper Defect Cause',  
 @PmkgTNoInitialsVN  = 'Pmkg T# and Initials',  
 @TimePmkgNotifiedVN  = 'Time Notified Pmkg',  
 @PmkgPRollRejectCauseVN  = 'Pmkg PRoll Reject Cause',  
 @TonsRejectVN   = 'Tons Reject',  
 @ProducedPRIDVN   = 'PRID', --Rev1.91  
 @ConsumedPRIDVN   = 'Parent PRID', --'PRID', Rev1.90  Rev1.91  
 @PUScheduleUnitStr  = 'ScheduleUnit=',  
 @RollLabelDescVN  = 'Parent Roll Label Description', --'Roll Label Description', --Rev1.90  
 @ProducedRollGCASVN   = 'Roll GCAS', --Rev1.91  
 @ConsumedRollGCASVN  = 'Parent GCAS', --'Roll GCAS', Rev1.90  
 @CvtgInitialSlabRadius1VN = 'Initial Slab Radius 1',  
 @CvtgFinalSlabRadius1VN  = 'Final Slab Radius 1',  
 @CvtgInitialSlabRadius2VN = 'Initial Slab Radius 2',  
 @CvtgFinalSlabRadius2VN  = 'Final Slab Radius 2',  
 @CvtgInitialSlabRadius3VN = 'Initial Slab Radius 3',  
 @CvtgFinalSlabRadius3VN  = 'Final Slab Radius 3',  
 @CvtgRollSlabWeightVN  = 'Roll Slab Weight',  
 @CvtgSlabWeightVN  = 'Slab Weight',  
 @CvtgPaperDefectCauseVN  = 'Paper Defect Cause',  
 @GPPRIDVN   = 'Grand Parent PRID', --'GP PRID', --Rev1.9  
 @GPRollLabelDescVN  = 'Grand Parent Roll Label Description', --'GP Roll Label Description', --Rev1.9  
 @RollCreationVN   = 'Parent Roll Creation Date/Time', --'Roll Creation Date/Time', --Rev1.9  
 @GPRollCreationVN  = 'Grand Parent Roll Creation Date/Time', --'GP Roll Creation Date/Time', --Rev1.9  
 @IntrTNoInitialsVN  = 'T# and Initials',  --Rev1.7  
 @IntrPRollRejectCauseVN  = 'PRoll Reject Cause',  --Rev1.7  
 @DBVersion   = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database') --Rev2.1  
-----------------------------------------------------------------------------------  
--  Initialization  
-----------------------------------------------------------------------------------  
SELECT @nCvtgProdLines  = 0,     -- Rev1.7  
 @nPmkgProdLines  = 0     -- Rev1.7  
  
-----------------------------------------------------------------------------------  
--  Get the ProdStatus_Id for production statuses used in this report.  
-----------------------------------------------------------------------------------  
SELECT @StatusRejectId  = (SELECT ProdStatus_Id FROM Production_Status WHERE ProdStatus_Desc = @StatusRejectDesc),  
-- @StatusGoodId   = (SELECT ProdStatus_Id FROM Production_Status WHERE ProdStatus_Desc = @StatusGoodDesc),  
 @StatusHoldId   = (SELECT ProdStatus_Id FROM Production_Status WHERE ProdStatus_Desc = @StatusHoldDesc)  
-- @StatusFireId   = (SELECT ProdStatus_Id FROM Production_Status WHERE ProdStatus_Desc = @StatusFireDesc)  
  
-------------------------------------------------------------------------------  
-- Get local language  
-------------------------------------------------------------------------------  
SELECT @LanguageParmId  = 8,  
 @LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
   
-- Translate messages  
SELECT @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId),  
 @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
-----------------------------------------------------------------------------------  
--  Parse the Converting Line (@CvtgPLIdList) report parameter and load    
-- the Ids into the temporary table @CvtgProdLines.  
-----------------------------------------------------------------------------------  
SELECT @SearchString = ltrim(rtrim(coalesce(@CvtgPLIdList,'')))  
WHILE len(@SearchString) > 0  
 BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = rtrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = rtrim(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = ltrim(rtrim(substring(@SearchString, (@Position + 1), len(@SearchString))))  
 IF len(@PartialString) > 0  
  BEGIN  
  IF IsNumeric(@PartialString) <> 1  
   BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
   VALUES ('Parameter @CvtgPLIdList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
   END  
  IF (SELECT Count(PLId) FROM @CvtgProdLines WHERE PLId = Convert(int, @PartialString)) = 0  
   BEGIN  
  
   -- Set variables to NULL, this prevents the Id being set to previous value if not found.  
   SELECT  @@PUId    = NULL,  
    @@ExtendedInfo   = NULL,  
    @@ScheduleUnit   = NULL,  
    @@CVPRRejRadiusId  = NULL,  
    @@CVPRRejWeightId  = NULL,  
    @@CVTGTNoInitialsId  = NULL,  
    @@DefectAcrossRollId  = NULL,  
    @@DefectInRollId  = NULL,  
    @@LSPTNoInitialsId  = NULL,  
    @@PmkgDefectCauseId  = NULL,  
    @@PmkgTNoInitialsId  = NULL,  
    @@TimePmkgNotifiedId  = NULL,  
    @@PRIDId   = NULL,  
    @@RollLabelDescId  = NULL,  
    @@CvtgInitialSlabRadius1Id = NULL,   
    @@CvtgFinalSlabRadius1Id = NULL,  
    @@CvtgInitialSlabRadius2Id = NULL,  
    @@CvtgFinalSlabRadius2Id = NULL,  
    @@CvtgInitialSlabRadius3Id = NULL,  
    @@CvtgFinalSlabRadius3Id = NULL,  
    @@CvtgRollSlabWeightId  = NULL,  
    @@CvtgSlabWeightId  = NULL,  
    @@CvtgPaperDefectCauseId = NULL,  
    @@RollCreationId  = NULL,  
    @@GPPRIDId    = NULL,   -- Rev1.7  
    @@GPRollLabelDescId   = NULL,   -- Rev1.7  
    @@GPRollCreationId  = NULL   -- Rev1.7  
  
   SELECT @@PUId = PU_Id  
   FROM Prod_Units  
   WHERE PL_Id = convert(int,@PartialString) ----@@PLId  
    AND PU_Desc LIKE @CvtgProdDesc --'%Converter Production'  
  
   if @@PUId is not NULL  
    BEGIN  
    SELECT @@CVPRRejRadiusId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVPRRejRadiusVN)  
    SELECT @@CVPRRejWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVPRRejWeightVN)  
    SELECT @@CVTGTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVTGTNoInitialsVN)  
    SELECT @@DefectAcrossRollId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @DefectAcrossRollVN)  
    SELECT @@DefectInRollId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @DefectInRollVN)  
    SELECT @@LSPTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @LSPTNoInitialsVN)  
    SELECT @@PmkgDefectCauseId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgDefectCauseVN)  
    SELECT @@PmkgTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgTNoInitialsVN)  
    SELECT @@TimePmkgNotifiedId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @TimePmkgNotifiedVN)  
    SELECT @@PRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ConsumedPRIDVN)  --Rev1.91  
    SELECT @@RollLabelDescId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @RollLabelDescVN)  
    SELECT @@CvtgInitialSlabRadius1Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius1VN)  
    SELECT @@CvtgFinalSlabRadius1Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius1VN)  
    SELECT @@CvtgInitialSlabRadius2Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius2VN)  
    SELECT @@CvtgFinalSlabRadius2Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius2VN)  
    SELECT @@CvtgInitialSlabRadius3Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius3VN)  
    SELECT @@CvtgFinalSlabRadius3Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius3VN)  
    SELECT @@CvtgRollSlabWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgRollSlabWeightVN)  
    SELECT @@CvtgSlabWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgSlabWeightVN)  
    SELECT @@CvtgPaperDefectCauseId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgPaperDefectCauseVN)  
    SELECT @@RollCreationId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @RollCreationVN)  
    SELECT @@GPPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPPRIDVN) --@PRIDVN) -- Rev1.9  
    SELECT @@GPRollLabelDescId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPRollLabelDescVN) --@RollLabelDescVN)     -- Rev1.9  
    SELECT @@GPRollCreationId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPRollCreationVN)    -- Rev1.7  
    end  
      
   SELECT @@ExtendedInfo = pu.Extended_Info  
   FROM Prod_Units pu  
    JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   WHERE pu.PL_Id = Convert(int, @PartialString)  
    AND pu.PU_Desc LIKE @CvtgPUCompareStr  
  
   select @@ScheduleUnit = GBDB.dbo.fnLocal_GlblParseInfo(@@ExtendedInfo, @PUScheduleUnitStr)  
  
  
   INSERT @CvtgProdLines (PLId,  
      ScheduleUnit,  
      CVPRRejRadiusId,  
      CVPRRejWeightId,  
      CVTGTNoInitialsId,  
      DefectAcrossRollId,  
      DefectInRollId,  
      LSPTNoInitialsId,  
      PmkgDefectCauseId,  
      PmkgTNoInitialsId,  
      TimePmkgNotifiedId,  
      PRIDId,  
      RollLabelDescId,   
      InitialSlabRadius1ID,  
      FinalSlabRadius1ID,  
      InitialSlabRadius2ID,   
      FinalSlabRadius2ID,  
      InitialSlabRadius3ID,  
      FinalSlabRadius3ID,  
      RollSlabWeightID,   
      SlabWeightID,  
      PaperDefectCauseID,  
      RollCreationId,  
      GPPRIDId,    -- Rev1.7  
      GPRollLabelDescId,   -- Rev1.7  
      GPRollCreationId)    -- Rev1.7  
   VALUES (convert(int, @PartialString),  
    @@ScheduleUnit,  
    @@CVPRRejRadiusId,  
    @@CVPRRejWeightId,  
    @@CVTGTNoInitialsId,  
    @@DefectAcrossRollId,  
    @@DefectInRollId,  
    @@LSPTNoInitialsId,  
    @@PmkgDefectCauseId,  
    @@PmkgTNoInitialsId,  
    @@TimePmkgNotifiedId,  
    @@PRIDId,  
    @@RollLabelDescId,  
    @@CvtgInitialSlabRadius1ID,  
    @@CvtgFinalSlabRadius1ID,  
    @@CvtgInitialSlabRadius2ID,   
    @@CvtgFinalSlabRadius2ID,  
    @@CvtgInitialSlabRadius3ID,  
    @@CvtgFinalSlabRadius3ID,   
    @@CvtgRollSlabWeightID,  
    @@CvtgSlabWeightID,  
    @@CvtgPaperDefectCauseID,  
    @@RollCreationId,  
    @@GPPRIDId,    -- Rev1.7  
    @@GPRollLabelDescId,   -- Rev1.7  
    @@GPRollCreationId)   -- Rev1.7  
  
   SELECT @nCvtgProdLines = @nCvtgProdLines + @@ROWCOUNT  -- Rev1.7  
   END  
  END  
 END  
  
-----------------------------------------------------------------------------------  
--  Parse the Papermaking Line (@PmkgPLIdList) report parameter and load    
-- the Ids into the temporary table @PmkgProdLines.  
-----------------------------------------------------------------------------------  
SELECT @SearchString = ltrim(rtrim(coalesce(@PmkgPLIdList,'')))  
WHILE len(@SearchString) > 0  
 BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = rtrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = rtrim(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = ltrim(rtrim(substring(@SearchString, (@Position + 1), len(@SearchString))))  
 IF len(@PartialString) > 0  
  BEGIN  
  IF IsNumeric(@PartialString) <> 1  
   BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
   VALUES ('Parameter @PmkgPLIdList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
   END  
  IF (SELECT Count(PLId) FROM @PmkgProdLines WHERE PLId = Convert(int, @PartialString)) = 0  
   BEGIN  
  
   -- Set variables to NULL, this prevents the Id being set to previous value if not found.  
   SELECT  @@PUId   = NULL,  
    @@ExtendedInfo   = NULL,  
    @@ScheduleUnit   = NULL,  
    @@PRIDId    = NULL,  
    @@LSPTNoInitialsId  = NULL,  
    @@PmkgTNoInitialsId  = NULL,  
    @@PmkgPRollRejectCauseId  = NULL,  
    @@RollGCASId   = NULL,  
    @@TonsRejectId   = NULL  
  
   SELECT @@PUId = PU_Id  
   FROM Prod_Units  
   WHERE PL_Id = Convert(int,@PartialString) --@@PLId  
    AND PU_Desc LIKE @PmkgRollsDesc   
  
   IF @@PUId IS NOT NULL   
    BEGIN  
    SELECT @@LSPTNoInitialsId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @LSPTNoInitialsVN)  
    SELECT @@PmkgTNoInitialsId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgTNoInitialsVN)  
    SELECT @@PmkgPRollRejectCauseId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgPRollRejectCauseVN)  
    SELECT @@PRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ProducedPRIDVN)  --Rev1.91  
    SELECT @@RollGCASId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ProducedRollGCASVN) --Rev1.91  
    SELECT @@TonsRejectId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @TonsRejectVN)  
    end  
  
   SELECT @@ExtendedInfo = pu.Extended_Info  
   FROM Prod_Units pu  
    JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   WHERE  pu.PL_Id = Convert(int, @PartialString)  
    AND pu.PU_Desc LIKE @PmkgPUCompareStr  
  
   select @@ScheduleUnit = GBDB.dbo.fnLocal_GlblParseInfo(@@ExtendedInfo, @PUScheduleUnitStr)  
  
   INSERT @PmkgProdLines (PLId,  
      ScheduleUnit,  
      LSPTNoInitialsId,   
      PmkgTNoInitialsId,  
      PmkgPRollRejectCauseId,  
      PRIDId,   
      RollGCASId,  
      TonsRejectId)   
   VALUES (convert(int, @PartialString),  
    @@ScheduleUnit,  
    @@LSPTNoInitialsId,   
    @@PmkgTNoInitialsId,  
    @@PmkgPRollRejectCauseId,  
    @@PRIDId,   
    @@RollGCASId,  
    @@TonsRejectId)  
  
   SELECT @nPmkgProdLines = @nPmkgProdLines + @@ROWCOUNT  -- Rev1.7  
   END  
  END  
 END  
  
-----------------------------------------------------------------------------------  
--Rev1.7  
--  Parse the Intermediate Line (@IntrPLIdList) report parameter and load    
-- the Ids into the temporary table @IntrProdLines.  
-----------------------------------------------------------------------------------  
SELECT @SearchString = ltrim(rtrim(coalesce(@IntrPLIdList,'')))  
WHILE len(@SearchString) > 0  
 BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = rtrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = rtrim(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = ltrim(rtrim(substring(@SearchString, (@Position + 1), len(@SearchString))))  
 IF len(@PartialString) > 0  
  BEGIN  
  IF IsNumeric(@PartialString) <> 1  
   BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
   VALUES ('Parameter @IntrPLIdList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
   END  
  IF (SELECT Count(PLId) FROM @IntrProdLines WHERE PLId = Convert(int, @PartialString)) = 0  
   BEGIN  
  
   -- Set variables to NULL, this prevents the Id being set to previous value if not found.  
   SELECT  @@PUId    = NULL,  
    @@ExtendedInfo   = NULL,  
    @@ScheduleUnit   = NULL,  
    --Production variables  
    @@PRIDId    = NULL,  
    @@LSPTNoInitialsId  = NULL,  
    @@IntrTNoInitialsId  = NULL,  
    @@IntrPRollRejectCauseId  = NULL,  
    @@RollGCASId   = NULL,  
    @@TonsRejectId   = NULL,  
    --UWS variables  
    @@CVPRRejRadiusId  = NULL,  
    @@CVPRRejWeightId  = NULL,  
    @@CVTGTNoInitialsId  = NULL,  
    @@DefectAcrossRollId  = NULL,  
    @@DefectInRollId  = NULL,  
    @@LSPTNoInitialsId  = NULL,  
    @@PmkgDefectCauseId  = NULL,  
    @@PmkgTNoInitialsId  = NULL,  
    @@TimePmkgNotifiedId  = NULL,  
    @@PPRIDId   = NULL,  
    @@RollLabelDescId  = NULL,  
    @@CvtgInitialSlabRadius1Id = NULL,    
    @@CvtgFinalSlabRadius1Id = NULL,  
    @@CvtgInitialSlabRadius2Id = NULL,  
    @@CvtgFinalSlabRadius2Id = NULL,  
    @@CvtgInitialSlabRadius3Id = NULL,  
    @@CvtgFinalSlabRadius3Id = NULL,  
    @@CvtgRollSlabWeightId  = NULL,  
    @@CvtgSlabWeightId  = NULL,  
    @@CvtgPaperDefectCauseId = NULL,  
    @@RollCreationId  = NULL,  
    @@GPPRIDId    = NULL,   -- Rev1.7  
    @@GPRollLabelDescId   = NULL,   -- Rev1.7  
    @@GPRollCreationId  = NULL,   -- Rev1.7  
    @@PLSPTNoInitialsId  = NULL   -- Rev1.7  
  
   SELECT @@PUId = PU_Id  
   FROM Prod_Units  
   WHERE PL_Id = Convert(int,@PartialString) --@@PLId  
    AND PU_Desc LIKE @IntrRollsDesc   
  
   IF @@PUId IS NOT NULL   
    BEGIN  
    SELECT @@LSPTNoInitialsId = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @LSPTNoInitialsVN)  
    SELECT @@IntrTNoInitialsId = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @IntrTNoInitialsVN)  
    SELECT @@IntrPRollRejectCauseId = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @IntrPRollRejectCauseVN)  
    SELECT @@PRIDId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ProducedPRIDVN) --Rev1.91  
    SELECT @@RollGCASId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ProducedRollGCASVN) --Rev1.91  
    SELECT @@TonsRejectId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @TonsRejectVN)  
    END  
  
   SELECT @@PUId = NULL  
   SELECT @@PUId = PU_Id  
   FROM Prod_Units  
   WHERE PL_Id = Convert(int,@PartialString) --@@PLId  
    AND PU_Desc LIKE @IntrUWSDesc   
  
   IF @@PUId IS NOT NULL   
    BEGIN  
    SELECT @@CVPRRejRadiusId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVPRRejRadiusVN)  
    SELECT @@CVPRRejWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVPRRejWeightVN)  
    SELECT @@CVTGTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CVTGTNoInitialsVN)  
    SELECT @@DefectAcrossRollId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @DefectAcrossRollVN)  
    SELECT @@DefectInRollId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @DefectInRollVN)  
    SELECT @@PLSPTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @LSPTNoInitialsVN)  
    SELECT @@PmkgDefectCauseId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgDefectCauseVN)  
    SELECT @@PmkgTNoInitialsId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @PmkgTNoInitialsVN)  
    SELECT @@TimePmkgNotifiedId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @TimePmkgNotifiedVN)  
    SELECT @@PPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @ConsumedPRIDVN) --Rev1.91  
    SELECT @@RollLabelDescId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @RollLabelDescVN)  
    SELECT @@CvtgInitialSlabRadius1Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius1VN)  
    SELECT @@CvtgFinalSlabRadius1Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius1VN)  
    SELECT @@CvtgInitialSlabRadius2Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius2VN)  
    SELECT @@CvtgFinalSlabRadius2Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius2VN)  
    SELECT @@CvtgInitialSlabRadius3Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgInitialSlabRadius3VN)  
    SELECT @@CvtgFinalSlabRadius3Id  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgFinalSlabRadius3VN)  
    SELECT @@CvtgRollSlabWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgRollSlabWeightVN)  
    SELECT @@CvtgSlabWeightId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgSlabWeightVN)  
    SELECT @@CvtgPaperDefectCauseId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @CvtgPaperDefectCauseVN)  
    SELECT @@RollCreationId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @RollCreationVN)  
    SELECT @@GPPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPPRIDVN) --@PRIDVN) -- Rev1.9  
    SELECT @@GPRollLabelDescId   = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPRollLabelDescVN) --@RollLabelDescVN) -- Rev1.9  
    SELECT @@GPRollCreationId  = GBDB.dbo.fnLocal_GlblGetVarId(@@PUId, @GPRollCreationVN) -- Rev1.7  
    END  
  
   SELECT @@ExtendedInfo = pu.Extended_Info  
   FROM Prod_Units pu  
    JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   WHERE  pu.PL_Id = Convert(int, @PartialString)  
    AND pu.PU_Desc LIKE @IntrReliabilityDesc  
  
   SELECT @@ScheduleUnit = GBDB.dbo.fnLocal_GlblParseInfo(@@ExtendedInfo, @PUScheduleUnitStr)  
  
   INSERT @IntrProdLines (PLId,  
      ScheduleUnit,  
      --Production variables  
      LSPTNoInitialsId,   
      IntrTNoInitialsId,  
      IntrPRollRejectCauseId,  
      PRIDId,   
      RollGCASId,  
      TonsRejectId,  
      --UWS variables  
      CVPRRejRadiusId,  
      CVPRRejWeightId,  
      CVTGTNoInitialsId,  
      DefectAcrossRollId,  
      DefectInRollId,  
      PLSPTNoInitialsId,  
      PmkgDefectCauseId,  
      PmkgTNoInitialsId,  
      TimePmkgNotifiedId,  
      PPRIDId,  
      RollLabelDescId,   
      InitialSlabRadius1ID,  
      FinalSlabRadius1ID,  
      InitialSlabRadius2ID,   
      FinalSlabRadius2ID,  
      InitialSlabRadius3ID,  
      FinalSlabRadius3ID,  
      RollSlabWeightID,   
      SlabWeightID,  
      PaperDefectCauseID,  
      RollCreationId,  
      GPPRIDId,    -- Rev1.7  
      GPRollLabelDescId,   -- Rev1.7  
      GPRollCreationId)    -- Rev1.7  
   VALUES (convert(int, @PartialString),  
    @@ScheduleUnit,  
    --Production variables  
    @@LSPTNoInitialsId,   
    @@IntrTNoInitialsId,  
    @@IntrPRollRejectCauseId,  
    @@PRIDId,   
    @@RollGCASId,  
    @@TonsRejectId,  
    --UWS variables  
    @@CVPRRejRadiusId,  
    @@CVPRRejWeightId,  
    @@CVTGTNoInitialsId,  
    @@DefectAcrossRollId,  
    @@DefectInRollId,  
    @@PLSPTNoInitialsId,  
    @@PmkgDefectCauseId,  
    @@PmkgTNoInitialsId,  
    @@TimePmkgNotifiedId,  
    @@PPRIDId,  
    @@RollLabelDescId,  
    @@CvtgInitialSlabRadius1ID,  
    @@CvtgFinalSlabRadius1ID,  
    @@CvtgInitialSlabRadius2ID,   
    @@CvtgFinalSlabRadius2ID,  
    @@CvtgInitialSlabRadius3ID,  
    @@CvtgFinalSlabRadius3ID,   
    @@CvtgRollSlabWeightID,  
    @@CvtgSlabWeightID,  
    @@CvtgPaperDefectCauseID,  
    @@RollCreationId,  
    @@GPPRIDId,    -- Rev1.7  
    @@GPRollLabelDescId,   -- Rev1.7  
    @@GPRollCreationId)   -- Rev1.7  
  
   SELECT @nIntrProdLines = @nIntrProdLines + @@ROWCOUNT  -- Rev1.7  
   END  
  END  
 END  
  
-------------------------------------------------------------------------------  
-- Insert the Converting Events data into the temporary table @CvtgPRolls.  
-------------------------------------------------------------------------------  
  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev2.1  
 BEGIN  
  INSERT @CvtgPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   ps.ProdStatus_Desc,  
   e.Event_Num  
  FROM Events e  
   LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @CvtgProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Status ps ON e.Event_Status = ps.ProdStatus_Id  
   LEFT JOIN Production_Starts prs ON  e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
  WHERE PU_Desc LIKE @CvtgPUCompareStr  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
  ORDER BY e.TimeStamp  
 End  
else  
 Begin  
  INSERT @CvtgPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   ps.ProdStatus_Desc,  
   e.Event_Num  
  FROM Events e  
   -- Removed P4 --  
   --LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   ----------------  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @CvtgProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Status ps ON e.Event_Status = ps.ProdStatus_Id  
   LEFT JOIN Production_Starts prs ON  e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
  WHERE PU_Desc LIKE @CvtgPUCompareStr  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
  ORDER BY e.TimeStamp  
 End  
-------------------------------------------------------------------------------  
-- Insert the Papermaking Events data into the temporary table @PmkgPRolls.  
-------------------------------------------------------------------------------  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev2.1  
 BEGIN  
  INSERT @PmkgPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber,  
     PRComment)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   CASE e.Event_Status  
    WHEN @StatusRejectId THEN @StatusRejectDesc  
    WHEN @StatusHoldId THEN @StatusHoldDesc  
    ELSE NULL  
    END,  
   Event_Num,  
   rtrim(ltrim(convert(varchar(1000),c.Comment_Text)))    -- Rev1.5  
  FROM Events e  
   LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @PmkgProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
   LEFT JOIN Comments c ON e.Comment_Id = c.Comment_Id    -- Rev1.5  
  WHERE  PU_Desc Like @PmkgRollsDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND ( e.Event_Status = @StatusRejectId  
    OR e.Event_Status = @StatusHoldId)     -- Rev1.7  
  ORDER BY e.TimeStamp  
 End  
Else  
 Begin  
  INSERT @PmkgPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber,  
     PRComment)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   CASE e.Event_Status  
    WHEN @StatusRejectId THEN @StatusRejectDesc  
    WHEN @StatusHoldId THEN @StatusHoldDesc  
    ELSE NULL  
    END,  
   Event_Num,  
   rtrim(ltrim(convert(varchar(1000),c.Comment_Text)))    -- Rev1.5  
  FROM Events e  
   -- Removed P4 --  
   --LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   ----------------  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @PmkgProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
   LEFT JOIN Comments c ON e.Comment_Id = c.Comment_Id    -- Rev1.5  
  WHERE  PU_Desc Like @PmkgRollsDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND ( e.Event_Status = @StatusRejectId  
    OR e.Event_Status = @StatusHoldId)     -- Rev1.7  
  ORDER BY e.TimeStamp  
 End  
-------------------------------------------------------------------------------  
-- Rev1.7  
-- Insert the Intermediate events data into the temporary table @IntrPRolls.  
-------------------------------------------------------------------------------  
-- Produced rolls  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev2.1  
 BEGIN  
  INSERT @IntrPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber,  
     PRComment)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   CASE e.Event_Status  
    WHEN @StatusRejectId THEN @StatusRejectDesc  
    WHEN @StatusHoldId THEN @StatusHoldDesc  
    ELSE NULL  
    END,  
   Event_Num,  
   rtrim(ltrim(convert(varchar(1000),c.Comment_Text)))    -- Rev1.5  
  FROM Events e  
   LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @IntrProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
   LEFT JOIN Comments c ON e.Comment_Id = c.Comment_Id    -- Rev1.5  
  WHERE  PU_Desc Like @IntrRollsDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND ( e.Event_Status = @StatusRejectId  
    OR e.Event_Status = @StatusHoldId)     -- Rev1.7  
  ORDER BY e.TimeStamp  
    
  --Received Rolls  
  INSERT @IntrPRolls2( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
  -- ps.ProdStatus_Desc,        --Rev1.7  
   @StatusRejectDesc,  
   e.Event_Num  
  FROM Events e  
   LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @IntrProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON  e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
  WHERE PU_Desc LIKE @IntrUWSDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND e.Event_Status = @StatusRejectId  
  ORDER BY e.TimeStamp  
  
 End  
Else  
 Begin  
  INSERT @IntrPRolls( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber,  
     PRComment)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
   CASE e.Event_Status  
    WHEN @StatusRejectId THEN @StatusRejectDesc  
    WHEN @StatusHoldId THEN @StatusHoldDesc  
    ELSE NULL  
    END,  
   Event_Num,  
   rtrim(ltrim(convert(varchar(1000),c.Comment_Text)))    -- Rev1.5  
  FROM Events e  
   -- Removed P4 --  
   --LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   ----------------  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @IntrProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
   LEFT JOIN Comments c ON e.Comment_Id = c.Comment_Id    -- Rev1.5  
  WHERE  PU_Desc Like @IntrRollsDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND ( e.Event_Status = @StatusRejectId  
    OR e.Event_Status = @StatusHoldId)     -- Rev1.7  
  ORDER BY e.TimeStamp  
    
  --Received Rolls  
  INSERT @IntrPRolls2( EventId,  
     EventTime,  
     StatusTime,  
     PUId,  
     PLId,  
     ProdId,  
     Team,  
     Shift,  
     RollStatus,   
     EventNumber)  
  SELECT e.Event_Id,  
   e.TimeStamp,  
   e.Entry_On,  
   e.PU_Id,  
   pu.PL_Id,  
   prs.Prod_Id,  
   cs.Crew_Desc,  
   cs.Shift_Desc,  
  -- ps.ProdStatus_Desc,        --Rev1.7  
   @StatusRejectDesc,  
   e.Event_Num  
  FROM Events e  
   -- Removed P4 --  
   --LEFT JOIN Event_Details ed ON e.Event_Id = ed.Event_Id  
   ----------------  
   LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
        JOIN @IntrProdLines ppl ON pu.PL_Id = ppl.PLId  
   LEFT JOIN Production_Starts prs ON  e.PU_Id = prs.PU_Id  
        AND e.Entry_On >= prs.Start_Time  
        AND ( e.Entry_On < prs.End_Time  
         OR prs.End_Time IS NULL)  
   LEFT JOIN Crew_Schedule cs ON ppl.ScheduleUnit = cs.PU_Id  
       AND e.Entry_On >= cs.Start_Time  
       AND e.Entry_On < cs.End_Time  
  WHERE PU_Desc LIKE @IntrUWSDesc  
   AND ( e.TimeStamp >= @StartTime  
    AND e.TimeStamp < @EndTime)   
   AND e.Event_Status = @StatusRejectId  
  ORDER BY e.TimeStamp  
 End  
-------------------------------------------------------------------------------  
-- Collect all the Test records for Pmkg/Cvtg/Intr variables.  
-------------------------------------------------------------------------------  
-- Converting  
INSERT @Tests ( TestId,  
  VarId,  
  PLId,  
  Value,  
  StartTime,  
  CommentId)  
SELECT t.Test_Id,  
 t.Var_Id,  
 cpl.PLId,  
 t.Result,  
 t.Result_On,  
 t.Comment_Id  
FROM @CvtgProdLines cpl  
 INNER JOIN tests t ON t.Var_Id IN ( CVPRRejRadiusId,  
      CVPRRejWeightId,  
      CVTGTNoInitialsId,  
      DefectAcrossRollId,  
      DefectInRollId,  
      LSPTNoInitialsId,   
      PmkgDefectCauseId,  
      PmkgTNoInitialsId,  
      TimePmkgNotifiedId,  
      PRIDId,  
      RollLabelDescId,  
      InitialSlabRadius1ID,  
      FinalSlabRadius1ID,  
      InitialSlabRadius2ID,   
      FinalSlabRadius2ID,  
      InitialSlabRadius3ID,   
      FinalSlabRadius3ID,  
      RollSlabWeightID,  
      SlabWeightID,   
      PaperDefectCauseID,  
      RollCreationId,  
      GPPRIDId,    -- Rev1.7  
      GPRollLabelDescId,   -- Rev1.7  
      GPRollCreationId)   -- Rev1.7  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
  
-- Papermaking  
INSERT @Tests ( TestId,  
  VarId,  
  PLId,  
  Value,  
  StartTime,  
  CommentId)  
SELECT t.Test_Id,  
 t.Var_Id,  
 cpl.PLId,  
 t.Result,  
 t.Result_On,  
 t.Comment_Id  
FROM @PmkgProdLines cpl  
 INNER JOIN tests t ON t.Var_Id IN ( LSPTNoInitialsId,  
      PmkgTNoInitialsId,   
      PmkgPRollRejectCauseId,  
      PRIDId,  
      RollGCASId,  
      TonsRejectId)  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
  
-- Intermediates  
INSERT @Tests ( TestId,  
  VarId,  
  PLId,  
  Value,  
  StartTime,  
  CommentId)  
SELECT t.Test_Id,  
 t.Var_Id,  
 cpl.PLId,  
 t.Result,  
 t.Result_On,  
 t.Comment_Id  
FROM @IntrProdLines cpl  
 INNER JOIN tests t ON t.Var_Id IN ( --Production variables  
      LSPTNoInitialsId,  
      IntrTNoInitialsId,  
      IntrPRollRejectCauseId,  
      PRIDId,  
      RollGCASId,  
      TonsRejectId,  
      --UWS variables  
      CVPRRejRadiusId,  
      CVPRRejWeightId,  
      CVTGTNoInitialsId,  
      DefectAcrossRollId,  
      DefectInRollId,  
      LSPTNoInitialsId,  
      PmkgDefectCauseId,  
      PmkgTNoInitialsId,  
      TimePmkgNotifiedId,  
      PPRIDId,  
      RollLabelDescId,  
      InitialSlabRadius1ID,  
      FinalSlabRadius1ID,  
      InitialSlabRadius2ID,  
      FinalSlabRadius2ID,  
      InitialSlabRadius3ID,  
      FinalSlabRadius3ID,  
      RollSlabWeightID,  
      SlabWeightID,  
      PaperDefectCauseID,  
      RollCreationId,  
      GPPRIDId,    -- Rev1.7  
      GPRollLabelDescId,   -- Rev1.7  
      GPRollCreationId)   -- Rev1.7  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
  
-------------------------------------------------------------------------------------  
ReturnResultSets:  
------------------------------------------------------------------------------------  
  
  
IF (SELECT count(*) FROM @ErrorMessages) > 0   
 BEGIN  
 SELECT * FROM @ErrorMessages  
 END  
ELSE  
 BEGIN  
 SELECT * FROM @ErrorMessages  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Cvtg Reject Pivot table.  
 -------------------------------------------------------------------------------  
 CREATE TABLE #CvtgPRollsTemp(  
  [Event Date]   varchar(25),  
  [Event Time]   varchar(25),  
  [Status Date]   varchar(25),  
  [Status Time]   varchar(25),  
  [Cvtg Team]   varchar(10),  
  [Cvtg Shift]   varchar(10),  
  [Cvtg Roll Status]  varchar(100),  
  [PRID]    varchar(100),  
  [Weight]   float,  
  [Producing Machine]  varchar(50),  
  [Paper Made Date]  varchar(25),  
  [Paper Made Team]  varchar(10),  
  [Turnover Number]  varchar(100),  
  [Turnover Position]  varchar(100),  
  [Substrate]   varchar(50),  
  [Winder Product]  varchar(75), --(50), Rev1.90  
  [Cvtg Line]   varchar(50),  
  [Paper Defect Cause]  varchar(100),  
  [Cvtg T# and Initials]  varchar(100),  
  [Cvtg Comment]   varchar(1000),  
  [Pmkg T# and Initials]  varchar(100),  
  [Pmkg Comment]   varchar(1000),  
  [RTCIS Reject Work Complete?] varchar(100),  
  [LSP Comment]   varchar(1000),  
  [Time Pmkg Notified]  varchar(100),  
  [Loc of Defect In Roll]  varchar(100),  
  [Loc of Defect Across Roll] varchar(100),  
  [PRoll ULID]   varchar(50),  
  [Rejected]   int,  
  [Total PR Run]   int,  
  [Initial Slab Radius 1]  float,  
  [Final Slab Radius 1]  float,  
  [Initial Slab Radius 2]  float,  
  [Final Slab Radius 2]  float,  
  [Initial Slab Radius 3]  float,  
  [Final Slab Radius 3]  float,  
  [Roll Slab Weight]  float  
  )  
  
 INSERT #CvtgPRollsTemp  
 SELECT Convert(varchar(25), EventTime, 101)[Event Date],  
  Convert(varchar(25), EventTime, 108)[Event Time],  
  Convert(varchar(25), StatusTime, 101)[Status Date],  
  Convert(varchar(25), StatusTime, 108)[Status Time],  
  Team [Cvtg Team],  
  Shift [Cvtg Shift],  
  RollStatus [Cvtg Roll Status],  
  coalesce( (SELECT Value  
    FROM @Tests  
    WHERE GPPRIDId = VarId  
     AND EventTime = StartTime),  
    (SELECT Value  
    FROM @Tests  
    WHERE PRIDId = VarId  
     AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (CVPRRejWeightId = VarId AND EventTime = StartTime)) [Weight],  
  pmkgpl.PL_Desc [Paper Machine],  
  convert(varchar(25), coalesce( gpe.TimeStamp, pe.TimeStamp), 101) [Paper Made Date],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PRIDId = VarId  
         AND EventTime = StartTime)))),3,1)  
   ELSE NULL  
   END)        [Paper Made Team],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PRIDId = VarId  
         AND EventTime = StartTime)))),4,3)  
   ELSE NULL  
   END)        [Turnover Number],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PRIDId = VarId  
         AND EventTime = StartTime)))),7,1)  
   ELSE NULL  
   END)         [Turnover Position],  
--Rev1.7  
  CASE WHEN charindex('(',coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPRollLabelDescId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE RollLabelDescId = VarId  
         AND EventTime = StartTime))) > 2  
   THEN left( coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPRollLabelDescId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE RollLabelDescId = VarId  
        AND EventTime = StartTime)),  
     charindex('(',coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPRollLabelDescId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE RollLabelDescId = VarId  
         AND EventTime = StartTime))) - 1)  
   ELSE NULL  
    END [Substrate],  
  p.Prod_Desc + '(' + p.Prod_Code + ')' [Winder Product],  
  pl.PL_Desc [Cvtg Line],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgDefectCauseId = VarId AND EventTime = StartTime)) [Paper Defect Cause],  
  (SELECT Top 1 Value FROM @Tests WHERE (CvtgTNoInitialsId = VarId AND EventTime = StartTime)) [Cvtg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)  
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (CvtgTNoInitialsId = VarId AND EventTime = StartTime)) [Cvtg Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (TimePmkgNotifiedId = VarId AND EventTime = StartTime)) [Time Pmkg Notified],  
  (SELECT Top 1 Value FROM @Tests WHERE (DefectInRollId = VarId AND EventTime = StartTime)) [Loc of Defect In Roll],  
  (SELECT Top 1 Value FROM @Tests WHERE (DefectAcrossRollId = VarId AND EventTime = StartTime)) [Loc of Defect Across Roll],  
  EventNumber [PRoll ULID],  
  (CASE WHEN RollStatus = @StatusRejectDesc THEN 1 ELSE 0 END) [Rejected],  
  1 [Total PR Run],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius1ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 1],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius1ID = VarId AND EventTime = StartTime)) [Final Slab Radius 1],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius2ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 2],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius2ID = VarId AND EventTime = StartTime)) [Final Slab Radius 2],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius3ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 3],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius3ID = VarId AND EventTime = StartTime)) [Final Slab Radius 3],  
  (SELECT Top 1 Value FROM @Tests WHERE (RollSlabWeightID = VarId AND EventTime = StartTime)) [Roll Slab Weight]  
 FROM @CvtgPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @CvtgProdLines ppl ON rj.PLId = ppl.PLId  
  LEFT JOIN Event_Components ec ON rj.EventId = ec.Event_Id  
  LEFT JOIN Events pe ON ec.Source_Event_Id = pe.Event_Id  
  LEFT JOIN Prod_Units pu ON pe.PU_Id = pu.PU_Id  
  LEFT JOIN Prod_Lines pmkgpl ON pu.PL_Id = pmkgpl.PL_Id  
  LEFT JOIN Event_Components gpec ON pe.Event_Id = gpec.Event_Id  
  LEFT JOIN Events gpe ON gpec.Source_Event_Id = gpe.Event_Id  
  LEFT JOIN Prod_Units gpu ON gpe.PU_Id = gpu.PU_Id  
  LEFT JOIN Prod_Lines gpl ON gpu.PL_Id = gpl.PL_Id  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #CvtgPRollsTemp set  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' '),  
  [LSP Comment] = replace(coalesce([LSP Comment],''), char(13)+char(10), ' '),  
  [Cvtg Comment] = replace(coalesce([Cvtg Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #CvtgPRollsTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #CvtgPRollsTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#CvtgPRollsTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #CvtgPRollsTemp  
  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Pmkg Rejects Data.  
 -------------------------------------------------------------------------------  
  
 CREATE TABLE #PmkgPRollsTemp(  
  [Event Date]   varchar(25),  
  [Event Time]   varchar(25),  
  [Status Date]   varchar(25),  
  [Status Time]   varchar(25),  
  [Paper Machine]   varchar(50),  
  [Paper Made Team]  varchar(10),  
  [Turnover Number]  varchar(100),  
  [PRoll Position]  varchar(100),  
  [Brand Desc]   varchar(50),  
  [GCAS]    varchar(100),  
  [PRID]    varchar(100),  
  [Weight]  float,  
  [Pmkg Roll Status]  varchar(100),  
  [Pmkg PRoll Reject Cause] varchar(100),  
  [Pmkg T# and Initials]  varchar(100),  
  [Pmkg Comment]   varchar(1000),  
  [RTCIS Reject Work Complete?] varchar(100),  
  [LSP Comment]   varchar(1000),  
  [PRoll Comment]   varchar(1000),  
  [PRoll ULID]   varchar(50)  
  )  
  
 Insert  #PmkgPRollsTemp  
 SELECT Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  pl.PL_Desc [Paper Machine],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),3,1)  
   ELSE NULL END) [Paper Made Team],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),4,3)  
   ELSE NULL END) [Turnover Number],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),7,1)  
   ELSE NULL END) [PRoll Position],  
  p.Prod_Desc [Brand Desc],  
  (SELECT Top 1 Value FROM @Tests WHERE (RollGCASId = VarId AND EventTime = StartTime)) [GCAS],  
  (SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (TonsRejectId = VarId AND EventTime = StartTime)) [Weight],   
  RollStatus [Pmkg Roll Status],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgPRollRejectCauseId = VarId AND EventTime = StartTime)) [Pmkg PRoll Reject Cause],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP Comment],  
  PRComment [PRoll Comment],  
  EventNumber [PRoll ULID]  
 FROM @PmkgPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @PmkgProdLines ppl ON rj.PLId = ppl.PLId  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #PmkgPRollsTemp set  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' '),  
  [LSP Comment] = replace(coalesce([LSP Comment],''), char(13)+char(10), ' '),  
  [PRoll Comment] = replace(coalesce([PRoll Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #PmkgPRollsTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #PmkgPRollsTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#PmkgPRollsTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #PmkgPRollsTemp  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Cvtg Reject data Where LSP T# and Initials  
 -- is NULL and status = Reject.    
 -------------------------------------------------------------------------------  
  
  
 CREATE TABLE #CvtgLSPTemp(  
  [RTCIS Work Complete?       Yes or No] varchar(100),  
  [LSP T# and Initials]   varchar(1000),  
  [PRoll ULID]    varchar(50),  
  [PRID]     varchar(100),  
  [Weight]   float,  
  [Slab Weight]    float,  
  [Event Date]    varchar(25),  
  [Event Time]    varchar(25),  
  [Status Date]    varchar(25),  
  [Status Time]    varchar(25),  
  [Cvtg Team]    varchar(10),  
  [Cvtg Shift]    varchar(10),  
  [Cvtg Roll Status]   varchar(100),  
  [Cvtg Line]    varchar(50),  
  [Cvtg T# and Initials]   varchar(100),  
  [Paper Defect Cause]   varchar(100),  
  [Cvtg Comment]    varchar(1000),  
  [Pmkg T# and Initials]   varchar(100),  
  [Pmkg Comment]    varchar(1000)  
  )  
  
  
 Insert  #CvtgLSPTemp  
 SELECT (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Work Complete? Yes or No],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP T# and Initials],  
  EventNumber [PRoll ULID],  
--Rev1.7  
  coalesce( (SELECT Value  
    FROM @Tests  
    WHERE GPPRIDId = VarId  
     AND EventTime = StartTime),  
    (SELECT Value  
    FROM @Tests  
    WHERE PRIDId = VarId  
     AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (CVPRRejWeightId = VarId AND EventTime = StartTime)) [Weight],  
  (SELECT Top 1 Value FROM @Tests WHERE (SlabWeightID = VarId AND EventTime = StartTime)) [Slab Weight],  
  Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  Team [Cvtg Team],  
  Shift [Cvtg Shift],  
  RollStatus [Cvtg Roll Status],  
  pl.PL_Desc [Cvtg Line],  
  (SELECT Top 1 Value FROM @Tests WHERE (CvtgTNoInitialsId = VarId AND EventTime = StartTime)) [Cvtg T# and Initials],  
  (SELECT Top 1 Value FROM @Tests WHERE (PaperDefectCauseID = VarId AND EventTime = StartTime)) [Paper Defect Cause],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)  
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (CvtgTNoInitialsId = VarId AND EventTime = StartTime)) [Cvtg Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment]  
 FROM @CvtgPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @CvtgProdLines ppl ON rj.PLId = ppl.PLId  
  LEFT JOIN Event_Components ec ON rj.EventId = ec.Event_Id  
  LEFT JOIN Events e ON ec.Source_Event_Id = e.Event_Id  
  LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
  LEFT JOIN Prod_Lines pmkgpl ON pu.PL_Id = pmkgpl.PL_Id  
 WHERE RollStatus = @StatusRejectDesc  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #CvtgLSPTemp set  
  [LSP T# and Initials] = replace(coalesce([LSP T# and Initials],''), char(13)+char(10), ' '),  
  [Cvtg Comment] = replace(coalesce([Cvtg Comment],''), char(13)+char(10), ' '),  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #CvtgLSPTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #CvtgLSPTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#CvtgLSPTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #CvtgLSPTemp  
  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Pmkg Rejects Data Where LSP T# and Initials  
 -- is NULL.  
 -------------------------------------------------------------------------------  
  
  
 CREATE TABLE #PmkgLSPTemp(  
  [RTCIS Work Complete?       Yes or No]  varchar(100),  
  [LSP T# and Initials]   varchar(1000),  
  [PRoll ULID]    varchar(50),  
  [PRID]     varchar(100),  
  [Weight]   float,  
  [Event Date]    varchar(25),  
  [Event Time]    varchar(25),  
  [Status Date]    varchar(25),  
  [Status Time]    varchar(25),  
  [Paper Machine]    varchar(50),  
  [Pmkg T# and Initials]   varchar(100),  
  [Pmkg Comment]    varchar(1000)  
  )  
  
  
 Insert #PmkgLSPTemp  
 SELECT (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP T# and Initials],  
  EventNumber [PRoll ULID],  
  (SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (TonsRejectId = VarId AND EventTime = StartTime)) [Weight],   
  Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  pl.PL_Desc [Paper Machine],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment]  
 FROM @PmkgPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @PmkgProdLines ppl ON rj.PLId = ppl.PLId  
 WHERE RollStatus = @StatusRejectDesc  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #PmkgLSPTemp set  
  [LSP T# and Initials] = replace(coalesce([LSP T# and Initials],''), char(13)+char(10), ' '),  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #PmkgLSPTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #PmkgLSPTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#PmkgLSPTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #PmkgLSPTemp  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Intermediate Input Rejects Pivot table.  
 -------------------------------------------------------------------------------  
 CREATE TABLE #IntrPRollsTemp2(  
  [Event Date]   varchar(25),  
  [Event Time]   varchar(25),  
  [Status Date]   varchar(25),  
  [Status Time]   varchar(25),  
  [Intr Team]   varchar(10),  
  [Intr Shift]   varchar(10),  
  [Intr Roll Status]  varchar(100),  
  [PRID]    varchar(100),  
  [Weight]   float,  
  [Paper Machine]   varchar(50),  
  [Paper Made Date]  varchar(25),  
  [Paper Made Team]  varchar(10),  
  [Turnover Number]  varchar(100),  
  [Turnover Position]  varchar(100),  
  [Substrate]   varchar(50),  
  [Winder Product]  varchar(50),  
  [Intr Line]   varchar(50),  
  [Paper Defect Cause]  varchar(100),  
  [Intr T# and Initials]  varchar(100),  
  [Intr Comment]   varchar(1000),  
  [Pmkg T# and Initials]  varchar(100),  
  [Pmkg Comment]   varchar(1000),  
  [RTCIS Reject Work Complete?] varchar(100),  
  [LSP Comment]   varchar(1000),  
  [Time Pmkg Notified]  varchar(100),  
  [Loc of Defect In Roll]  varchar(100),  
  [Loc of Defect Across Roll] varchar(100),  
  [PRoll ULID]   varchar(50),  
  [Rejected]   int,  
  [Total PR Run]   int,  
  [Initial Slab Radius 1]  float,  
  [Final Slab Radius 1]  float,  
  [Initial Slab Radius 2]  float,  
  [Final Slab Radius 2]  float,  
  [Initial Slab Radius 3]  float,  
  [Final Slab Radius 3]  float,  
  [Roll Slab Weight]  float  
  )  
  
 INSERT #IntrPRollsTemp2  
 SELECT Convert(varchar(25), EventTime, 101)[Event Date],  
  Convert(varchar(25), EventTime, 108)[Event Time],  
  Convert(varchar(25), StatusTime, 101)[Status Date],  
  Convert(varchar(25), StatusTime, 108)[Status Time],  
  Team [Intr Team],  
  Shift [Intr Shift],  
  RollStatus [Intr Roll Status],  
  coalesce( (SELECT Value  
    FROM @Tests  
    WHERE GPPRIDId = VarId  
     AND EventTime = StartTime),  
    (SELECT Value  
    FROM @Tests  
    WHERE PPRIDId = VarId  
     AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (CVPRRejWeightId = VarId AND EventTime = StartTime)) [Weight],  
  pmkgpl.PL_Desc [Paper Machine],  
  convert(varchar(25), coalesce( gpe.TimeStamp, pe.TimeStamp), 101) [Paper Made Date],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PPRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PPRIDId = VarId  
         AND EventTime = StartTime)))),3,1)  
   ELSE NULL  
   END)        [Paper Made Team],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PPRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PPRIDId = VarId  
         AND EventTime = StartTime)))),4,3)  
   ELSE NULL  
   END)        [Turnover Number],  
--Rev1.7  
  (CASE WHEN len(rtrim(ltrim(coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPPRIDId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE PPRIDId = VarId  
        AND EventTime = StartTime))))) = 11  
   THEN substring(rtrim(ltrim(coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPPRIDId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE PPRIDId = VarId  
         AND EventTime = StartTime)))),7,1)  
   ELSE NULL  
   END)         [Turnover Position],  
--Rev1.7  
  CASE WHEN charindex('(',coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPRollLabelDescId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE RollLabelDescId = VarId  
         AND EventTime = StartTime))) > 2  
   THEN left( coalesce( (SELECT Value  
       FROM @Tests  
       WHERE GPRollLabelDescId = VarId  
        AND EventTime = StartTime),  
       (SELECT Value  
       FROM @Tests  
       WHERE RollLabelDescId = VarId  
        AND EventTime = StartTime)),  
     charindex('(',coalesce( (SELECT Value  
        FROM @Tests  
        WHERE GPRollLabelDescId = VarId  
         AND EventTime = StartTime),  
        (SELECT Value  
        FROM @Tests  
        WHERE RollLabelDescId = VarId  
         AND EventTime = StartTime))) - 1)  
   ELSE NULL  
    END [Substrate],  
  p.Prod_Desc + '(' + p.Prod_Code + ')' [Winder Product],  
  pl.PL_Desc [Intr Line],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgDefectCauseId = VarId AND EventTime = StartTime)) [Paper Defect Cause],  
  (SELECT Top 1 Value FROM @Tests WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)  
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (TimePmkgNotifiedId = VarId AND EventTime = StartTime)) [Time Pmkg Notified],  
  (SELECT Top 1 Value FROM @Tests WHERE (DefectInRollId = VarId AND EventTime = StartTime)) [Loc of Defect In Roll],  
  (SELECT Top 1 Value FROM @Tests WHERE (DefectAcrossRollId = VarId AND EventTime = StartTime)) [Loc of Defect Across Roll],  
  EventNumber [PRoll ULID],  
  (CASE WHEN RollStatus = @StatusRejectDesc THEN 1 ELSE 0 END) [Rejected],  
  1 [Total PR Run],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius1ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 1],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius1ID = VarId AND EventTime = StartTime)) [Final Slab Radius 1],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius2ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 2],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius2ID = VarId AND EventTime = StartTime)) [Final Slab Radius 2],  
  (SELECT Top 1 Value FROM @Tests WHERE (InitialSlabRadius3ID = VarId AND EventTime = StartTime)) [Initial Slab Radius 3],  
  (SELECT Top 1 Value FROM @Tests WHERE (FinalSlabRadius3ID = VarId AND EventTime = StartTime)) [Final Slab Radius 3],  
  (SELECT Top 1 Value FROM @Tests WHERE (RollSlabWeightID = VarId AND EventTime = StartTime)) [Roll Slab Weight]  
 FROM @IntrPRolls2 rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @IntrProdLines ppl ON rj.PLId = ppl.PLId  
  LEFT JOIN Event_Components ec ON rj.EventId = ec.Event_Id  
  LEFT JOIN Events pe ON ec.Source_Event_Id = pe.Event_Id  
  LEFT JOIN Prod_Units pu ON pe.PU_Id = pu.PU_Id  
  LEFT JOIN Prod_Lines pmkgpl ON pu.PL_Id = pmkgpl.PL_Id  
  LEFT JOIN Event_Components gpec ON pe.Event_Id = gpec.Event_Id  
  LEFT JOIN Events gpe ON gpec.Source_Event_Id = gpe.Event_Id  
  LEFT JOIN Prod_Units gpu ON gpe.PU_Id = gpu.PU_Id  
  LEFT JOIN Prod_Lines gpl ON gpu.PL_Id = gpl.PL_Id  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #IntrPRollsTemp2 set  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' '),  
  [LSP Comment] = replace(coalesce([LSP Comment],''), char(13)+char(10), ' '),  
  [Intr Comment] = replace(coalesce([Intr Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #IntrPRollsTemp2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #IntrPRollsTemp2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#IntrPRollsTemp2', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #IntrPRollsTemp2  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Intermediates Production Rejects Data.  
 -------------------------------------------------------------------------------  
 CREATE TABLE #IntrPRollsTemp(  
  [Event Date]   varchar(25),  
  [Event Time]   varchar(25),  
  [Status Date]   varchar(25),  
  [Status Time]   varchar(25),  
  [Paper Machine]   varchar(50),  
  [Paper Made Team]  varchar(10),  
  [Turnover Number]  varchar(100),  
  [PRoll Position]  varchar(100),  
  [Brand Desc]   varchar(50),  
  [GCAS]    varchar(100),  
  [PRID]    varchar(100),  
  [Weight]  float,  
  [Intr Roll Status]  varchar(100),  
  [Intr PRoll Reject Cause] varchar(100),  
  [Intr T# and Initials]  varchar(100),  
  [Intr Comment]   varchar(1000),  
  [RTCIS Reject Work Complete?] varchar(100),  
  [LSP Comment]   varchar(1000),  
  [PRoll Comment]   varchar(1000),  
  [PRoll ULID]   varchar(50)  
  )  
  
 INSERT  #IntrPRollsTemp  
 SELECT Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  pl.PL_Desc [Paper Machine],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),3,1)  
   ELSE NULL END) [Paper Made Team],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),4,3)  
   ELSE NULL END) [Turnover Number],  
  (CASE WHEN len(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime))))) = 11 THEN  
   substring(rtrim(ltrim((SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)))),7,1)  
   ELSE NULL END) [PRoll Position],  
  p.Prod_Desc [Brand Desc],  
  (SELECT Top 1 Value FROM @Tests WHERE (RollGCASId = VarId AND EventTime = StartTime)) [GCAS],  
  (SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (TonsRejectId = VarId AND EventTime = StartTime)) [Weight],   
  RollStatus [Intr Roll Status],  
  (SELECT Top 1 Value FROM @Tests WHERE (IntrPRollRejectCauseId = VarId AND EventTime = StartTime)) [Intr PRoll Reject Cause],  
  (SELECT Top 1 Value FROM @Tests WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP Comment],  
  PRComment [PRoll Comment],  
  EventNumber [PRoll ULID]  
 FROM @IntrPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @IntrProdLines ppl ON rj.PLId = ppl.PLId  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #IntrPRollsTemp set  
  [Intr Comment] = replace(coalesce([Intr Comment],''), char(13)+char(10), ' '),  
  [LSP Comment] = replace(coalesce([LSP Comment],''), char(13)+char(10), ' '),  
  [PRoll Comment] = replace(coalesce([PRoll Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #IntrPRollsTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #IntrPRollsTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#IntrPRollsTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #IntrPRollsTemp  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Cvtg Reject data Where LSP T# and Initials  
 -- is NULL and status = Reject.    
 -------------------------------------------------------------------------------  
  
 CREATE TABLE #IntrLSPTemp2(  
  [RTCIS Work Complete?       Yes or No] varchar(100),  
  [LSP T# and Initials]   varchar(1000),  
  [PRoll ULID]    varchar(50),  
  [PRID]     varchar(100),  
  [Weight]   float,  
  [Slab Weight]    float,  
  [Event Date]    varchar(25),  
  [Event Time]    varchar(25),  
  [Status Date]    varchar(25),  
  [Status Time]    varchar(25),  
  [Intr Team]    varchar(10),  
  [Intr Shift]    varchar(10),  
  [Intr Roll Status]   varchar(100),  
  [Intr Line]    varchar(50),  
  [Intr T# and Initials]   varchar(100),  
  [Paper Defect Cause]   varchar(100),  
  [Intr Comment]    varchar(1000),  
  [Pmkg T# and Initials]   varchar(100),  
  [Pmkg Comment]    varchar(1000)  
  )  
  
  
 Insert  #IntrLSPTemp2  
 SELECT (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Work Complete? Yes or No],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP T# and Initials],  
  EventNumber [PRoll ULID],  
--Rev1.7  
  coalesce( (SELECT Value  
    FROM @Tests  
    WHERE GPPRIDId = VarId  
     AND EventTime = StartTime),  
    (SELECT Value  
    FROM @Tests  
    WHERE PRIDId = VarId  
     AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (CVPRRejWeightId = VarId AND EventTime = StartTime)) [Weight],  
  (SELECT Top 1 Value FROM @Tests WHERE (SlabWeightID = VarId AND EventTime = StartTime)) [Slab Weight],  
  Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  Team [Intr Team],  
  Shift [Intr Shift],  
  RollStatus [Intr Roll Status],  
  pl.PL_Desc [Intr Line],  
  (SELECT Top 1 Value FROM @Tests WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr T# and Initials],  
  (SELECT Top 1 Value FROM @Tests WHERE (PaperDefectCauseID = VarId AND EventTime = StartTime)) [Paper Defect Cause],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)  
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr Comment],  
  (SELECT Top 1 Value FROM @Tests WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (PmkgTNoInitialsId = VarId AND EventTime = StartTime)) [Pmkg Comment]  
 FROM @IntrPRolls2 rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @IntrProdLines ppl ON rj.PLId = ppl.PLId  
  LEFT JOIN Event_Components ec ON rj.EventId = ec.Event_Id  
  LEFT JOIN Events e ON ec.Source_Event_Id = e.Event_Id  
  LEFT JOIN Prod_Units pu ON e.PU_Id = pu.PU_Id  
  LEFT JOIN Prod_Lines pmkgpl ON pu.PL_Id = pmkgpl.PL_Id  
 WHERE RollStatus = @StatusRejectDesc  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #IntrLSPTemp2 set  
  [LSP T# and Initials] = replace(coalesce([LSP T# and Initials],''), char(13)+char(10), ' '),  
  [Intr Comment] = replace(coalesce([Intr Comment],''), char(13)+char(10), ' '),  
  [Pmkg Comment] = replace(coalesce([Pmkg Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #IntrLSPTemp2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #IntrLSPTemp2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#IntrLSPTemp2', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #IntrLSPTemp2  
  
 -------------------------------------------------------------------------------  
 -- Event source data for the Intr Production Rejects Data Where LSP T#  
 -- and Initials is NULL.  
 -------------------------------------------------------------------------------  
 CREATE TABLE #IntrLSPTemp(  
  [RTCIS Work Complete?       Yes or No]  varchar(100),  
  [LSP T# and Initials]   varchar(1000),  
  [PRoll ULID]    varchar(50),  
  [PRID]     varchar(100),  
  [Weight]   float,  
  [Event Date]    varchar(25),  
  [Event Time]    varchar(25),  
  [Status Date]    varchar(25),  
  [Status Time]    varchar(25),  
  [Paper Machine]    varchar(50),  
  [Intr T# and Initials]   varchar(100),  
  [Intr Comment]    varchar(1000)  
  )  
  
  
 INSERT #IntrLSPTemp  
 SELECT (SELECT Top 1 Value FROM @Tests WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [RTCIS Reject Work Complete?],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (LSPTNoInitialsId = VarId AND EventTime = StartTime)) [LSP T# and Initials],  
  EventNumber [PRoll ULID],  
  (SELECT Top 1 Value FROM @Tests WHERE (PRIDId = VarId AND EventTime = StartTime)) [PRID],  
  (SELECT Top 1 Value FROM @Tests WHERE (TonsRejectId = VarId AND EventTime = StartTime)) [Weight],   
  Convert(varchar(25), EventTime, 101) [Event Date],  
  Convert(varchar(25), EventTime, 108) [Event Time],  
  Convert(varchar(25), StatusTime, 101) [Status Date],  
  Convert(varchar(25), StatusTime, 108) [Status Time],  
  pl.PL_Desc [Paper Machine],  
  (SELECT Top 1 Value FROM @Tests WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr T# and Initials],  
  (SELECT Top 1 CONVERT(varchar(1000), Comment_Text)   
      FROM @Tests t  
       LEFT JOIN Comments c ON t.CommentId = c.Comment_Id  
      WHERE (IntrTNoInitialsId = VarId AND EventTime = StartTime)) [Intr Comment]  
 FROM @IntrPRolls rj  
  LEFT JOIN Prod_Lines pl ON rj.PLId = pl.PL_Id  
  LEFT JOIN Products p ON rj.ProdId = p.Prod_Id  
  LEFT JOIN @IntrProdLines ppl ON rj.PLId = ppl.PLId  
 WHERE RollStatus = @StatusRejectDesc  
 ORDER BY p.Prod_Desc, EventTime  
  
 update #IntrLSPTemp set  
  [LSP T# and Initials] = replace(coalesce([LSP T# and Initials],''), char(13)+char(10), ' '),  
  [Intr Comment] = replace(coalesce([Intr Comment],''), char(13)+char(10), ' ')  
  
 select @SQL =   
 case  
 when (select count(*) from #IntrLSPTemp) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #IntrLSPTemp) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#IntrLSPTemp', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
 drop table #IntrLSPTemp  
  
 end  
  
RETURN  
  
  
