CREATE procedure [dbo].[spASP_appEventAnalysis]
--declare
@EventType int,
@EventSubType  	  	  	  	 int, 
@StartTime  	  	  	  	  	  	 datetime,
@EndTime  	  	  	  	  	  	  	 datetime,
@NumberOfIntervals  	  	 int,
@Units  	  	  	  	  	  	  	  	 nvarchar(1000),
@Products  	  	  	  	  	  	 nvarchar(1000),
@Variables  	  	  	  	  	  	 nvarchar(3000),
@CrewFilter  	  	  	  	  	 nvarchar(100),
@FaultFilter  	  	  	  	  	 nvarchar(100), 	 
@CauseReportLevel  	  	 int,
@CauseCategoryFilter  	 int,
@CauseFilterLevel0  	  	 int,
@CauseFilterLevel1  	  	 int,
@CauseFilterLevel2  	  	 int,
@CauseFilterLevel3  	  	 int,
@CauseFilterLevel4  	  	 int,
@ActionReportLevel  	  	 int,
@ActionFilterLevel1  	 int,
@ActionFilterLevel2  	 int,
@ActionFilterLevel3  	 int,
@ActionFilterLevel4  	 int,
@AnalysisOptions  	  	  	 nvarchar(1000),
@LocationId 	  	  	  	  	  	 int,
@Categories    	  	  	  	 nVarChar(1000) = Null,
@FilterOutNPT 	 Bit = 0,
@ReasonId 	  	  	  	  	  	  	 int = Null,
@ShiftFilter 	  	  	  	  	 nvarchar(10) = Null,
@InTimeZone nvarchar(200)=NULL
AS
--Low Priority
--TODO: Add Flag To Just Dump (Joined) Details (need to keep id around?)
--TODO: Maybe Get Product Change Temp Table First And Then Join Products To Temp Table 
/*****************************************************
-- For Testing
--*****************************************************
Select @EventType = 3
Select @EventSubtype = null
Select @StartTime = '1-jul-2002'
Select @EndTime = '1-1-2006'
Select @NumberOfIntervals = 15
Select @Units = '136'
Select @Products = null
Select @Variables = null --'2,3,4,6,10'
Select @CrewFilter = NULL
Select @FaultFilter = NULL
Select @CauseReportLevel = 0
Select @CauseFilterLevel0 = NULL
Select @CauseFilterLevel1 = NULL
Select @CauseFilterLevel2 = NULL
Select @CauseFilterLevel3 = NULL
Select @CauseFilterLevel4 = NULL
Select @ActionReportLevel = 1
Select @ActionFilterLevel1 = NULL
Select @ActionFilterLevel2 = NULL
Select @ActionFilterLevel3 = NULL
Select @ActionFilterLevel4 = NULL
Select @AnalysisOptions = 'Product'
Select @AnalysisOptions = @AnalysisOptions + ',Cause'
Select @AnalysisOptions = @AnalysisOptions + ',Action'
Select @AnalysisOptions = @AnalysisOptions + ',Capability'
Select @AnalysisOptions = @AnalysisOptions + ',Summary'
Select @AnalysisOptions = @AnalysisOptions + ',Criteria'
Select @AnalysisOptions = @AnalysisOptions + ',Trends'
Select @AnalysisOptions = @AnalysisOptions + ',Fault'
Select @AnalysisOptions = @AnalysisOptions + ',Crew'
Select @AnalysisOptions = @AnalysisOptions + ',Location'
Select @AnalysisOptions = @AnalysisOptions + ',Category'
Select @AnalysisOptions = @AnalysisOptions + ',Unit'
--*****************************************************/
-- Retreive the Language Id of the current user
Declare @LangId INT
Declare @Err nvarchar(250)
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
-- Do some basic validation
--**********************************************
IF @Units = '' OR @Units IS NULL
  RAISERROR('SP: No Units Specifed', 16, -1)
SET @Err = 'SP: ' + dbo.fnDBTranslate(@LangId,35284,'You Must Specify Variables When Using Alarm Events')
IF @EventType = 11 And @Variables Is Null
 	 Raiserror(@Err, 16, -1)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnDBTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
--*****************************************************
--Determine Which Analysis Have Been Requested
--*****************************************************
Declare @HasProduct tinyint
Declare @HasCrew tinyint
Declare @HasShift tinyint
Declare @HasFault tinyint
Declare @HasCause tinyint
Declare @HasAction tinyint
Declare @HasCapability tinyint
Declare @HasStatistics tinyint
Declare @HasSummary tinyint
Declare @HasCriteria tinyint
Declare @HasTrends tinyint
Declare @HasLocations tinyint
Declare @HasCategories tinyint
Declare @HasUnits bit
Declare @HasNPTime Bit
DECLARE @INstr 	 VARCHAR(7000)
DECLARE @Id 	  	 INT
Select @HasProduct = Case When Charindex('Product', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasCrew = Case When Charindex('Crew', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasShift = Case When Charindex('Shift', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasFault = Case When Charindex('Fault', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasCause = Case When Charindex('Cause', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasAction = Case When Charindex('Action', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasCapability = Case When Charindex('Capability', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasSummary = Case When Charindex('Summary', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasCriteria = Case When Charindex('Criteria', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasTrends = Case When Charindex('Trends', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasLocations = Case When Charindex('Location', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasCategories = Case When Charindex('Category', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasUnits = Case When Charindex('Unit', @AnalysisOptions,1) > 0 Then 1 Else 0 End
Select @HasNPTime = Case When Charindex('NPTime', @AnalysisOptions,1) > 0 Then 1 Else 0 End
--Don't show certain sections when you drill down into them
If @Products Is Not Null
  If not (charindex(',',@Products,1) > 0)
    Select @HasProduct = 0
If @CrewFilter Is Not Null
  Select @HasCrew = 0
If @ShiftFilter Is Not Null
 	 Select @HasShift = 0
If @FaultFilter Is Not Null
  Select @HasFault = 0
If @LocationId Is Not Null
 	 Set @HasLocations = 0
--Don't show the category and action sections for the non-productive event
If @EventType = -2
 	 Begin
 	  	 Set @HasCategories = 0
 	  	 Set @HasAction = 0
 	 End
Declare @CategoryList Table (Item Int)
--If we only have one category, there is no need to break them down
If @Categories Is Not Null And charindex(',', @Categories, 1) = 0
 	 Set @HasCategories = 0
If @Categories Is Not Null  -- BS: ECR 34594 Create the @categoryList if @categories is not null
BEGIN
 	 Select @INstr = @Categories + ','
 	 While (LEN(LTRIM(RTRIM(@INstr))) > 1) 
 	 Begin
 	  	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	  	 insert into @CategoryList (Item) Values (@Id)
 	  	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),LEN(@INstr))
 	  	 Select @INstr = Right(@INstr,LEN(@INstr)-1)
 	 End
END
If @ReasonId Is Not Null And @ReasonId >= 0
 	 Set @HasNPTime = 0
Declare @FilterByCategory Bit
If @Categories Is Not Null
 	 Set @FilterByCategory = 1
--If we only have one unit, there is no need to break them down
If @Units Is Not Null And charindex(',', @Units, 1) = 0
 	 Set @HasUnits = 0
--*****************************************************
Declare @@UnitId int
Declare @SQL1 nvarchar(3000)
Declare @SQL2 nvarchar(3000)
Declare @SQL3 nvarchar(3000)
Declare @SQL4 nvarchar(3000)
Declare @ThisOperatingTime int
Declare @ThisProduction real
Declare @TotalOperatingTime int
Declare @TotalProduction real
Declare @IsAcknowledged int
Declare @EventName nVarChar(100)
Declare @UnitNameList nvarchar(3000)
Declare @VariableCount int
Declare @FaultId int
--These are used for getting the unit production stats
Declare @iActualProduction real,
@iActualQualityLoss real,
@iActualYieldLoss real,
@iIdealYield real,
@iIdealRate real, 
@iIdealProduction real,  
@iWarningProduction real,  
@iRejectProduction real,  
@iTargetQualityLoss real,
@iWarningQualityLoss real,
@iRejectQualityLoss real,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int
Declare @AmountEngineeringUnits nvarchar(25),
@WasteAmountEngUnits nvarchar(25),
@ItemEngineeringUnits nvarchar(25),
@TimeEngineeringUnits int
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @@ProductId int
Declare @EventId int
--These are used to temporarily store the timestamps of the events
--immediately before and after the time range.
Declare @PreTimestamp DateTime
Declare @PostTimestamp DateTime
Declare @ProductNameList nvarchar(3000)
DECLARE @MainSummaryTable Table  (
 	 [Timestamp] 	  	  	  	  	 datetime,
 	 ProductId 	  	  	  	  	 int NULL,
 	 CauseId  	  	  	  	  	 int NULL,
 	 ActionId  	  	  	  	  	 int NULL,
 	 Duration  	  	  	  	  	 real NULL,
 	 TimeToRepair  	  	  	  	 real NULL,
 	 TimePreviousFailure 	  	  	 real NULL,
 	 TimeToAck 	  	  	  	  	 int NULL,
 	 BucketTime 	  	  	  	  	 int NULL,
 	 BucketRepair 	  	  	  	 int NULL,
 	 BucketFailure 	  	  	  	 int NULL,
 	 Fault  	  	  	  	  	  	 nVarChar(100) NULL,
 	 Crew 	  	  	  	  	  	 nvarchar(10) NULL,
 	 Shift 	  	  	  	  	  	 nvarchar(10) NULL,
 	 LocationId 	  	  	  	  	 int NULL,
 	 CategoryId  	  	  	  	  	 int NULL,
 	 UnitId 	  	  	  	  	  	 int NULL
) 
DECLARE @MainSummaryTableForProduct Table  (
-- 	 [Timestamp] 	  	  	  	  	 datetime,
 	 ProductId 	  	  	  	  	 int NULL,
-- 	 CauseId  	  	  	  	  	 int NULL,
-- 	 ActionId  	  	  	  	  	 int NULL,
 	 Duration  	  	  	  	  	 real NULL
-- 	 TimeToRepair  	  	  	  	 real NULL,
-- 	 TimePreviousFailure 	  	  	 real NULL,
-- 	 TimeToAck 	  	  	  	  	 int NULL,
-- 	 BucketTime 	  	  	  	  	 int NULL,
-- 	 BucketRepair 	  	  	  	 int NULL,
-- 	 BucketFailure 	  	  	  	 int NULL,
-- 	 Fault  	  	  	  	  	  	 nVarChar(100) NULL,
-- 	 Crew 	  	  	  	  	  	 nvarchar(10) NULL,
-- 	 Shift 	  	  	  	  	  	 nvarchar(10) NULL,
-- 	 LocationId 	  	  	  	  	 int NULL,
-- 	 CategoryId  	  	  	  	  	 int NULL,
-- 	 UnitId 	  	  	  	  	  	 int NULL
) 
--If @HasFault = 1
--  Alter Table @MainSummaryTable Add Fault nVarChar(100) NULL
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
Select @EventName = NULL
Select @UnitNameList = NULL
Select @TotalOperatingTime = 0
-- Override Variables If CauseFilterLevel0 Is set and we are querying Alarms
If @EventType = 11 and @CauseFilterLevel0 Is Not Null
  Select @Variables = convert(nvarchar(10), @CauseFilterLevel0) 
--Build List Of Units
DECLARE @UnitsTable Table  (
  Item int
)
SELECT @INstr = @Units + ','
While (LEN(LTRIM(RTRIM(@INstr))) > 1) 
Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	 insert into @UnitsTable (Item) Values (@Id)
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),LEN(@INstr))
 	 Select @INstr = Right(@INstr,LEN(@INstr)-1)
End
--Build List Of Products
If @Products Is Not Null
  Begin
 	  	 DECLARE @ProductsTable Table  ( Item int 	 )
 	  	 SELECT @INstr = @Products + ','
 	  	 While (LEN(LTRIM(RTRIM(@INstr))) > 1) 
 	  	 Begin
 	  	  	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	  	  	 insert into @ProductsTable (Item) Values (@Id)
 	  	  	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),LEN(@INstr))
 	  	  	 Select @INstr = Right(@INstr,LEN(@INstr)-1)
 	  	 End
  End
--Build List Of Variables
If @Variables Is Not Null
  Begin
 	  	 DECLARE @VariablesTable Table  ( Item int)
 	  	 SELECT @INstr = @Variables + ','
 	  	 While (LEN(LTRIM(RTRIM(@INstr))) > 1) 
 	  	 Begin
 	  	  	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	  	  	 insert into @VariablesTable (Item) Values (@Id)
 	  	  	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),LEN(@INstr))
 	  	  	 Select @INstr = Right(@INstr,LEN(@INstr)-1)
 	  	 End
  End
If @HasProduct = 1 
  Begin
    DECLARE @OperatingTimeTable Table  (
      ProductId int,
      TotalTime int,
      TotalProduction real NULL 
    ) 
  End
Declare Unit_Event_Cursor Insensitive Cursor 
  For Select Item From @UnitsTable 
  For Read Only
Open Unit_Event_Cursor
Fetch Next From Unit_Event_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    If @UnitNameList Is Null
      Select @UnitNameList = PU_Desc From Prod_Units Where PU_Id = @@UnitId
    Else
      Select @UnitNameList = @UnitNameList + ', ' + (Select PU_Desc From Prod_Units Where PU_Id = @@UnitId)
 	 Print 'Analyzing EventType ' + Cast(@EventType As nvarchar(10)) + ' for units ' + @UnitNameList
  	  	 --Prepare Details Table
    DECLARE @DetailsTable Table  (
 	  	  	 Id 	  	  	  	  	  	  	  	  	 int Null,
 	  	   Timestamp  	  	  	  	  	 datetime,
 	  	  	 ProductId 	  	  	  	  	  	 int NULL,
 	  	  	 CauseId  	  	  	  	  	  	 int NULL,
 	  	  	 ActionId  	  	  	  	  	  	 int NULL,
      Duration  	  	  	  	  	  	 real NULL,
 	  	  	 TimeToRepair  	  	  	  	 real NULL,
 	  	  	 TimePreviousFailure 	 float NULL,
      TimeToAck 	  	  	  	  	  	 int NULL,
      FaultId  	  	  	  	  	  	 int NULL,
 	  	  	 Crew 	  	  	  	  	  	  	  	 nvarchar(10) NULL,
 	  	  	 Shift 	  	  	  	  	  	  	  	 nvarchar(10) NULL,
      SaveRow  	  	  	  	  	  	 tinyint NULL,
 	  	  	 LocationId 	  	  	  	  	 int NULL,
 	  	  	 CategoryId 	  	  	  	  	 int NULL,
 	  	  	 UnitId 	  	  	  	  	  	  	 int NULL,
 	  	  	 StartTime 	  	  	  	  	  	 DateTime Null,
 	  	  	 EndTime 	  	  	  	  	  	  	 DateTime Null,
 	  	  	 StartTimeNPT 	  	  	  	 DateTime Null,
 	  	  	 EndTimeNPT 	  	  	  	  	 DateTime Null,
 	  	  	 --The duration, quantity, etc. that occurred during non-productive time for this event
 	  	  	 NPQty  	  	  	  	  	  	  	 int Null,
 	  	  	 --The number of seconds of non-produtive time that occurred, without pro-rating.  This
 	  	  	 --is primarily used for the time to repair value.
 	  	  	 NPQtyActual 	  	  	  	  	 int Null, 
 	  	  	 ERTID 	  	  	  	  	  	  	  	 Int Null 	  	 
    ) 
  	  	 --Prepare @DetailsTableForProduct Table
    DECLARE @DetailsTableForProduct Table  (
 	  	  	 Id 	  	  	  	  	  	  	  	  	 int Null,
 	  	   Timestamp  	  	  	  	  	 datetime,
 	  	  	 ProductId 	  	  	  	  	  	 int NULL,
 	  	  	 --CauseId  	  	  	  	  	  	 int NULL,
 	  	  	 --ActionId  	  	  	  	  	  	 int NULL,
      Duration  	  	  	  	  	  	 real NULL,
 	  	  	 --TimeToRepair  	  	  	  	 real NULL,
 	  	  	 --TimePreviousFailure 	 float NULL,
      --TimeToAck 	  	  	  	  	  	 int NULL,
      FaultId  	  	  	  	  	  	 int NULL,
 	  	  	 --Crew 	  	  	  	  	  	  	  	 nvarchar(10) NULL,
 	  	  	 --Shift 	  	  	  	  	  	  	  	 nvarchar(10) NULL,
      --SaveRow  	  	  	  	  	  	 tinyint NULL,
 	  	  	 --LocationId 	  	  	  	  	 int NULL,
 	  	  	 --CategoryId 	  	  	  	  	 int NULL,
 	  	  	 --UnitId 	  	  	  	  	  	  	 int NULL,
 	  	  	 StartTime 	  	  	  	  	  	 DateTime Null,
 	  	  	 EndTime 	  	  	  	  	  	  	 DateTime Null,
 	  	  	 --StartTimeNPT 	  	  	  	 DateTime Null,
 	  	  	 --EndTimeNPT 	  	  	  	  	 DateTime Null,
 	  	  	 --The duration, quantity, etc. that occurred during non-productive time for this event
 	  	  	 NPQty  	  	  	  	  	  	  	 int Null
 	  	  	 --The number of seconds of non-produtive time that occurred, without pro-rating.  This
 	  	  	 --is primarily used for the time to repair value.
 	  	  	 --NPQtyActual 	  	  	  	  	 int Null  	  	 
    ) 
--    If @HasCapability = 1 
--  	  	   Create Index DetailTime on @DetailsTable (Timestamp, CauseId)
    If @EventType = 2 
      Begin
 	  	  	  	 --*****************************************************
 	  	  	  	 -- DOWNTIME EVENTS
 	  	  	  	 --*****************************************************
 	  	  	  	 Select @EventName = dbo.fnDBTranslate(@LangId, 34775, 'Downtime')
 	  	  	  	 --Get the timestamp of the event that occured before the time range
 	  	  	  	 Select @PreTimestamp = Max(d.End_Time)
 	  	  	  	 From Timed_Event_Details d
 	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	 And d.End_Time <= @StartTime
 	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In
 	  	  	  	  	  	  	  	 (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	 And (@FaultFilter Is Null Or d.TEFault_Id In (Select TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter))
 	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
 	  	  	  	 --Get the timestamp of the event that ended after the time range
 	  	  	  	 Select @PostTimestamp = Min(d.Start_Time)
 	  	  	  	 From Timed_Event_Details d
 	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	 And d.Start_Time >= @EndTime
 	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In
 	  	  	  	  	  	  	  	 (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	 And (@FaultFilter Is Null Or d.TEFault_Id In (Select TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter))
 	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
SELECT @PreTimestamp = ISNULL(@PreTimestamp,@StartTime)
SELECT @PostTimestamp = ISNULL(@PostTimestamp,@EndTime)
 	  	  	  	 Insert Into @DetailsTable ([Timestamp], StartTime, EndTime, StartTimeNPT, EndTimeNPT,
 	  	  	  	  	  	  	  	  	  	  CauseId, ActionId, Duration, TimeToRepair, FaultId, 
 	  	  	  	  	  	  	  	  	  	  LocationId, CategoryId, UnitId, NPQty, NPQtyActual,ERTID)
 	  	  	  	 Select d.Start_Time, d.Start_Time, d.End_Time,
 	  	  	  	  	 Case When @FilterOutNPT = 1 Then dbo.fnCmn_ModifyNPTimeRange2(@@UnitId, d.Start_Time, d.End_Time, 1, @ReasonId) Else d.Start_Time End,
 	  	  	  	  	 Case When @FilterOutNPT = 1 Then dbo.fnCmn_ModifyNPTimeRange2(@@UnitId, d.Start_Time, d.End_Time, 0, @ReasonId) Else d.End_Time End,
 	  	  	  	  	 Case When @CauseReportLevel <= 1 Then d.Reason_Level1
 	  	  	  	  	  	 When @CauseReportLevel = 2 Then d.Reason_Level2
 	  	  	  	  	  	 When @CauseReportLevel = 3 Then d.Reason_Level3
 	  	  	  	  	  	 Else d.Reason_Level4 End,
 	  	  	  	  	 Case When @ActionReportLevel = 1 Then d.Action_Level1
 	  	  	  	  	  	 When @ActionReportLevel = 2 Then d.Action_Level2
 	  	  	  	  	  	 When @ActionReportLevel = 3 Then d.Action_Level3
 	  	  	  	  	  	 Else d.Action_Level4 End,
 	  	  	  	  	 --Duration
 	  	  	  	  	 Case When d.Start_Time >= @StartTime And d.End_Time <= @EndTime
 	  	  	  	  	  	 Then Datediff(second, d.Start_Time, d.End_Time) / 60.0
 	  	  	  	  	  	 Else Datediff(second, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime)) / 60.0 End,
 	  	  	  	  	 --Time to repair
 	  	  	  	  	 DateDiff(second, d.Start_Time, coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	 --Calculate the time from previous failure
 	  	  	  	  	 --Case When d.Start_Time < @StartTime Then Null When d.Uptime <= 0 Then null else d.Uptime End,
 	  	  	  	  	 d.TEFault_Id,
 	  	  	  	  	 d.Source_PU_Id,
 	  	  	  	  	 Null,
 	  	  	  	  	 d.PU_Id UnitId,
 	  	  	  	  	 --NPTime
 	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(@@UnitId, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime), @ReasonId),
 	  	  	  	  	 --NPQtyActual
 	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(@@UnitId, d.Start_Time, Coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())), @ReasonId),
 	  	  	  	  	 d.Event_Reason_Tree_Data_Id
 	  	  	  	  	 From Timed_Event_Details_NPT d
 	  	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	  	  	  	  	 --Check if the the events started during our reporting range
 	  	  	  	  	 And (( d.Start_Time <= @PostTimestamp AND (d.End_Time >= @PreTimestamp OR d.End_Time is Null)))
 	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In
 	  	  	  	  	  	  	 (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	  	 And (@FaultFilter Is Null Or d.TEFault_Id In (Select TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter))
 	  	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
 	  	  	  	  	 Print Cast(@@RowCount As nvarchar(10)) + ' Downtime events were found that match the filter'
 	  	  	  	  	 --Loop through all of the events and calculate the time between failures (uptime)
 	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	 Set TimePreviousFailure = (datediff(second, 
 	  	  	  	  	  	 (Select max(d.EndTimeNPT) From @DetailsTable d Where d.EndTimeNPT < x.Timestamp And d.UnitId = x.UnitId), x.Timestamp)) / 60.0
 	  	  	  	  	 FROM @DetailsTable x
 	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	 Set CategoryId =  (SELECT Min(b.ERC_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 FROM Event_Reason_Category_Data b 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id = a.ERTID)
  	  	  	  	  	 FROM @DetailsTable a
 	  	  	  	  	 --select * from @DetailsTable order by timestamp
 	  	  	  	  	 If @FilterOutNPT = 1
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	  	 Set Duration = Duration - (NPQty / 60.0),
 	  	  	  	  	  	  	 TimeToRepair = TimeToRepair - (NPQtyActual / 60.0),
 	  	  	  	  	  	  	 TimePreviousFailure = TimePreviousFailure - (dbo.fnCmn_SecondsNPTime2(UnitId, (Select max(d.EndTimeNPT) From @DetailsTable d Where d.EndTimeNPT < x.[Timestamp]), x.[Timestamp], @ReasonId) / 60.0)
 	  	  	  	  	  	  	 FROM @DetailsTable x
 	  	  	  	  	  	  	 Delete From @DetailsTable
 	  	  	  	  	  	  	 Where Duration <= 0
 	  	  	  	  	  	  	 Print Cast(@@RowCount As nvarchar(10)) + ' Downtime events were filtered because they had no duration, or were completely in NP time'
 	  	  	  	  	  	 End
 	  	  	  	  	 --Remove the rows outside the time range
 	  	  	  	  	 Delete From @DetailsTable
 	  	  	  	  	 Where EndTime <= @StartTime Or StartTime >= @EndTime
 	  	  	  	  	 Print Cast(@@RowCount As nvarchar(10)) + ' downtime events were marked as being outside the time range'
--select * from @DetailsTable order by timestamp
       Select @IsAcknowledged = 0
      End        
    Else If @EventType = 3 
      Begin
 	  	  	  	 --*****************************************************
 	  	  	  	 -- Waste EVENTS
 	  	  	  	 --*****************************************************
 	  	  	  	 Select @EventName = dbo.fnDBTranslate(@LangId, 34779, 'Waste')
 	  	  	  	 Select @PreTimestamp = Max(Coalesce(e.[Timestamp], d.[Timestamp]))
 	  	  	  	 From Waste_Event_Details d
 	  	  	  	 Left Outer Join Events e On d.Event_Id = e.Event_Id
 	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	 And Coalesce(e.[Timestamp], d.[Timestamp]) <= @StartTime
 	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	 And (@FaultFilter Is Null Or d.WEFault_Id = (Select WEFault_Id From Waste_Event_Fault Where PU_Id = @@UnitId and WEFault_Name = @FaultFilter))
 	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
 	  	  	  	 --Don't count waste recorded in NP time
 	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime](d.PU_Id, d.[Timestamp], Null) = 0))
 	  	  	  	 And Amount > 0
 	  	  	  	 Print 'Pre Timestamp = ' + Cast(@PreTimestamp As nvarchar(100))
 	  	  	  	 Select @PostTimestamp = Min(Coalesce(e.[Timestamp], d.[Timestamp]))
 	  	  	  	 From Waste_Event_Details d
 	  	  	  	 Left Outer Join Events e On d.Event_Id = e.Event_Id
 	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	 And Coalesce(e.[Timestamp], d.[Timestamp]) >= @EndTime
 	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	 And (@FaultFilter Is Null Or d.WEFault_Id = (Select WEFault_Id From Waste_Event_Fault Where PU_Id = @@UnitId and WEFault_Name = @FaultFilter))
 	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
 	  	  	  	 --Don't count waste recorded in NP time
 	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime](d.PU_Id, d.[Timestamp], Null) = 0))
 	  	  	  	 And Amount > 0
 	  	  	  	 Print 'Post Timestamp = ' + Cast(@PostTimestamp As nvarchar(100))
 	  	  	  	 --Note: For event based waste, MABE only counts the timestamps of the events associated with the waste
 	  	  	  	 --records.  Multiple waste records within a single event are treated as 1 event for the MABE calculation.
 	  	  	  	 --For other calculations such as MAPE, each waste event is used because the individual amounts are important.
 	  	  	  	 Insert Into @DetailsTable (Id, [Timestamp], StartTime, CauseId, ActionId, Duration, TimeToRepair, FaultId, LocationId, CategoryId, UnitId, NPQty,ERTID,ProductId)
 	  	  	  	 Select d.WED_Id, Coalesce(e.[Timestamp], d.[Timestamp]), --The time of the event or the waste record
 	  	  	  	  	 d.[Timestamp], --the time of the waste record, even if it's associated with an event
 	  	  	  	  	 Case When @CauseReportLevel <= 1 Then d.Reason_Level1
 	  	  	  	  	  	 When @CauseReportLevel = 2 Then d.Reason_Level2
 	  	  	  	  	  	 When @CauseReportLevel = 3 Then d.Reason_Level3
 	  	  	  	  	  	 Else d.Reason_Level4 End,
 	  	  	  	  	 Case When @ActionReportLevel = 1 Then d.Action_Level1
 	  	  	  	  	  	 When @ActionReportLevel = 2 Then d.Action_Level2
 	  	  	  	  	  	 When @ActionReportLevel = 3 Then d.Action_Level3
 	  	  	  	  	  	 Else d.Action_Level4 End,
 	  	  	  	  	 d.Amount, d.Amount, d.WEFault_ID, d.Source_PU_Id,
 	  	  	  	  	 Null, d.pu_id,
 	  	  	  	  	 --NPQty is either not counted, or it's the amount of waste
 	  	  	  	  	 Case dbo.[fnWA_IsNonProductiveTime2](d.PU_Id, d.[Timestamp], Null, @ReasonId) When 0 Then 0 Else d.Amount End,
 	  	  	  	  	 d.Event_Reason_Tree_Data_Id,
 	  	  	  	  	 Coalesce(e.Applied_Product, ps.Prod_Id)
 	  	  	  	 From Waste_Event_Details d
 	  	  	  	 Left Outer Join Events e On d.Event_Id = e.Event_Id
                Left Outer Join Production_Starts ps on ps.PU_id = e.PU_Id and ps.start_time < e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time is Null))
 	  	  	  	 Where d.PU_Id = @@UnitId
 	  	  	  	 and ((Coalesce(e.[Timestamp], d.[Timestamp]) >= @StartTime and Coalesce(e.[Timestamp], d.[Timestamp]) <= @EndTime)
 	  	  	  	  	  	  	 Or Coalesce(e.[Timestamp], d.[Timestamp]) = @PostTimestamp
 	  	  	  	  	  	  	 Or Coalesce(e.[Timestamp], d.[Timestamp]) = @PreTimestamp)
 	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	 And (@CauseFilterLevel0 Is Null Or d.Source_PU_Id = @CauseFilterLevel0)
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action_Level1 = @ActionFilterLevel1)
 	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action_Level2 = @ActionFilterLevel2)
 	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action_Level3 = @ActionFilterLevel3)
 	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action_Level4 = @ActionFilterLevel4)
 	  	  	  	 And (@FaultFilter Is Null Or d.WEFault_Id = (Select WEFault_Id From Waste_Event_Fault Where PU_Id = @@UnitId and WEFault_Name = @FaultFilter))
 	  	  	  	 And (@LocationId Is Null Or d.Source_PU_Id = @LocationId)
 	  	  	  	 --Don't count waste recorded in NP time
 	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime](d.PU_Id, d.[Timestamp], Null) = 0))
 	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	 Set CategoryId =  (SELECT Min(b.ERC_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 FROM Event_Reason_Category_Data b 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id = a.ERTID)
  	  	  	  	  	 FROM @DetailsTable a
--select * from @DetailsTable
--select * from waste_event_details where timestamp = 'Jul 10 2006  2:20AM'
 	  	  	  	 
 	  	  	  	 --Count the waste events before we get rid of the placeholders (for example waste with 0)
 	  	  	  	 Declare @WasteOccurences Int
-- 	  	  	  	 Select @WasteOccurences = Count(Id)
-- 	  	  	  	 From @DetailsTable
-- 	  	  	  	 Where [Timestamp] <> @PreTimestamp
-- 	  	  	  	 And [Timestamp] <> @PostTimestamp
--
-- 	  	  	  	 --Now get rid of the placeholder events
-- 	  	  	  	 Delete From @DetailsTable
-- 	  	  	  	 Where Duration = 0
 	  	  	  	 Declare @LastRecord Int
 	  	  	  	 Select @LastRecord = Id
 	  	  	  	 From @DetailsTable
 	  	  	  	 Where [Timestamp] = (Select Max([Timestamp]) From @DetailsTable Where [Timestamp] <= @EndTime)
 	  	  	  	 Order By Id Asc
 	  	  	  	 --Cursor through the events and calculate the unit production
 	  	  	  	 Declare Evt_Cursor Cursor 
 	  	  	  	 For Select StartTime, UnitId, Id, ProductId
 	  	  	  	  	 From @DetailsTable 
 	  	  	  	  	 Where (Duration > 0)
 	  	  	  	  	 Or (Id = @LastRecord)
 	  	  	  	 For Read Only
 	  	  	  	 
 	  	  	  	 Declare @Timestamp DateTime, @UnitId Int
 	  	  	  	 Declare @ProductionStart DateTime, @ProductionEnd DateTime
 	  	  	  	 Open Evt_Cursor
 	  	  	  	 Fetch Next From Evt_Cursor Into @Timestamp, @UnitId, @EventId, @@ProductID
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
 	  	 
 	  	  	  	  	 --Get the timestamp of the previous event that had waste
 	  	  	  	  	 Select @ProductionStart = Max(StartTime)
 	  	  	  	  	 From @DetailsTable
 	  	  	  	  	 Where StartTime <= @Timestamp
 	  	  	  	  	 And UnitId = @UnitId
 	  	  	  	  	 And Id <> @EventId
 	  	  	  	  	 And Duration > 0
 	  	  	  	  	 --Get the timestamp of the previous event, because we can't count
 	  	  	  	  	 --the current waste event for production
 	  	  	  	  	 Select @ProductionEnd = Max(StartTime)
 	  	  	  	  	 From @DetailsTable
 	  	  	  	  	 Where StartTime <= @Timestamp
 	  	  	  	  	 And UnitId = @UnitId
 	  	  	  	  	 And Id <> @EventId
 	  	  	 
-- 	  	  	  	  	 --The end time for the production range is our current timestamp
-- 	  	  	  	  	 Set @ProductionEnd = @Timestamp
 	  	  	  	  	 
 	  	  	  	  	 If @ProductionStart Is Not Null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 --Look up the production stats
 	  	  	  	  	  	  	 execute spCMN_GetUnitProduction
 	  	  	  	  	  	  	  	 @UnitId,
 	  	  	  	  	  	  	  	 @ProductionStart,
 	  	  	  	  	  	  	  	 @ProductionEnd,
 	  	  	  	  	  	  	  	 @@ProductID, 
 	  	  	  	  	  	  	  	 @iActualProduction OUTPUT,
 	  	  	  	  	  	  	  	 @iActualQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iActualYieldLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iActualTotalItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualGoodItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualBadItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualConformanceItems OUTPUT,
 	  	  	  	  	  	  	  	 @iIdealYield OUTPUT,  
 	  	  	  	  	  	  	  	 @iIdealRate OUTPUT,  
 	  	  	  	  	  	  	  	 @iIdealProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iWarningProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iRejectProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iTargetQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iWarningQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iRejectQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @AmountEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @ItemEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @TimeEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @FilterOutNPT
 	 
 	  	  	  	  	  	  	  	 Print 'Production for ' + Cast(@ProductionStart As nvarchar(100)) + ' to ' + Cast(@ProductionEnd As nvarchar(100)) + ' is ' + Cast(@iActualproduction As nvarchar(100))
 	  	  	  	  	  	  	  	 --Update the current detail row with the production amount
 	  	  	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	  	  	 Set TimePreviousFailure = @iActualProduction
 	  	  	  	  	  	  	  	 Where Id = @EventId
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else If @ProductionStart = @ProductionEnd
 	  	  	  	  	  	  	 --The preceeding waste event was at the same time, so the production was 0
 	  	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	  	 Set TimePreviousFailure = 0
 	  	  	  	  	  	  	 Where Id = @EventId
 	  	  	  	  	  	 Fetch Next From Evt_Cursor Into @Timestamp, @UnitId, @EventId, @@ProductID
 	  	  	  	  	 End
 	  	  	  	 
 	  	  	  	 Close Evt_Cursor
 	  	  	  	 Deallocate Evt_Cursor
 	  	  	  	 --Get the information from the last row, since we needs it's data
 	  	  	  	 --before we get rid of it
 	  	  	  	 -- BS - Not clear why we are changing data for a good record (in range) by a record from outside of range (rev. 4209)
 	  	  	  	 -- This would create wrong report by associating waste amount to a wrong location/cause/action/fault/category
 	  	  	  	 -- ECR 34756
 	  	  	  	 --Update d
 	  	  	  	 --Set d.LocationId = d2.LocationId,
 	  	  	  	 --d.CauseId = d2.CauseId,
 	  	  	  	 --d.ActionId = d2.ActionId,
 	  	  	  	 --d.FaultId = d2.FaultId,
 	  	  	  	 --d.CategoryId = d2.CategoryId
 	  	  	  	 --From @DetailsTable d
 	  	  	  	 --Join @DetailsTable d2 On 1=1 --This is the joined table to get the data from
 	  	  	  	 ----Update the last record in the time range
 	  	  	  	 --Where d.Id = (Select Max(Id) From @DetailsTable Where [Timestamp] = (Select Max([Timestamp]) From @DetailsTable Where StartTime >= @StartTime And StartTime <= @EndTime))
 	  	  	  	 ----Get the data from the record outside the time range
 	  	  	  	 --And d2.Id = (Select Max(Id) From @DetailsTable Where [Timestamp] = (Select Max([Timestamp]) From @DetailsTable))
 	  	  	  	 --Remove the rows outside the time range
 	  	  	  	 Delete From @DetailsTable
 	  	  	  	 Where StartTime <= @StartTime Or StartTime >= @EndTime
--select * from @DetailsTable
        Select @IsAcknowledged = 0
      End        
    Else If @EventType = 11
      Begin
        Declare @@KeyId int
 	  	  	  	 Select @EventName = dbo.fnDBTranslate(@LangId, 34839, 'Alarms')
 	  	  	  	 --*****************************************************
 	  	  	  	 -- Alarm EVENTS
 	  	  	  	 --*****************************************************
        Select @VariableCount = 0
 	  	  	  	 Declare Alarm_Cursor Insensitive Cursor 
 	  	  	  	   For Select i.Item From @VariablesTable i Join Variables v on v.var_id = i.item Join Prod_Units pu on pu.pu_id = v.pu_Id and (pu.Pu_Id = @@UnitId or pu.Master_Unit = @@UnitId)   
 	  	  	  	   For Read Only
 	  	  	  	 
 	  	  	  	 Open Alarm_Cursor
 	  	  	  	 
 	  	  	  	 Fetch Next From Alarm_Cursor Into @@KeyId
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
 	  	  	  	     Select @VariableCount = @VariableCount + 1
 	  	 
 	  	  	  	  	  	 --Find the event before the time range
 	  	  	  	  	  	 Select @PreTimestamp = Max(Coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())))
 	  	  	  	  	  	 From Alarms d
 	  	  	  	  	  	 Where d.Key_Id = @@KeyId and d.Alarm_Type_Id in (1,2)
 	  	  	  	  	  	 And d.End_Time < @StartTime
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or
 	  	  	  	  	  	  	  	  	 d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Find the event after the time range
 	  	  	  	  	  	 Select @PreTimestamp = Min(d.Start_Time)
 	  	  	  	  	  	 From Alarms d
 	  	  	  	  	  	 Where d.Key_Id = @@KeyId and d.Alarm_Type_Id in (1,2)
 	  	  	  	  	  	 And d.Start_Time > @EndTime
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or
 	  	  	  	  	  	  	  	  	 d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 Insert Into @DetailsTable ([Timestamp], EndTime, CauseId, ActionId, Duration, TimeToRepair, TimeToAck, LocationId, CategoryId, UnitId, NPQty, NPQtyActual,ERTID)
 	  	  	  	  	  	 Select d.Start_Time, Coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())),
 	  	  	  	  	  	  	 Case When @CauseReportLevel <= 1 Then d.Cause1
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 2 Then d.Cause2
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 3 Then d.Cause3
 	  	  	  	  	  	  	  	 Else d.Cause4 End,
 	  	  	  	  	  	  	 Case When @ActionReportLevel = 1 Then d.Action1
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 2 Then d.Action2
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 3 Then d.Action3
 	  	  	  	  	  	  	  	 Else d.Action4 End,
 	  	  	  	  	  	 --Duration
 	  	  	  	  	  	 Datediff(second, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime)) / 60.0,
 	  	  	  	  	  	 --Time to repair (not pro-rated)
 	  	  	  	  	  	 Datediff(second, d.Start_Time , coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	 --Time to acknowledge (not pro-rated)
 	  	  	  	  	  	 Datediff(second, d.Start_Time, coalesce(d.Ack_On, dbo.fnServer_CmnGetDate(getutcdate()))),
 	  	  	  	  	  	 d.Key_Id, Null, d.source_pu_id,
 	  	  	  	  	  	 --NPQty is the amount of time that we were in an alarm state and in NP time
 	  	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(d.Source_PU_Id, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime), @ReasonId),
 	  	  	  	  	  	 --NPQtyActual
 	  	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(d.Source_PU_Id, Coalesce(d.Start_Time, @StartTime), Coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())), @ReasonId),
 	  	  	  	  	  	 d.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	 From Alarms d
 	  	  	  	  	  	 Where d.Key_Id = @@KeyId and d.Alarm_Type_Id in (1,2)
 	  	  	  	  	  	 And ((d.Start_Time >= @StartTime and d.Start_Time < @EndTime
 	  	  	  	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or
 	  	  	  	  	  	  	  	  	 d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList))))
 	  	  	  	  	  	  	  	 Or
 	  	  	  	  	  	  	  	 (d.Start_Time = (Select Max(t.Start_Time) From Alarms t Where t.Key_Id = @@KeyId and d.Alarm_Type_Id in (1,2)
 	  	  	  	  	  	  	  	  	 And t.start_time <= @StartTime and ((d.End_Time > @StartTime) or (d.End_Time is Null)))))
 	  	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	     Fetch Next From Alarm_Cursor Into @@KeyId
 	  	  	  	   End
 	  	  	  	 
 	  	  	  	 Close Alarm_Cursor
 	  	  	  	 Deallocate Alarm_Cursor  
 	  	  	  	 --Loop through all of the alarms and calculate the time between them
 	  	  	  	 --We'll also subtract the NP time while we're at it
 	  	  	  	 Update @DetailsTable
 	  	  	  	 Set TimePreviousFailure = (datediff(second, (Select max(d.EndTime) From @DetailsTable d Where d.EndTime < x.Timestamp And d.UnitId = x.UnitId), x.Timestamp) - Case When @FilterOutNPT = 1 Then dbo.fnCmn_SecondsNPTime2(UnitId, (Select max(d.Timestamp) From @DetailsTable d Where d.timestamp < x.Timestamp), x.Timestamp, @ReasonId) Else 0 End) / 60.0
 	  	  	  	 FROM @DetailsTable x
 	  	  	  	 
 	  	  	  	 Update @DetailsTable
 	  	  	  	 Set CategoryId =  (SELECT Min(b.ERC_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 FROM Event_Reason_Category_Data b 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id = a.ERTID)
 	  	  	  	 FROM @DetailsTable a
 	  	  	  	 --Remove the rows outside the time range
 	  	  	  	 Delete From @DetailsTable
 	  	  	  	 Where EndTime <= @StartTime Or StartTime >= @EndTime
 	  	  	  	 If @FilterOutNPT = 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 --Subtract the non-productive time
 	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	 Set Duration = Duration - (NPQty / 60.0),
 	  	  	  	  	  	 TimeToRepair = TimeToRepair - (NPQtyActual / 60.0),
 	  	  	  	  	  	 TimeToAck = TimeToAck - NPQtyActual
 	  	  	  	  	  	 --Delete all alarms with a duration of 0
 	  	  	  	  	  	 Delete From @DetailsTable
 	  	  	  	  	  	 Where Duration = 0
 	  	  	  	  	 End
        Select @IsAcknowledged = 1 
      End
    Else If @EventType = 14
      Begin
 	  	  	  	 --*****************************************************
 	  	  	  	 -- User Defined EVENTS
 	  	  	  	 --*****************************************************
        Declare @UDEType int
 	  	  	  	 Select @EventName = event_subtype_desc, @UDEType = duration_required, @IsAcknowledged = ack_required From Event_Subtypes Where event_subtype_id = @EventSubtype
 	  	  	  	 If @UDEType = 1 
         	 Begin
 	  	  	  	  	  	 --Get the timestamp of the event that occured before the time range
 	  	  	  	  	  	 Select @PreTimestamp = Max(d.End_Time)
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype 	  	  	  	  	 
 	  	  	  	  	  	 And d.End_Time <= @StartTime
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
    	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Get the timestamp of the event that occured after the time range
 	  	  	  	  	  	 Select @PostTimestamp = Min(d.Start_Time)
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype 	  	  	  	  	 
 	  	  	  	  	  	 And d.Start_Time >= @EndTime
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
    	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 SELECT @PreTimestamp = ISNULL(@PreTimestamp,@StartTime)
 	  	  	  	  	  	 SELECT @PostTimestamp = ISNULL(@PostTimestamp,@EndTime)
 	  	  	  	  	  	 Insert Into @DetailsTable ([Timestamp], StartTime, EndTime, CauseId, ActionId, TimeToAck, Duration, TimeToRepair, CategoryId, NPQty, NPQtyActual, UnitId,ERTID )
 	  	  	  	  	  	 Select d.Start_Time, d.Start_Time, d.End_Time,
 	  	  	  	  	  	  	 Case When @CauseReportLevel <= 1 Then d.Cause1
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 2 Then d.Cause2
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 3 Then d.Cause3
 	  	  	  	  	  	  	  	 Else d.Cause4 End,
 	  	  	  	  	  	  	 Case When @ActionReportLevel = 1 Then d.Action1
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 2 Then d.Action2
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 3 Then d.Action3
 	  	  	  	  	  	  	  	 Else d.Action4 End,
 	  	  	  	  	  	 --Time to Ack (Not pro-rated)
 	  	  	  	  	  	 Datediff(second, d.Start_Time, coalesce(d.Ack_on, dbo.fnServer_CmnGetDate(getutcdate()))),
 	  	  	  	  	  	 --Duration
 	  	  	  	  	  	 --Datediff(second, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime)) / 60.0,
 	  	  	  	  	  	 Case when (d.end_time is null)
 	  	  	  	  	  	     Then Datediff(second, d.Start_Time, @EndTime) / 60.0
                            Else Datediff(second, d.Start_Time, d.End_Time) / 60.0
 	  	  	  	  	  	 End,
 	  	  	  	  	  	 --Time to repair (Not pro-rated)
 	  	  	  	  	  	 DateDiff(second, d.Start_Time, coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	  	  	 --NPQty
 	  	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(d.PU_Id, dbo.fnGetHigherDate(d.Start_Time, @StartTime), dbo.fnGetLowerDate(d.End_Time, @EndTime), @ReasonId),
 	  	  	  	  	  	 --NPQtyActual
 	  	  	  	  	  	 dbo.fnCmn_SecondsNPTime2(d.PU_Id, Coalesce(d.Start_Time, @StartTime), Coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate())), @ReasonId),
 	  	  	  	  	  	 Null, d.PU_Id UnitId,d.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype
 	  	  	  	  	  	  	 and ((d.end_time>=@pretimestamp or d.end_time is null) and (d.start_time<=@posttimestamp))
 	  	  	  	  	 -- 	 And (((d.Start_Time = (Select Max(t.Start_Time) From User_Defined_Events t Where t.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype 	 And t.start_time < @EndTime))
 	  	  	  	  	 -- 	  	  	 And ((d.End_Time >= @StartTime) or (d.End_Time is Null)))
 	  	  	  	  	 -- 	  	  	  	 Or d.End_Time = @PreTimestamp Or d.Start_Time = @PostTimestamp)
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
    	  	  	  	  	 And (@CauseFilterLevel1 Is Null Or d.Cause1 = @CauseFilterLevel1)
 	  	  	  	  	  	 And (@CauseFilterLevel2 Is Null Or d.Cause2 = @CauseFilterLevel2)
 	  	  	  	  	  	 And (@CauseFilterLevel3 Is Null Or d.Cause3 = @CauseFilterLevel3)
 	  	  	  	  	  	 And (@CauseFilterLevel4 Is Null Or d.Cause4 = @CauseFilterLevel4)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Loop through all of the events and calculate the time between them
 	  	  	  	  	  	 --We'll also subtract the NP time while we're at it
 	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	 Set TimePreviousFailure = (datediff(second, (Select max(d.EndTime) From @DetailsTable d Where d.EndTime < x.Timestamp And d.UnitId = x.UnitId), x.Timestamp) - Case When @FilterOutNPT = 1 Then dbo.fnCmn_SecondsNPTime2(UnitId, (Select max(d.Timestamp) From @DetailsTable d Where d.timestamp < x.Timestamp), x.Timestamp, @ReasonId) Else 0 End) / 60.0
 	  	  	  	  	  	 FROM @DetailsTable x
 	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	 Set CategoryId =  (SELECT Min(b.ERC_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 FROM Event_Reason_Category_Data b 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id = a.ERTID)
 	  	  	  	  	  	 FROM @DetailsTable a
 	  	  	  	  	  	 --Remove the rows outside the time range
 	  	  	  	  	  	 Delete From @DetailsTable
 	  	  	  	  	  	 Where EndTime <= @StartTime Or StartTime >= @EndTime
 	  	  	  	  	  	 Print Cast(@@RowCount As nvarchar(10)) + ' non-productive events were marked as being outside the time range'
 	  	  	  	  	  	 --Factor in NP time to duration
 	  	  	  	  	  	 If @FilterOutNPT = 1
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	  	  	 Set Duration = Duration - (NPQty / 60.0),
 	  	  	  	  	  	  	  	 TimeToRepair = TimeToRepair - (NPQtyActual / 60.0),
 	  	  	  	  	  	  	  	 TimeToAck = TimeToAck - NPQtyActual
 	  	  	  	  	  	  	  	 Delete From @DetailsTable
 	  	  	  	  	  	  	  	 Where Duration = 0
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 --Get the timestamp of the event that occured before the time range
 	  	  	  	  	  	 Select @PreTimestamp = Max(d.End_Time)
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	  	 And d.End_Time <= @StartTime
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Don't count user defined events recorded in NP time
 	  	  	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime2](d.PU_Id, d.Start_Time, Null, @ReasonId) = 0))
 	  	  	  	  	  	 --Get the timestamp of the event that occured before the time range
 	  	  	  	  	  	 Select @PostTimestamp = Min(d.Start_Time)
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	  	 And d.Start_Time >= @StartTime
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Don't count user defined events recorded in NP time
 	  	  	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime2](d.PU_Id, d.Start_Time, Null, @ReasonId) = 0))
            -- Only Start Time Applies
 	  	  	  	  	  	 Insert Into @DetailsTable ([Timestamp], CauseId, ActionId, TimeToAck, Duration, TimeToRepair, CategoryId, UnitId, NPQty,ERTID)
 	  	  	  	  	  	 Select d.Start_Time,
 	  	  	  	  	  	  	 Case When @CauseReportLevel <= 1 Then d.Cause1
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 2 Then d.Cause2
 	  	  	  	  	  	  	  	 When @CauseReportLevel = 3 Then d.Cause3
 	  	  	  	  	  	  	  	 Else d.Cause4 End,
 	  	  	  	  	  	  	 Case When @ActionReportLevel = 1 Then d.Action1
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 2 Then d.Action2
 	  	  	  	  	  	  	  	 When @ActionReportLevel = 3 Then d.Action3
 	  	  	  	  	  	  	  	 Else d.Action4 End,
 	  	  	  	  	  	 Datediff(second, d.Start_Time, coalesce(d.Ack_on, dbo.fnServer_CmnGetDate(getutcdate()))),
 	  	  	  	  	  	 --Duration
 	  	  	  	  	  	 0.0,
 	  	  	  	  	  	 --Time to repair
 	  	  	  	  	  	 0.0,
 	  	  	  	  	  	 Null, d.PU_Id,
 	  	  	  	  	  	 --NPQty
 	  	  	  	  	  	 0.0,d.Event_Reason_Tree_Data_Id 
 	  	  	  	  	  	 From User_Defined_Events d
 	  	  	  	  	  	 Where d.PU_Id = @@UnitId and d.Event_Subtype_Id = @EventSubtype
 	  	  	  	  	  	 And (@FilterByCategory Is Null Or @FilterByCategory <> 1 Or d.Event_Reason_Tree_Data_Id In (Select Event_Reason_Tree_Data_Id From Event_Reason_Category_Data Where ERC_Id In (Select Item From @CategoryList)))
 	  	  	  	  	  	 And ((d.Start_Time >= @StartTime and d.Start_Time < @EndTime)
 	  	  	  	  	  	  	  	  	 Or
 	  	  	  	  	  	  	  	  	 d.Start_Time = @PostTimestamp Or d.End_Time = @PreTimestamp)
 	  	  	  	  	  	 And (@ActionFilterLevel1 Is Null Or d.Action1 = @ActionFilterLevel1)
 	  	  	  	  	  	 And (@ActionFilterLevel2 Is Null Or d.Action2 = @ActionFilterLevel2)
 	  	  	  	  	  	 And (@ActionFilterLevel3 Is Null Or d.Action3 = @ActionFilterLevel3)
 	  	  	  	  	  	 And (@ActionFilterLevel4 Is Null Or d.Action4 = @ActionFilterLevel4)
 	  	  	  	  	  	 --Don't count user defined events recorded in NP time
 	  	  	  	  	  	 And (@FilterOutNPT = 0 Or (dbo.[fnWA_IsNonProductiveTime2](d.PU_Id, d.Start_Time, Null, @ReasonId) = 0))
 	  	  	  	  	  	 --Loop through all of the events and calculate the time between them
 	  	  	  	  	  	 --We'll also subtract the NP time while we're at it
 	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	 Set TimePreviousFailure = (datediff(second, (Select max(d.[Timestamp]) From @DetailsTable d Where d.[Timestamp] < x.Timestamp And d.UnitId = x.UnitId), x.[Timestamp]) - Case When @FilterOutNPT = 1 Then dbo.fnCmn_SecondsNPTime2(UnitId, (Select max(d.[Timestamp]) From @DetailsTable d Where d.[Timestamp] < x.[Timestamp]), x.[Timestamp], @ReasonId) Else 0 End) / 60.0
 	  	  	  	  	  	 FROM @DetailsTable x
 	  	  	  	  	  	 
 	  	  	  	  	  	 Update @DetailsTable
 	  	  	  	  	  	 Set CategoryId =  (SELECT Min(b.ERC_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 FROM Event_Reason_Category_Data b 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE  b.Event_Reason_Tree_Data_Id = a.ERTID)
 	  	  	  	  	  	 FROM @DetailsTable a 	  	  	  	  	  	 
 	  	  	  	  	 End
      End
    Else If @EventType = -2
      Begin
 	  	  	  	 --*****************************************************
 	  	  	  	 -- Non-Productive Time
 	  	  	  	 --*****************************************************
 	  	  	  	 Select @EventName = dbo.fnDBTranslate(@LangId, 35132, 'Non-Productive Time')
 	  	  	  	 Set @IsAcknowledged = 0
 	  	  	  	 --Get the timestamp of the event that occured before the time range
 	  	  	  	 Select @PreTimestamp = Max(npd.End_Time)
 	  	  	  	 From NonProductive_Detail npd
 	  	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	  	 Where npd.PU_Id = @@UnitId
 	  	  	  	 And npd.End_Time <= @StartTime
 	  	  	  	 And (@FaultFilter Is Null Or npd.Event_Reason_Tree_Data_Id In
 	  	  	  	  	 (Select rtd.Event_Reason_Tree_Data_Id
 	  	  	  	  	 From Event_Reason_Tree_Data rtd
 	  	  	  	  	 Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
 	  	  	  	  	 Where er.Event_Reason_Name = @FaultFilter))
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or npd.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or npd.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or npd.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or npd.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@LocationId Is Null Or pu.PU_Id = @LocationId)
 	  	  	  	 --Get the timestamp of the event that occured after the time range
 	  	  	  	 Select @PostTimestamp = Min(npd.Start_Time)
 	  	  	  	 From NonProductive_Detail npd
 	  	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	  	 Where npd.PU_Id = @@UnitId
 	  	  	  	 And npd.Start_Time >= @EndTime
 	  	  	  	 And (@FaultFilter Is Null Or npd.Event_Reason_Tree_Data_Id In
 	  	  	  	  	 (Select rtd.Event_Reason_Tree_Data_Id
 	  	  	  	  	 From Event_Reason_Tree_Data rtd
 	  	  	  	  	 Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
 	  	  	  	  	 Where er.Event_Reason_Name = @FaultFilter))
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or npd.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or npd.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or npd.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or npd.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@LocationId Is Null Or pu.PU_Id = @LocationId)
 	  	  	  	 Insert Into @DetailsTable ([Timestamp], StartTime, EndTime, FaultId, Duration, TimeToRepair, LocationId, UnitId, CauseId)
 	  	  	  	 Select npd.Start_Time, npd.Start_Time, npd.End_Time, npd.Event_Reason_Tree_Data_Id,
 	  	  	  	 --Duration
 	  	  	  	 Datediff(second, dbo.fnGetHigherDate(npd.Start_Time, @StartTime), dbo.fnGetLowerDate(npd.End_Time, @EndTime)) / 60.0,
 	  	  	  	 --Time to repair (Not pro-rated)
 	  	  	  	 DateDiff(second, npd.Start_Time, coalesce(npd.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0,
 	  	  	  	 pu.Master_Unit, npd.PU_Id,
 	  	  	  	 Case When @CauseReportLevel <= 1 Then npd.Reason_Level1
 	  	  	  	  	 When @CauseReportLevel = 2 Then npd.Reason_Level2
 	  	  	  	  	 When @CauseReportLevel = 3 Then npd.Reason_Level3
 	  	  	  	  	 Else npd.Reason_Level4 End
 	  	  	  	 From NonProductive_Detail npd
 	  	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	  	  	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	  	  	  	 Where npd.PU_Id = @@UnitId
 	  	  	  	 And ((NPD.End_time = @PreTimestamp Or NPD.Start_Time = @PostTimestamp)
 	  	  	  	  	 Or (npd.Start_Time >= @StartTime and npd.Start_Time <= @EndTime))
 	  	  	  	 And (@FaultFilter Is Null Or npd.Event_Reason_Tree_Data_Id In
 	  	  	  	  	 (Select rtd.Event_Reason_Tree_Data_Id
 	  	  	  	  	 From Event_Reason_Tree_Data rtd
 	  	  	  	  	 Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
 	  	  	  	  	 Where er.Event_Reason_Name = @FaultFilter))
 	  	  	  	 And (@CauseFilterLevel1 Is Null Or npd.Reason_Level1 = @CauseFilterLevel1)
 	  	  	  	 And (@CauseFilterLevel2 Is Null Or npd.Reason_Level2 = @CauseFilterLevel2)
 	  	  	  	 And (@CauseFilterLevel3 Is Null Or npd.Reason_Level3 = @CauseFilterLevel3)
 	  	  	  	 And (@CauseFilterLevel4 Is Null Or npd.Reason_Level4 = @CauseFilterLevel4)
 	  	  	  	 And (@LocationId Is Null Or pu.PU_Id = @LocationId)
 	  	  	  	 --If the NP time filter is on, only get the events
 	  	  	  	 --that are associated with the non-productive category
 	  	  	  	 And (@FilterOutNPT = 0 Or (pu.Non_Productive_Category = ercd.ERC_Id))
 	  	  	  	 --Loop through all of the non-productive events and calculate the time between them
 	  	  	  	 Update @DetailsTable
 	  	  	  	 Set TimePreviousFailure = (datediff(second, (Select max(d.EndTime) From @DetailsTable d Where d.EndTime < x.Timestamp And d.UnitId = x.UnitId), x.Timestamp)) / 60.0
 	  	  	  	 FROM @DetailsTable x
 	  	  	  	 --Remove the rows outside the time range
 	  	  	  	 Delete From @DetailsTable
 	  	  	  	 Where EndTime <= @StartTime Or StartTime >= @EndTime
 	  	  	  	 Print Cast(@@RowCount As nvarchar(10)) + ' non-productive events were marked as being outside the time range'
 	   End
    If @Products Is Not Null OR @HasProduct = 1
      Begin
        DECLARE @ProductChanges Table  (
          ProductId int,
          StartTime datetime,
          EndTime datetime,
          ProductionAmount real NULL,
          SaveRow tinyint NULL
        )
        Insert Into @ProductChanges (ProductId, StartTime, EndTime)
 	  	   select ProdId, StartTime, EndTime from dbo.fnRS_GetReportProductMap(@@UnitId, @StartTime, @EndTime, 1) -- Force Event Type 1 so Applied Product is used
        if (@EventType = 11) -- Alarms
        begin
 	       Update @DetailsTable 
 	         Set ProductId = (Select ProductId From @ProductChanges ps Where ps.StartTime < x.Timestamp and ((ps.EndTime >= x.Timestamp) or (ps.EndTime Is Null)))      	 
 	  	  	 FROM @DetailsTable x
        end
        else if (@EventType <> 3) -- ProductIds allready filled in above for waste events
        begin
 	       Update @DetailsTable 
 	         Set ProductId = (Select ProductId From @ProductChanges ps Where ps.StartTime <= x.Timestamp and ((ps.EndTime > x.Timestamp) or (ps.EndTime Is Null)))      	 
 	  	  	 FROM @DetailsTable x
        end
        If @Products Is Not Null
          Begin
            Update @ProductChanges Set SaveRow = 1 Where ProductId in (Select Item From @ProductsTable)
            Delete From @ProductChanges Where SaveRow Is Null Or SaveRow = 0
            Update @DetailsTable Set SaveRow = 1 Where ProductId in (Select Item From @ProductsTable)
            Delete From @DetailsTable Where SaveRow Is Null Or SaveRow = 0
          End
        -- Update Operating Time From Trimmed Production Starts
        Select @ThisOperatingTime = ((Select sum(datediff(second, StartTime, EndTime))From @ProductChanges) * (Case When @EventType = 11 Then @VariableCount Else 1 End))
     	  	 Select @TotalOperatingTime = @TotalOperatingTime + @ThisOperatingTime
        If @EventType = 3
          Begin
            -- Loop Through Remaining Production Starts And Totalize Production
 	  	  	  	  	  	 Declare Time_Cursor Insensitive Cursor 
 	  	  	  	  	  	   For Select StartTime, EndTime, ProductId From @ProductChanges 
 	  	  	  	  	  	   For Read Only
 	  	  	  	  	  	 
 	  	  	  	  	  	 Open Time_Cursor
 	  	  	  	  	  	 
 	  	  	  	  	  	 Fetch Next From Time_Cursor Into @@StartTime, @@EndTime, @@ProductId
 	  	  	  	  	  	 
 	  	  	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	  	  	   Begin
 	  	  	  	  	  	  	  	 execute spCMN_GetUnitProduction
 	  	  	  	  	  	  	  	  	  	 @@UnitId,
 	  	  	  	  	  	  	  	  	  	 @@StartTime, 
 	  	  	  	  	  	  	  	  	  	 @@EndTime,
 	  	  	  	  	  	  	  	  	  	 @@ProductID, 
 	  	  	  	  	  	  	  	  	  	 @iActualProduction OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualYieldLoss OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualTotalItems OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualGoodItems OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualBadItems OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iActualConformanceItems OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iIdealYield OUTPUT,  
 	  	  	  	  	  	  	  	  	  	 @iIdealRate OUTPUT,  
 	  	  	  	  	  	  	  	  	  	 @iIdealProduction OUTPUT,  
 	  	  	  	  	  	  	  	  	  	 @iWarningProduction OUTPUT,  
 	  	  	  	  	  	  	  	  	  	 @iRejectProduction OUTPUT,  
 	  	  	  	  	  	  	  	  	  	 @iTargetQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iWarningQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @iRejectQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @AmountEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @ItemEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @TimeEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	  	  	 @FilterOutNPT
 	  	  	  	  	  	  	  	 if @AmountEngineeringUnits Is Null
 	  	  	  	  	  	  	  	  	 Set @WasteAmountEngUnits = ''
 	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	 Set @WasteAmountEngUnits = @AmountEngineeringUnits
                Update @ProductChanges set ProductionAmount = coalesce(@iActualProduction,0.0) + coalesce(@iActualQualityLoss,0)
                  Where ProductId = @@ProductId and StartTime = @@StartTime and EndTime = @@EndTime
 	  	  	  	  	  	  	  	 Fetch Next From Time_Cursor Into @@StartTime, @@EndTime, @@ProductId
 	  	  	  	  	  	   End
 	  	  	  	  	  	 
 	  	  	  	  	  	 Close Time_Cursor
 	  	  	  	  	  	 Deallocate Time_Cursor  
            -- Totalize Production
            Select @ThisProduction = coalesce((Select sum(ProductionAmount) From @ProductChanges),0)
            Select @TotalProduction = @TotalProduction + @ThisProduction
          End
        If @HasProduct = 1
          Begin
           	 Insert Into @OperatingTimeTable (ProductId, TotalTime, TotalProduction)
              Select ProductId, 
                     sum(datediff(second, StartTime, EndTime) - Case When @FilterOutNPT = 1 Then dbo.fnCmn_SecondsNPTime2(@@UnitId, StartTime, EndTime, @ReasonId) Else 0 End) * (Case When @EventType = 11 Then @VariableCount Else 1 End),
                     sum(ProductionAmount)
                From @ProductChanges
                Group By ProductId
          End
      End
    Else
      Begin
        Select @ThisOperatingTime = (datediff(second, @StartTime, @EndTime) * (Case When @EventType = 11 Then @VariableCount Else 1 End))
        Select @TotalOperatingTime = @TotalOperatingTime + @ThisOperatingTime
        If @EventType = 3 
          Begin
             --Get Production For Time Period 
 	  	  	  	  	  	 execute spCMN_GetUnitProduction
 	  	  	  	  	  	  	  	 @@UnitId,
 	  	  	  	  	  	  	  	 @StartTime, 
 	  	  	  	  	  	  	  	 @EndTime,
 	  	  	  	  	  	  	  	 0, 
 	  	  	  	  	  	  	  	 @iActualProduction OUTPUT,
 	  	  	  	  	  	  	  	 @iActualQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iActualYieldLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iActualTotalItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualGoodItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualBadItems OUTPUT,
 	  	  	  	  	  	  	  	 @iActualConformanceItems OUTPUT,
 	  	  	  	  	  	  	  	 @iIdealYield OUTPUT,  
 	  	  	  	  	  	  	  	 @iIdealRate OUTPUT,  
 	  	  	  	  	  	  	  	 @iIdealProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iWarningProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iRejectProduction OUTPUT,  
 	  	  	  	  	  	  	  	 @iTargetQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iWarningQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @iRejectQualityLoss OUTPUT,
 	  	  	  	  	  	  	  	 @AmountEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @ItemEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @TimeEngineeringUnits OUTPUT,
 	  	  	  	  	  	  	  	 @FilterOutNPT
            Select @ThisProduction = coalesce(@iActualProduction,0.0) + coalesce(@iActualQualityLoss,0) 
            Select @TotalProduction = @TotalProduction + @ThisProduction
          End
      End
--Debug the details table here
--Select * From @DetailsTable
    --If Crew Requested, Update Crew
    If @HasCrew = 1 or @CrewFilter Is Not Null or @HasShift = 1 or @ShiftFilter Is Not Null
 	 begin
      Update @DetailsTable 
        Set Crew = c.Crew_Desc,
 	  	  	  	 Shift = c.Shift_Desc
 	  	  	     FROM @DetailsTable x
 	  	  	  	 JOIN Crew_Schedule c ON c.PU_Id = @@UnitId and c.Start_Time <= x.Timestamp and C.End_Time > x.Timestamp
 	 -- 	  	  	 Where c.PU_Id = @@UnitId and c.Start_Time <= @DetailsTable.Timestamp and C.End_Time > @DetailsTable.Timestamp
 	 end
 	  	 Print 'Crew Filter: ' + @CrewFilter
    -- Purge Filtered Crew Records 
    If @CrewFilter Is Not Null
 	  	  	 If @CrewFilter = @sUnspecified
 	  	  	  	 Begin
 	  	  	  	 Print 'Filtering by unspecified crew'
 	  	  	  	 Delete From @DetailsTable Where Crew Is Not Null
 	  	  	  	 End
 	  	  	 Else
 	  	  	 begin
 	  	  	  	 Delete From @DetailsTable Where Crew <> @CrewFilter Or Crew Is Null
 	  	  	 end
 	  	 If @ShiftFilter Is Not Null
 	  	  	 If @ShiftFilter = @sUnspecified
 	  	  	 begin
 	  	  	  	 Delete From @DetailsTable Where Shift Is Not Null
 	  	  	 end
 	  	  	 Else
 	  	  	 begin
 	  	  	  	 Delete From @DetailsTable Where Shift <> @ShiftFilter Or Shift Is Null
 	  	  	 end
    -- If This Waste, We Need To Normalize MTBF From Time Units Into Production
    --If @EventType = 3 
    --  Update @DetailsTable set TimePreviousFailure = TimePreviousFailure * (@ThisProduction / (convert(real,@ThisOperatingTime) / 60.0))
    If @EventType = 2 -- or @EventType = 11 or (@EventType = 14 and @UDEType = 1) or @EventType = -2 
         -- Downtime, alarm event, ude, NP Time
    Begin
 	  	 -- Break up timebased rows based on products and save into a temporary table
 	  	 Insert Into @DetailsTableForProduct (ProductId, StartTime, EndTime, Id, [Timestamp], 
 	  	 --CauseId, ActionId, 
 	  	 Duration, 
 	     --TimeToRepair, TimePreviousFailure, TimeToAck, 
 	     FaultId, 
 	  	 --Crew, Shift, SaveRow, LocationId, CategoryId, 	 UnitId, 
 	  	 --StartTimeNPT, EndTimeNPT, 
        NPQty 
        --NPQtyActual
 	  	 )
 	  	 select 
 	  	  	 d.productid as ProductId,
 	  	  	 case when p.starttime<d.starttime then d.starttime else p.starttime end as StartTime, 
 	  	  	 case when p.endtime>d.endtime then d.endtime else p.endtime end as EndTime,
 	  	  	 p.Id,
 	  	  	 p.Timestamp,
 	  	  	 --p.CauseId,
 	  	  	 --p.ActionId,
 	  	  	 p.Duration,
 	  	  	 --p.TimeToRepair,
 	  	  	 --p.TimePreviousFailure,
 	  	  	 --p.TimeToAck,
 	  	  	 p.FaultId,
 	  	  	 --p.Crew,
 	  	  	 --p.Shift,
 	  	  	 --p.SaveRow,
 	  	  	 --p.LocationId,
 	  	  	 --p.CategoryId,
 	  	  	 --p.UnitId,
 	  	  	 --StartTime,
 	  	  	 --EndTime,
 	  	  	 --p.StartTimeNPT,
 	  	  	 --p.EndTimeNPT,
 	  	  	 p.NPQty
 	  	  	 --p.NPQtyActual
 	  	  	 from @ProductChanges d inner join @DetailsTable p on 
 	  	  	 (p.starttime<=d.starttime and p.endtime>d.starttime) or --there was a down time start during this product
 	  	  	 (p.starttime<d.endtime and p.endtime>=d.endtime) or --there was a down time end during this product
 	  	  	 (p.starttime>d.starttime and p.endtime<d.endtime) --this product is entirely within a downtime event
 	  	 order by starttime
 	  	 -- Update the duration column based on starttime/endtime, this accounts for the sliced duration based on product
 	  	 update @DetailsTableForProduct set Duration = Case When StartTime >= @StartTime And EndTime <= @EndTime
 	  	   Then Datediff(second, StartTime, EndTime) / 60.0
 	  	   Else Datediff(second, dbo.fnGetHigherDate(StartTime, @StartTime), dbo.fnGetLowerDate(EndTime, @EndTime)) / 60.0 End
 	  	 If @FilterOutNPT = 1
 	  	 Begin
 	  	  	 If @EventType = 2 -- or @EventType = 11 or (@EventType = 14 and @UDEType = 1) -- Downtime, alarm event, ude
 	  	  	 begin
 	  	  	  	 Update @DetailsTableForProduct
 	  	  	  	 Set Duration = Duration - (NPQty / 60.0)
 	  	  	  	 FROM @DetailsTableForProduct x
 	  	  	  	 Delete From @DetailsTableForProduct
 	  	  	  	 Where Duration <= 0
 	  	  	 end
 	  	 End
 	 end
 	 Else -- If @EventType = 3 waste and others
 	 Begin
 	  	 -- Just copy the @DetailsTable into @DetailsTableForProduct
 	  	 Insert Into @DetailsTableForProduct (ProductId, StartTime, EndTime, Id, [Timestamp], Duration, FaultId, NPQty)
 	  	 select 
 	  	  	 p.productid as ProductId,
 	  	  	 p.starttime, 
 	  	  	 p.endtime,
 	  	  	 p.Id,
 	  	  	 p.Timestamp,
 	  	  	 p.Duration,
 	  	  	 p.FaultId,
 	  	  	 p.NPQty
 	  	  	 from @DetailsTable p 
 	  	 -- Duraion is amount, don't do anything
 	 End
    If @HasFault = 1 and @EventType = 2
 	 begin
 	     Insert Into  @MainSummaryTable (Timestamp,ProductId,CauseId,ActionId,Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, Fault, LocationId, CategoryId, UnitId) 
 	       Select Timestamp,ProductId,CauseId,ActionId, Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, case when tef.TEFault_Id Is Null then @sUnspecified Else tef.TEFault_Name End, LocationId, CategoryId, UnitId
 	         From @DetailsTable x
          Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = x.FaultId 
 	  	 -- do the same for the product, only ProductId and duration are selecetd
 	     Insert Into  @MainSummaryTableForProduct (ProductId,Duration) 
 	       Select ProductId, Duration
 	         From @DetailsTableForProduct x
          Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = x.FaultId 
 	 end
    Else If @HasFault = 1 and @EventType = 3
 	 begin
 	     Insert Into  @MainSummaryTable (Timestamp,ProductId,CauseId,ActionId, Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, Fault, LocationId, CategoryId, UnitId) 
 	       Select Timestamp,ProductId,CauseId,ActionId, Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, case when wef.WEFault_Id Is Null then @sUnspecified Else wef.WEFault_Name End, LocationId, CategoryId, UnitId
 	         From @DetailsTable x
          Left Outer Join Waste_Event_Fault wef on wef.WEFault_Id = x.FaultId 
 	  	 -- do the same for the product, only ProductId and duration are selecetd
 	     Insert Into  @MainSummaryTableForproduct (ProductId, Duration) 
 	       Select ProductId, Duration
 	         From @DetailsTableForProduct x
          Left Outer Join Waste_Event_Fault wef on wef.WEFault_Id = x.FaultId 
 	 end
 	 Else If @HasFault = 1 And @EventType = -2 --Non-productive time
 	 begin
 	  	 Insert Into @MainSummaryTable ([Timestamp], ProductId, Duration, CauseId, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, Fault, LocationId, UnitId)
 	  	  	 Select [Timestamp], ProductId, Duration, CauseId, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, er.Event_Reason_Name, LocationId, UnitId
 	  	  	 From @DetailsTable d
 	  	  	 Left Outer Join Event_Reason_Tree_Data rtd On rtd.Event_Reason_Tree_Data_Id = d.FaultId
 	  	  	 Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
 	  	  	 --Left Outer Join Event_Reasons erp On rtd.Parent_Event_Reason_Id = er.Event_Reason_Id
 	  	 -- do the same for the product, only ProductId and duration are selecetd
 	  	 Insert Into @MainSummaryTableForProduct (ProductId, Duration)
 	  	  	 Select ProductId, Duration
 	  	  	 From @DetailsTableForProduct d
 	  	  	 Left Outer Join Event_Reason_Tree_Data rtd On rtd.Event_Reason_Tree_Data_Id = d.FaultId
 	  	  	 Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
 	  	  	 --Left Outer Join Event_Reasons erp On rtd.Parent_Event_Reason_Id = er.Event_Reason_Id
 	 end
    Else
 	 begin
 	     Insert Into  @MainSummaryTable (Timestamp,ProductId,CauseId,ActionId,Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, LocationId, CategoryId, UnitId) 
 	       Select Timestamp,ProductId,CauseId,ActionId,Duration, TimeToRepair, TimePreviousFailure, TimeToAck, Crew, Shift, LocationId, CategoryId, UnitId
 	         From @DetailsTable
 	  	 -- do the same for the product, only ProductId and duration are selecetd
 	     Insert Into  @MainSummaryTableForProduct (ProductId, Duration) 
 	       Select ProductId, Duration
 	         From @DetailsTableForProduct
 	 end
--Select npd.*, er.Event_Reason_Name 'Fault', erp.Event_Reason_Name 'Cause'
--From NonProductive_Detail npd
--Left Outer Join Event_Reason_Tree_Data rtd On rtd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id
--Left Outer Join Event_Reasons er On rtd.Event_Reason_Id = er.Event_Reason_Id
--Left Outer Join Event_Reasons erp On rtd.Parent_Event_Reason_Id = er.Event_Reason_Id
--
-- select * from event_reason_tree_data
--select * from event_reasons
    --For Testing
    DELETE from @DetailsTable
    DELETE from @DetailsTableForProduct
    If @Products Is Not Null OR @HasProduct = 1
 	 Begin
 	  	 DELETE from @ProductChanges
 	 end
    Fetch Next From Unit_Event_Cursor Into @@UnitId
  End
Close Unit_Event_Cursor
Deallocate Unit_Event_Cursor  
--*****************************************************
-- Prepare For Returning Resultsets
--*****************************************************
Declare @Total  	  	  	 real
Declare @Min  	  	  	  	 real
Declare @Max  	  	  	  	 real
Declare @Bucketsize real
Declare @Std  	  	  	  	 real
Declare @Avg  	  	  	  	 real
Declare @CapabilityBuckets int
DECLARE @FloatResults Table  (
  ID    int NULL,
  Value1 real NULL,
  Value2 real NULL 
)
DECLARE @FloatResults2 Table  (
  ID    int NULL,
  Value real NULL
)
DECLARE @IntegerResults Table  (
  ID    int NULL,
  Value int NULL
)
--*****************************************************
-- Pass Back Prompts
--*****************************************************
DECLARE @Prompts Table  (
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter nvarchar(3000),
  PromptValue_Parameter2 nvarchar(3000)
)
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Select @ReportName = @EventName + ' ' + dbo.fnDBTranslate(@LangId, 34574, 'Event Analysis')
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2) Values ('Criteria', dbo.fnDBTranslate(@LangId, 34520, 'Analyzing Data From [{0}] To [{1}]'), dbo.fnServer_CmnConvertFromDBTime(@StartTime,@InTimeZone), dbo.fnServer_CmnConvertFromDBTime(@EndTime,@InTimeZone))
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnDBTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnConvertFromDBTime(dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))
Insert into @Prompts (PromptName, PromptValue) Values ('ProductAnalysis', dbo.fnDBTranslate(@LangId, 34522, 'Product Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('CrewAnalysis', dbo.fnDBTranslate(@LangId, 34523, 'Crew Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('ShiftAnalysis', dbo.fnDBTranslate(@LangId, 35266, 'Shift Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('FaultAnalysis', dbo.fnDBTranslate(@LangId, 34524, 'Fault Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('CauseAnalysis', dbo.fnDBTranslate(@LangId, 34525, 'Cause Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('LocationAnalysis', dbo.fnDBTranslate(@LangId, 35194, 'Location Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('ActionAnalysis', dbo.fnDBTranslate(@LangId, 34526, 'Action Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('DataSummary', dbo.fnDBTranslate(@LangId, 34527, 'Data Summary'))
Insert into @Prompts (PromptName, PromptValue) Values ('CriteriaSummary', dbo.fnDBTranslate(@LangId, 34528, 'Criteria Summary'))
Insert into @Prompts (PromptName, PromptValue) Values ('CategoryAnalysis', dbo.fnDBTranslate(@LangId, 35174, 'Category Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('UnitAnalysis', dbo.fnDBTranslate(@LangId, 35171, 'Unit Analysis'))
Insert into @Prompts (PromptName, PromptValue) Values ('NPAnalysis', dbo.fnDBTranslate(@LangId, 35132, 'Non-Productive Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('TableCause', dbo.fnDBTranslate(@LangId, 34529, 'Cause'))
Insert into @Prompts (PromptName, PromptValue) Values ('TableTotal', dbo.fnDBTranslate(@LangId, 34530, 'Total'))
Insert into @Prompts (PromptName, PromptValue) Values ('TableOccurances', dbo.fnDBTranslate(@LangId, 34534, '#Occurrences'))
Insert into @Prompts (PromptName, PromptValue) Values ('TablePercentTotal', dbo.fnDBTranslate(@LangId, 34535, '%Rpt Time'))
If @EventType = -2
  Begin
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTR', dbo.fnDBTranslate(@LangId, 35164, 'MNPT'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTBF', dbo.fnDBTranslate(@LangId, 35165, 'MPT'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTA', dbo.fnDBTranslate(@LangId, 34105, 'MTTA'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TablePercentFault', dbo.fnDBTranslate(@LangId, 34536, '%Fault'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTTR', dbo.fnDBTranslate(@LangId, 35166, 'Inc MNPT'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTBF', dbo.fnDBTranslate(@LangId, 35196, 'Inc MPT'))
  End
Else If @EventType <> 3
  Begin 
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTR', dbo.fnDBTranslate(@LangId, 34531, 'MTTR'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTBF', dbo.fnDBTranslate(@LangId, 34532, 'MTBF'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTA', dbo.fnDBTranslate(@LangId, 34533, 'MTTA'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TablePercentFault', dbo.fnDBTranslate(@LangId, 34536, '%Fault'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTTR', dbo.fnDBTranslate(@LangId, 34537, 'Inc MTTR'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTBF', dbo.fnDBTranslate(@LangId, 34538, 'Inc MTBF'))
  End
Else
  Begin
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTR', dbo.fnDBTranslate(@LangId, 35248, 'MAPE'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTBF', dbo.fnDBTranslate(@LangId, 35249, 'MABE'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableMTTA', dbo.fnDBTranslate(@LangId, 35081, 'MATA'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TablePercentFault', dbo.fnDBTranslate(@LangId, 35082, '%Waste'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTTR', dbo.fnDBTranslate(@LangId, 35250, 'Inc MAPE'))
    Insert into @Prompts (PromptName, PromptValue) Values ('TableIncrementalMTBF', dbo.fnDBTranslate(@LangId, 35251, 'Inc MABE'))
  End
select * From @Prompts
--*****************************************************
-- Build Resultset Map
--*****************************************************
Declare @ResultsetNumber int
DECLARE @ResultsetMap Table  (
  [Id] int,
  Analysis  	  	 nvarchar(50),
  Item  	  	  	  	 nvarchar(50),
  [Description] nvarchar(255)
)
Select @ResultsetNumber = 0
If @HasProduct = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Product', 'PieOperatingPercent', dbo.fnDBTranslate(@LangId, 34539, 'Operating Time (%)'))    
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Product', 'PieOperatingPercent', dbo.fnDBTranslate(@LangId, 35022, 'Production (%)'))    
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Product', 'ParetoFaultPercent', dbo.fnDBTranslate(@LangId, 35197, 'Non-Productive Time (%)')) 
    Else If @EventType <> 3 
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Product', 'ParetoFaultPercent', dbo.fnDBTranslate(@LangId, 34540, 'Fault Time (%)'))    
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Product', 'ParetoFaultPercent', dbo.fnDBTranslate(@LangId, 35023, 'Waste (%)'))    
  End
If @HasCrew = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Crew', 'PiePercentbyCrew', dbo.fnDBTranslate(@LangId, 34541, 'Crew (%)'))    
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Crew', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Crew', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34542, 'MTTR and MTTA By Crew (Minutes)'))
    Else If @EventType <> 3 
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Crew', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34543, 'MTTR By Crew (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Crew', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35024, 'MATR By Crew') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Crew', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 34544, 'Occurrences By Crew (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Crew', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35199, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Crew', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 34545, 'MTBF By Crew (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Crew', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35025, 'MABF By Crew') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasShift = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Shift', 'PiePercentbyShift', dbo.fnDBTranslate(@LangId, 35267, 'Shift (%)'))    
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Shift', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Shift', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35268, 'MTTR and MTTA By Shift (Minutes)'))
    Else If @EventType <> 3 
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Shift', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35269, 'MTTR By Shift (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Shift', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35270, 'MATR By Shift') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Shift', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35271, 'Occurrences By Shift (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Shift', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35199, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Shift', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35272, 'MTBF By Shift (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Shift', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35273, 'MABF By Shift') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasFault = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Fault', 'PiePercentbyFault', dbo.fnDBTranslate(@LangId, 34546, 'Fault (%)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Fault', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Fault', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34547, 'MTTR and MTTA By Fault (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Fault', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34548, 'MTTR By Fault (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Fault', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35026, 'MAPE By Fault') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Fault', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 34549, 'Occurrences By Fault (#)')) 
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Fault', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Fault', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 34550, 'MTBF By Fault (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Fault', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35027, 'MABF By Fault') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasCause = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Cause', 'PiePercentbyCause', dbo.fnDBTranslate(@LangId, 34551, 'Cause (%)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Cause', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Cause', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34552, 'MTTR and MTTA By Cause (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Cause', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34553, 'MTTR By Cause (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Cause', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35028, 'MAPE By Cause') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Cause', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 34554, 'Occurrences By Cause (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Cause', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35199, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Cause', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 34555, 'MTBF By Cause (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Cause', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35029, 'MABE By Cause') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasLocations = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Location', 'PiePercentByLocation', dbo.fnDBTranslate(@LangId, 35200, 'Location (%)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	  	 Values (@ResultsetNumber, 'Location', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35198, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Location', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35201, 'MTTR and MTTA By Location (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Location', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35202, 'MTTR By Location (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Location', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35203, 'MAPE By Location') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Location', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35204, 'Occurrences By Location (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Location', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35199, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Location', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35205, 'MTBF By Location (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Location', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35252, 'MABE By Location') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasCategories = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Category', 'PiePercentByCategory', dbo.fnDBTranslate(@LangId, 35207, 'Category (%)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
    If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Category', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35208, 'MTTR and MTTA By Category (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Category', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35209, 'MTTR By Category (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Category', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35253, 'MAPE By Category') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Category', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35211, 'Occurrences By Category (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
    If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Category', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35212, 'MTBF By Category (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Category', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35254, 'MABE By Category') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasUnits = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Unit', 'PiePercentByUnit', dbo.fnDBTranslate(@LangId, 35214, 'Unit (%)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Unit', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35215, 'Average Non-Productive Time (Minutes)'))
    Else If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Unit', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35216, 'MTTR and MTTA By Unit (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Unit', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35217, 'MTTR By Unit (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Unit', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35255, 'MAPE By Unit') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Unit', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35219, 'Occurrences By Unit (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Unit', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35220, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Unit', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35221, 'MTBF By Unit (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Unit', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35256, 'MABE By Unit') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasAction = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Action', 'PiePercentbyAction', dbo.fnDBTranslate(@LangId, 34556, 'Occurrence By Action (%)')) 
    Select @ResultsetNumber = @ResultsetNumber + 1
    If @IsAcknowledged = 1  
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Action', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34557, 'MTTR and MTTA By Action (Minutes)'))
    Else If @EventType <> 3
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Action', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 34558, 'MTTR By Action (Minutes)'))
    Else
 	     Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	       Values (@ResultsetNumber, 'Action', 'ParetoMTTR', dbo.fnDBTranslate(@LangId, 35030, 'MAPE By Action') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Action', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35274, 'Occurrences By Action (#)'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Action', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35220, 'Average Productive Time (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Action', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35279, 'MTBF By Action (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Action', 'ParetoMTBF', dbo.fnDBTranslate(@LangId, 35276, 'MABE By Action') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasNPTime = 1
 	 Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'NPTime', 'PiePercent', dbo.fnDBTranslate(@LangId, 35223, 'Non-Productive Time Reasons (Minutes)')) 
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'NPTime', 'PiePercent', dbo.fnDBTranslate(@LangId, 35224, 'Productive Time vs. Non-Productive Time (Minutes)')) 
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'NPTime', 'ParetoOccurances', dbo.fnDBTranslate(@LangId, 35225, 'Non-Productive Reason Occurences')) 
 	 End
If @HasCapability = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTTR', dbo.fnDBTranslate(@LangId, 35226, 'Non-Productive Capability (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTTR', dbo.fnDBTranslate(@LangId, 34559, 'MTTR Capability (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTTR', dbo.fnDBTranslate(@LangId, 35031, 'MAPE Capability') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTTR', dbo.fnDBTranslate(@LangId, 35239, 'Non-Productive Capability (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTTR', dbo.fnDBTranslate(@LangId, 34559, 'MTTR Capability (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTTR', dbo.fnDBTranslate(@LangId, 35031, 'MAPE Capability') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTBF', dbo.fnDBTranslate(@LangId, 35240, 'Productive Capability (Minutes)'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTBF', dbo.fnDBTranslate(@LangId, 34560, 'MTBF Capability (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'StatisticsMTBF', dbo.fnDBTranslate(@LangId, 35032, 'MABE Capability') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTBF', dbo.fnDBTranslate(@LangId, 35227, 'Productive Capability (Minutes)'))
    Else If @EventType <> 3 
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTBF', dbo.fnDBTranslate(@LangId, 34560, 'MTBF Capability (Minutes)'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Capability', 'HistogramMTBF', dbo.fnDBTranslate(@LangId, 35032, 'MABE Capability') + '(' + Coalesce(@WasteAmountEngUnits, '') + ')')
  End
If @HasTrends = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Trends', 'TrendTotal', dbo.fnDBTranslate(@LangId, 34561, 'Total Trend'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTBF', dbo.fnDBTranslate(@LangId, 35228, 'Productive Time Trend'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTBF', dbo.fnDBTranslate(@LangId, 34562, 'MTBF Trend'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTBF', dbo.fnDBTranslate(@LangId, 35033, 'MABE Trend'))
    Select @ResultsetNumber = @ResultsetNumber + 1
 	 If @EventType = -2
 	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTTR', dbo.fnDBTranslate(@LangId, 35229, 'Non-Productive Time Trend'))
    Else If @EventType <> 3
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTTR', dbo.fnDBTranslate(@LangId, 34563, 'MTTR Trend'))
    Else
      Insert into @ResultsetMap (ID, Analysis, Item, Description)
        Values (@ResultsetNumber, 'Trends', 'TrendMTTR', dbo.fnDBTranslate(@LangId, 35034, 'MAPE Trend'))
    If @IsAcknowledged = 1
      Begin
 	  	  	 Select @ResultsetNumber = @ResultsetNumber + 1
 	  	  	 Insert into @ResultsetMap (ID, Analysis, Item, Description)
 	  	  	 Values (@ResultsetNumber, 'Trends', 'TrendMTTA', dbo.fnDBTranslate(@LangId, 34564, 'MTTA Trend'))
      End
  End
If @HasSummary = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Summary', 'GridStatistics', dbo.fnDBTranslate(@LangId, 34565, 'Data Summary'))
  End
If @HasCriteria = 1
  Begin
    Select @ResultsetNumber = @ResultsetNumber + 1
    Insert into @ResultsetMap (ID, Analysis, Item, Description)
      Values (@ResultsetNumber, 'Criteria', 'GridCriteria', dbo.fnDBTranslate(@LangId, 34566, 'Criteria Summary'))
  End
Select * From @ResultsetMap
  Order By ID
--*****************************************************
-- Return Product Resultsets
--*****************************************************
If @HasProduct = 1
  Begin
    If @EventType <> 3 
   	  	 Select @Total = sum(TotalTime) / 60.0 From @OperatingTimeTable
    Else
   	  	 Select @Total = sum(TotalProduction) From @OperatingTimeTable
 	  	 
 	  	 
 	  	 DELETE FROM  @FloatResults2
 	  	 
 	 -- Return % Operating Time By Product
 	 -- The percentage of run time for each product compared to the total run time
    If @EventType <> 3 
   	  	 Insert Into @FloatResults2 (Id, Value)
 	    	   Select ProductId, sum(TotalTime) / 60.0
          From @OperatingTimeTable
 	  	       Group By ProductId 
    Else
   	  	 Insert Into @FloatResults2 (Id, Value)
 	    	   Select ProductId, sum(TotalProduction)
          From @OperatingTimeTable
 	  	       Group By ProductId 
 	 --First Product Chart
    Select ProductId = Id, Product = CASE WHEN p.Prod_Code = '<None>' THEN dbo.fnDBTranslate(@LangId, 34079, '<None>') ELSE p.Prod_Code END, 
           PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value / @Total * 100.0 END
      From @FloatResults2 i 
      Left Outer Join Products p on p.Prod_id = i.Id
      Order By Value DESC 
 	  	 
 	  	 -- Return % Fault Time By Product
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select ProductId, sum(Duration)
        From @MainSummaryTableForProduct
 	  	     Group By ProductId 
--select * from @DetailsTable
--select * from @FloatResults2 --19 & 180
--select * from @FloatResults --19 & 50 & Null
 	 --Second product chart
 	 --The total number of minutes/waste from each event divided by the amount of time the product was run
    Select ProductId = i.Id, Product = CASE WHEN p.Prod_Code = '<None>' THEN dbo.fnDBTranslate(@LangId, 34079, '<None>') ELSE p.Prod_Code END, 
           PercentFault = CASE WHEN i.Value = 0 THEN 0.0 ELSE f.Value1 / i.Value * 100.0 END
      From @FloatResults2 i --The total amount of minutes/waste while that product was run (from @OperatingTimeTable)
      Left Outer Join Products p on p.Prod_id = i.Id
      left outer Join @FloatResults f on f.Id = i.Id --The total amount of minutes/waste from the event (from @DetailsTable)
      Where i.Value > 0
      Order By PercentFault DESC 
  End
--*****************************************************
-- Return Crew Resultsets
--*****************************************************
If @HasCrew = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Crew
 	  	 --The duration/quantity attributed to each crew
 	   Select Coalesce(Crew, @sUnspecified) Crew, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE sum(Duration) / @Total * 100.0 END
      From @MainSummaryTable
 	     Group By Crew
      Order By sum(Duration) DESC 
 	  	 
 	  	 -- Return MTTR, MTTA
 	   Select Coalesce(Crew, @sUnspecified) Crew, MTTR = avg(TimeToRepair), MTTA = avg(TimeToAck) / 60.0
      From @MainSummaryTable
 	     Group By Crew 	 
 	  	   Order by avg(TimeToRepair) DESC
 	  	 -- Return #Occurances
 	   Select Coalesce(Crew, @sUnspecified) Crew, Occurances = count(Timestamp)
      From @MainSummaryTable
 	     Group By Crew 
 	  	   Order by Count(timestamp) DESC
 	  	  	  	 
 	  	 -- Return MTBF/MABE
 	   Select Coalesce(Crew, @sUnspecified) Crew, MTBF = avg(TimePreviousFailure)
      From @MainSummaryTable
 	     Group By Crew
 	  	   Order By avg(TimePreviousFailure) ASC
  End
--*****************************************************
--*****************************************************
-- Return Shift Resultsets
--*****************************************************
If @HasShift = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Shift
 	  	 --The duration/quantity attributed to each shift
 	   Select Coalesce(Shift, @sUnspecified) Shift, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE sum(Duration) / @Total * 100.0 END
      From @MainSummaryTable
 	     Group By Shift
      Order By sum(Duration) DESC 
 	  	 
 	  	 -- Return MTTR, MTTA
 	   Select Coalesce(Shift, @sUnspecified) Shift, MTTR = avg(TimeToRepair), MTTA = avg(TimeToAck) / 60.0
      From @MainSummaryTable
 	     Group By Shift 	 
 	  	   Order by avg(TimeToRepair) DESC
 	  	 -- Return #Occurances
 	   Select Coalesce(Shift, @sUnspecified) Shift, Occurances = count(Timestamp)
      From @MainSummaryTable
 	     Group By Shift 
 	  	   Order by Count(timestamp) DESC
 	  	  	  	 
 	  	 -- Return MTBF
 	   Select Coalesce(Shift, @sUnspecified) Shift, MTBF = avg(TimePreviousFailure)
      From @MainSummaryTable
 	     Group By Shift
 	  	   Order By avg(TimePreviousFailure) ASC
  End
--*****************************************************
--*****************************************************
-- Return Fault Resultsets
--*****************************************************
If @HasFault = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Fault
 	   --The percentage of time/waste that this fault caused, over the total fault time/amount
 	   Select Coalesce(Fault, @sUnspecified) Fault, PercentTotal = CASE WHEN @Total = 0 Then 0.0 ELSE sum(Duration) / @Total * 100.0 END
      From @MainSummaryTable
 	     Group By Fault
      Order By sum(Duration) DESC 
 	  	 
 	  	 -- Return MTTR, MTTA
 	   Select Coalesce(Fault, @sUnspecified) Fault, MTTR = avg(TimeToRepair), MTTA = avg(TimeToAck) / 60.0
      From @MainSummaryTable
 	     Group By Fault  	 
 	  	   Order by avg(TimeToRepair) DESC
 	  	 -- Return #Occurances
 	   Select Coalesce(Fault, @sUnspecified) Fault, Occurances = count(Timestamp)
      From @MainSummaryTable
 	     Group By Fault 
 	  	   Order by Count(timestamp) DESC
 	  	  	  	 
 	  	 -- Return MTBF
 	   Select Coalesce(Fault, @sUnspecified) Fault, MTBF = avg(TimePreviousFailure)
      From @MainSummaryTable
 	     Group By Fault 
 	  	   Order By avg(TimePreviousFailure) ASC
  End
--*****************************************************
--*****************************************************
-- Return Cause Resultsets
--*****************************************************
If @HasCause = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Cause
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select CauseId, sum(Duration)
        From @MainSummaryTable
 	  	     Group By CauseId 
 	  	 
 	  	 If @EventType in (2,3) and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11 and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = v.Var_Desc, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select CauseId = Id, Cause = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	  	 -- Return MTTR, MTTA
 	  	 DELETE FROM  @FloatResults
 	  	 Insert Into @FloatResults (Id, Value1, Value2)
 	  	   Select CauseId, avg(TimeToRepair), avg(TimeToAck) / 60.0
        From @MainSummaryTable
 	  	     Group By CauseId 
 	  	 
 	  	 If @EventType in (2,3) and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11 and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = v.Var_Desc, MTTR = Value1, MTTA = Value2   
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select CauseId = Id, Cause = case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	 
 	  	 
 	  	 -- Return #Occurances
 	  	 DELETE FROM @IntegerResults
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select CauseId, count(Timestamp)
        From @MainSummaryTable
 	  	     Group By CauseId 
 	  	 
 	  	 If @EventType in (2,3) and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Prod_Units pu on pu.PU_id = i.Id
        Order By Value DESC 
 	  	 Else If @EventType = 11 and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = v.Var_Desc, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Variables v on v.Var_id = i.Id
        Order By Value DESC 
    Else
      Select CauseId = Id, Cause = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
        Order By Value DESC 
 	  	 
 	  	 -- Return MTBF
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select CauseId, avg(TimePreviousFailure)
        From @MainSummaryTable
 	  	     Group By CauseId 
 	  	 
 	  	 If @EventType in (2,3) and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = pu.PU_Desc, MTBF = Value1  
        From @FloatResults f 
        Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 ASC 
 	  	 Else If @EventType = 11 and @CauseReportLevel = 0 
      Select CauseId = Id, Cause = v.Var_Desc, MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 ASC 
    Else
      Select CauseId = Id, Cause = r.Event_Reason_Name, MTBF = Value1  
        From @FloatResults f 
        Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
  End
--*****************************************************
--*****************************************************
-- Return Location Resultsets
--*****************************************************
If @HasLocations = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Cause
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select LocationId, sum(Duration)
        From @MainSummaryTable
 	  	     Group By LocationId 
 	  	 
 	  	 If @EventType in (2,3)
      Select LocationId = Id, Location = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11
      Select LocationId = Id, Location = v.Var_Desc, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select LocationId = Id, Location = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	  	 -- Return MTTR, MTTA
 	  	 DELETE FROM  @FloatResults
 	  	 Insert Into @FloatResults (Id, Value1, Value2)
 	  	   Select LocationId, avg(TimeToRepair), avg(TimeToAck) / 60.0
        From @MainSummaryTable
 	  	     Group By LocationId 
 	  	 
 	  	 If @EventType in (2,3)
      Select LocationId = Id, Location = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11
      Select LocationId = Id, Location = v.Var_Desc, MTTR = Value1, MTTA = Value2   
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select LocationId = Id, Location = case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	 
 	  	 
 	  	 -- Return #Occurances
 	  	 DELETE FROM  @IntegerResults
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select LocationId, count(Timestamp)
        From @MainSummaryTable
 	  	     Group By LocationId 
 	  	 
 	  	 If @EventType in (2,3)
      Select LocationId = Id, Location = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Prod_Units pu on pu.PU_id = i.Id
        Order By Value DESC 
 	  	 Else If @EventType = 11
      Select LocationId = Id, Location = v.Var_Desc, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Variables v on v.Var_id = i.Id
        Order By Value DESC 
    Else
      Select LocationId = Id, Location = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
        Order By Value DESC 
 	  	 
 	  	 -- Return MTBF
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select LocationId, avg(TimePreviousFailure)
        From @MainSummaryTable
 	  	     Group By LocationId 
 	  	 
 	  	 If @EventType in (2,3)
      Select LocationId = Id, Location = pu.PU_Desc, MTBF = Value1  
        From @FloatResults f 
        Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 ASC 
 	  	 Else If @EventType = 11
      Select LocationId = Id, Location = v.Var_Desc, MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 ASC 
    Else
      Select LocationId = Id, Location = r.Event_Reason_Name, MTBF = Value1  
        From @FloatResults f 
        Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
  End
--*****************************************************
--*****************************************************
-- Return Category Resultsets
--*****************************************************
If @HasCategories = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select CategoryId, sum(Duration)
        From @MainSummaryTable
 	  	     Group By CategoryId 
      Select CategoryId = Id, Category = Case When Id Is Null Then @sUnspecified Else c.ERC_Desc End, PercentTotal = CASE WHEN @Total = 0 Then 0.0 ELSE  Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Event_Reason_catagories c on c.ERC_Id = f.Id
        Order By Value1 DESC 
 	  	 -- Return MTTR, MTTA
 	  	 DELETE FROM  @FloatResults
 	  	 Insert Into @FloatResults (Id, Value1, Value2)
 	  	   Select CategoryId, avg(TimeToRepair), avg(TimeToAck) / 60.0
        From @MainSummaryTable
 	  	     Group By CategoryId 
 	  	 
      Select CategoryId = Id, Category = Case When Id Is Null Then @sUnspecified Else c.ERC_Desc End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Event_Reason_catagories c on c.ERC_Id = f.[Id]
        Order By Value1 DESC 
 	 
 	  	 
 	  	 -- Return #Occurances
 	  	 DELETE FROM  @IntegerResults
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select CategoryId, count(Timestamp)
        From @MainSummaryTable
 	  	     Group By CategoryId 
 	  	 
      Select CategoryId = Id, Category = Case When Id Is Null Then @sUnspecified Else c.ERC_Desc End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reason_catagories c on c.ERC_Id = i.Id
        Order By Value DESC 
 	  	 
 	  	 -- Return MTBF
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select CategoryId, avg(TimePreviousFailure)
        From @MainSummaryTable
 	  	     Group By CategoryId 
      Select CategoryId = Id, Category = Case When Id Is Null Then @sUnspecified Else c.ERC_Desc End, MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Event_Reason_catagories c on c.ERC_Id = f.Id
        Order By Value1 ASC 
 	  	   
  End
--*****************************************************
--*****************************************************
-- Return Unit Resultsets
--*****************************************************
If @HasUnits = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
 	  	 
 	  	 -- Return % Cause
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select UnitId, sum(Duration)
        From @MainSummaryTable
 	  	     Group By UnitId 
 	  	 
 	  	 If @EventType in (2,3)
      Select UnitId = Id, Unit = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11
      Select UnitId = Id, Unit = v.Var_Desc, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select UnitId = Id, Unit = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, PercentTotal = CASE WHEN @Total = 0 THEN 0.0 ELSE Value1 / @Total * 100.0 END
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	  	 -- Return MTTR, MTTA
 	  	 DELETE FROM  @FloatResults
 	  	 Insert Into @FloatResults (Id, Value1, Value2)
 	  	   Select UnitId, avg(TimeToRepair), avg(TimeToAck) / 60.0
        From @MainSummaryTable
 	  	     Group By UnitId 
 	  	 
 	  	 If @EventType in (2,3)
      Select UnitId = Id, Unit = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 DESC 
 	  	 Else If @EventType = 11
      Select UnitId = Id, Unit = v.Var_Desc, MTTR = Value1, MTTA = Value2   
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 DESC 
    Else
      Select UnitId = Id, Unit = case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, MTTR = Value1, MTTA = Value2  
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 DESC 
 	 
 	  	 
 	  	 -- Return #Occurances
 	  	 DELETE FROM  @IntegerResults
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select UnitId, count(Timestamp)
        From @MainSummaryTable
 	  	     Group By UnitId 
 	  	 
 	  	 If @EventType in (2,3)
      Select UnitId = Id, Unit = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Prod_Units pu on pu.PU_id = i.Id
        Order By Value DESC 
 	  	 Else If @EventType = 11
      Select UnitId = Id, Unit = v.Var_Desc, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Variables v on v.Var_id = i.Id
        Order By Value DESC 
    Else
      Select UnitId = Id, Unit = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
        Order By Value DESC 
 	  	 
 	  	 -- Return MTBF
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select UnitId, avg(TimePreviousFailure)
        From @MainSummaryTable
 	  	     Group By UnitId 
 	  	 
 	  	 If @EventType in (2,3)
      Select UnitId = Id, Unit = pu.PU_Desc, MTBF = Value1  
        From @FloatResults f 
        Join Prod_Units pu on pu.PU_id = f.Id
        Order By Value1 ASC 
 	  	 Else If @EventType = 11
      Select UnitId = Id, Unit = v.Var_Desc, MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Variables v on v.Var_id = f.Id
        Order By Value1 ASC 
    Else
      Select UnitId = Id, Unit = r.Event_Reason_Name, MTBF = Value1  
        From @FloatResults f 
        Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
  End
--*****************************************************
--*****************************************************
-- Return Action Resultsets
--*****************************************************
If @HasAction = 1 
  Begin
 	  	 Select @Total = Count(Timestamp) From @MainSummaryTable
 	  	 
 	  	 -- Return % Actions
 	  	 DELETE FROM  @IntegerResults
 	  	 
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select ActionId, Count(Timestamp)
        From @MainSummaryTable
 	  	     Group By ActionId 
 	  	 
    Select ActionId = Id, Action = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, PercentTotal = Case When @Total > 0 Then Value / @Total * 100.0 Else 100.0 End   
      From @IntegerResults i 
      Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
      Order By Value DESC 
 	  	 -- Return MTTR, MTTA
 	  	 DELETE FROM  @FloatResults
 	  	 Insert Into @FloatResults (Id, Value1, Value2)
 	  	   Select ActionId, avg(TimeToRepair), avg(TimeToAck) / 60.0
        From @MainSummaryTable
 	  	     Group By ActionId 
 	  	 
    Select ActionId = Id, Action = case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, MTTR = Value1, MTTA = Value2  
      From @FloatResults f 
      Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
      Order By Value1 DESC 
 	  	 -- Return #Occurances
 	  	 DELETE FROM  @IntegerResults
 	  	 Insert Into @IntegerResults (Id, Value)
 	  	   Select ActionId, count(Timestamp)
        From @MainSummaryTable
 	  	     Group By ActionId 
 	  	 
 	  	 If @EventType = 11
 	  	  	 Select ActionId = Id, [Action] = Coalesce(r.Event_Reason_Name, @sUnspecified), Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
        Order By Value DESC 
 	  	 Else
      Select ActionId = Id, [Action] = Coalesce(r.Event_Reason_Name, @sUnspecified), Occurances = Value  
        From @IntegerResults i 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = i.Id
        Order By [Value] DESC 
 	  	 
 	  	 -- Return MTBF
 	  	 DELETE FROM  @FloatResults
 	  	 
 	  	 Insert Into @FloatResults (Id, Value1)
 	  	   Select ActionId, avg(TimePreviousFailure)
        From @MainSummaryTable
 	  	     Group By ActionId 
 	  	 
 	  	 If @EventType in (2,3)
      Select ActionId = Id, [Action] = Coalesce(r.Event_Reason_Name, @sUnspecified), MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
 	  	 Else If @EventType = 11
      Select ActionId = Id, [Action] = Coalesce(r.Event_Reason_Name, @sUnspecified), MTBF = Value1  
        From @FloatResults f 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
    Else
      Select ActionId = Id, [Action] = Coalesce(r.Event_Reason_Name, @sUnspecified), MTBF = Value1  
        From @FloatResults f 
        Join Event_Reasons r on r.Event_Reason_id = f.Id
        Order By Value1 ASC 
 	 End
--*****************************************************
-- Return non-produtive time Resultsets
--*****************************************************
If @HasNPTime = 1
 	 Begin
 	  	 --Note: these charts are reporting on non-productive time for the entire reporting range,
 	  	 --not just that which occurred during the event that is being analyzed
 	  	 Declare @TotalMinutes Float
 	  	 Declare @NPMinutes Float
 	  	 Set @TotalMinutes = Datediff(second, @StartTime, @EndTime) / 60.0
 	  	 Select @NPMinutes = Sum(Datediff(second, dbo.fnGetHigherDate(npd.Start_Time, @StartTime), dbo.fnGetLowerDate(npd.End_Time, @EndTime)) / 60.0)
 	  	 From NonProductive_Detail npd
 	  	 Where npd.PU_Id = @@UnitId
 	  	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	  	 --Print Cast(@NPMinutes As nvarchar(10)) + ' Minutes of non-productive time'
 	  	 --Generate the pie chart that breaks down the non-productive reasons by time
 	  	 Select ertd.Event_Reason_Id 'Id', Coalesce(Event_Reason_Name, @sUnspecified) 'Label',
 	  	  	  	  	 [Value] = CASE WHEN @NPMinutes = 0 THEN 0.0 ELSE (Sum(Datediff(second, dbo.fnGetHigherDate(npd.Start_Time, @StartTime), dbo.fnGetLowerDate(npd.End_Time, @EndTime)) / 60.0) / @NPMinutes) * 100 END
 	  	 From NonProductive_Detail npd
 	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	 Where npd.PU_Id = @@UnitId
 	  	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	  	 Group By ertd.Event_Reason_Id, Event_Reason_Name
 	  	 --Generate the pie chart that breaks down the productive and non-productive by time
 	  	 Declare @NPBreakdown Table
 	  	 (
 	  	  	 Label nvarchar(1000),
 	  	  	 Value Float
 	  	 )
 	  	 Insert Into @NPBreakDown (Label,Value)
 	  	  	 SELECT 'Productive', [Value] = CASE WHEN @TotalMinutes = 0 THEN 0.0 ELSE ((@TotalMinutes - @NPMinutes) / @TotalMinutes) * 100 END
 	  	 Insert Into @NPBreakDown 
 	  	  	 SELECT 'Non-Prod',[Value] = CASE WHEN @TotalMinutes = 0 THEN 0.0 ELSE  (@NPMinutes / @TotalMinutes) * 100 END
 	  	 Select * From @NPBreakdown
 	 
 	  	 --Generate the paraeto will have the number of occurences of each reason for non-productive time
 	  	 Select ertd.Event_Reason_Id 'Id', Coalesce(er.Event_Reason_Name, @sUnspecified) 'Label', Count(*) 'Occurances'
 	  	 From NonProductive_Detail npd
 	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	 Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
 	  	 Where npd.PU_Id = @@UnitId
 	  	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
 	  	 Group By ertd.Event_Reason_Id, er.Event_Reason_Name
 	 End
--*****************************************************
-- Return Capability Resultsets
--*****************************************************
If @HasCapability = 1 
  Begin
    -- Determine TTR Min and Max, Bucketsize
    Select @Min = min(TimeToRepair), @Max = max(TimeToRepair), @Avg = Avg(TimeToRepair), @Std = stdev(TimeToRepair), @Total = Count(Timestamp)
      From @MainSummaryTable
 	  	 -- Calculate the bucket size based on the fact that we want 3 buckets / standard deviation
    Select @Bucketsize = @Std / 3.0
 	  	 -- Calculate how many buckets we'll have based range of data available
    Select @CapabilityBuckets = CASE WHEN @Bucketsize = 0 Then 0 ELSE convert(int, (@Max - @Min) / @Bucketsize) + 1 END    
 	  	 -- Update Bucket#
    Update @MainSummaryTable Set BucketRepair = CASE WHEN @Bucketsize = 0 Then 0 ELSE convert(int, (TimeToRepair - @Min) / @BucketSize) END 
    -- Return MTTR Statistics
    Select Average = @Avg, StandardDeviation = @Std, Minimum = @Min, Maximum = @Max, Total = @Total, 
           LowerReject = (@Avg - (3 * @Std)), LowerWarning = (@Avg - (2 * @Std)), Target = @Avg, UpperWarning = (@Avg + (2 * @Std)), UpperReject = (@Avg + (3 * @Std)), BucketSize = @BucketSize, NumberOfBuckets = @CapabilityBuckets 
    -- Return MTTR Capability
    Select Bucket = BucketRepair, XValue = (@Min + ((BucketRepair + 1) * @BucketSize)), YValue = count(timestamp)
      From @MainSummaryTable
      Group By BucketRepair
      Order by BucketRepair
    -- Determine TBF Min and Max, Bucketsize
    Select @Min = min(TimePreviousFailure), @Max = max(TimePreviousFailure), @Avg = Avg(TimePreviousFailure), @Std = stdev(TimePreviousFailure), @Total = Count(Timestamp)
      From @MainSummaryTable
      Where TimePreviousFailure Is Not Null 
    Select @Bucketsize = @Std / 3.0
    Select @CapabilityBuckets = CASE WHEN @Bucketsize = 0 Then 0 ELSE convert(int, (@Max - @Min) / @Bucketsize) + 1 END
 	  	 -- Update Bucket#
    Update @MainSummaryTable Set BucketFailure = CASE WHEN @Bucketsize = 0 Then 0 ELSE convert(int, (TimePreviousFailure - @Min) / @BucketSize) END
    -- Return MTBF Statistics
    Select Average = @Avg, StandardDeviation = @Std, Minimum = @Min, Maximum = @Max , Total = @Total, 
           LowerReject = (@Avg - (3 * @Std)), LowerWarning = (@Avg - (2 * @Std)), Target = @Avg, UpperWarning = (@Avg + (2 * @Std)), UpperReject = (@Avg + (3 * @Std)), BucketSize = @BucketSize , NumberOfBuckets = @CapabilityBuckets    
    -- Return MTBF Capability
    Select Bucket = BucketFailure, XValue = (@Min + ((BucketFailure + 1) * @BucketSize)), YValue = count(timestamp)
      From @MainSummaryTable
      Where TimePreviousFailure Is Not Null 
      Group By BucketFailure
      Order by BucketFailure
 	 End
--*****************************************************
--*****************************************************
-- Return Trend Resultsets
--*****************************************************
If @HasTrends = 1 
  Begin
 	  	 Declare @HasTrendData bit
 	 
    -- Calculate Time Buckets
    Select @BucketSize = CASE WHEN @NumberOfIntervals = 0 Then 0 ELSE datediff(second,@StartTime, @EndTime) / @NumberOfIntervals END
 	  	 If @BucketSize = 0
     	 Set @HasTrendData = 0
 	  	 Else
 	  	  	 Set @HasTrendData = 1
    Update @MainSummaryTable Set BucketTime = CASE WHEN @Bucketsize = 0 Then 0 ELSE convert(int, datediff(second,@StartTime, Timestamp) / @BucketSize) END
    -- Return Total Time Trend
    Select Bucket = BucketTime, Timestamp = dateadd(second, convert(int, (BucketTime + 1) * @BucketSize), @StartTime), YValue = sum(Duration)
      From @MainSummaryTable
 	  	  	 Where @HasTrendData = 1
      Group By BucketTime
      Order by BucketTime
 	  	  	 
    -- Return MTBF Trend
    Select Bucket = BucketTime, Timestamp = dateadd(second, convert(int, (BucketTime + 1) * @BucketSize), @StartTime), YValue = avg(TimePreviousFailure)
      From @MainSummaryTable
      Where TimePreviousFailure Is Not Null 
 	  	  	 And @HasTrendData = 1
      Group By BucketTime
      Order by BucketTime
    -- Return MTTR Trend
    Select Bucket = BucketTime, Timestamp = dateadd(second, convert(int, (BucketTime + 1) * @BucketSize), @StartTime), YValue = avg(TimeToRepair)
      From @MainSummaryTable
 	  	  	 Where @HasTrendData = 1
      Group By BucketTime
      Order by BucketTime
    If @IsAcknowledged = 1
      Begin
 	  	     -- Return MTTA Trend
 	  	     Select Bucket = BucketTime, Timestamp = dateadd(second, convert(int, (BucketTime + 1) * @BucketSize), @StartTime), YValue = avg(TimeToAck) / 60.0
 	  	       From @MainSummaryTable
 	  	  	  	  	 Where @HasTrendData = 1
 	  	       Group By BucketTime
 	  	       Order by BucketTime
  	  	  	 End
 	 End
--*****************************************************
--*****************************************************
-- Return Summary Resultsets
--*****************************************************
If @HasSummary = 1 
  Begin
 	  	 Select @Total = sum(Duration) From @MainSummaryTable
    DECLARE  @Report Table(
      Id  	  	 int NULL, 
      Total real NULL,
      MTBF 	 real NULL,
  	  	  	 MTTR 	 real NULL,
 	  	  	 MTTA 	 real NULL,
      STBF 	 real NULL,
  	  	  	 STTR 	 real NULL,
  	  	  	 STTA 	 real NULL,
      Occurances int NULL
    )   
    Insert Into @Report
      Select CauseId, Sum(Duration) , Avg(TimePreviousFailure), Avg(TimeToRepair), Avg(TimeToAck) / 60.0, Stdev(TimePreviousFailure) , Stdev(TimeToRepair), Stdev(TimeToAck) / 60.0, Count(Timestamp)      
      From @MainSummaryTable
      Group By CauseId
 	 Declare @SummaryTable Table
 	  	 (Cause nVarchar(500),  	  	 
 	  	 Id 	 int NULL, 
 	  	 Total real NULL,
 	  	 MTBF 	 real NULL,
  	  	 MTTR 	 real NULL,
 	  	 MTTA 	 real NULL,
 	  	 STBF 	 real NULL,
  	  	 STTR 	 real NULL,
  	  	 STTA 	 real NULL,
 	  	 Occurances int NULL,
 	  	 PercentTotal float,
 	  	 PercentFault Float,
 	  	 IncrementalTBF float, 	 
 	  	 IncrementalTTR float)
 	 If @EventType = 2 and @CauseReportLevel = 0 
 	  	 Insert Into @SummaryTable
 	  	 Select Cause = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End,  d.*,
             PercentTotal = CASE WHEN @Total = 0 Then 0.0 ELSE Total  / convert(real, @TotalOperatingTime / 60.0) * 100.0 END, PercentFault = CASE WHEN @Total = 0 Then 0.0 ELSE Total / @Total * 100.0 END, 
             IncrementalTBF = CASE WHEN @Total = 0 Then 0.0 ELSE (STBF * Occurances) / @Total * 100.0 END, IncrementalTTR = CASE WHEN @Total = 0 Then 0.0 ELSE (STTR * Occurances) / @Total * 100.0 END
        From @Report d 
        Left Outer Join Prod_Units pu on pu.PU_id = d.Id
        Order By Total DESC
 	 Else If @EventType = 3 and @CauseReportLevel = 0 
 	  	 Insert Into @SummaryTable
 	  	 Select Cause = Case When Id Is Null Then @sUnspecified Else pu.PU_Desc End,  d.*,
             PercentTotal = CASE WHEN @Total = 0 Then 0.0 ELSE Total  / @TotalProduction * 100.0 END , PercentFault = CASE WHEN @Total = 0 Then 0.0 ELSE Total / @Total * 100.0 END, 
             IncrementalTBF = CASE WHEN @Total = 0 Then 0.0 ELSE (STBF * Occurances) / @Total * 100.0 END, IncrementalTTR = CASE WHEN @Total = 0 Then 0.0 ELSE (STTR * Occurances) / @Total * 100.0 END
        From @Report d 
        Left Outer Join Prod_Units pu on pu.PU_id = d.Id
        Order By Total DESC 
 	 Else If @EventType = 11 and @CauseReportLevel = 0 
 	  	 Insert Into @SummaryTable
 	  	 Select Cause = v.Var_Desc,  d.*,
             PercentTotal = CASE WHEN @Total = 0 Then 0.0 ELSE Total / convert(real, @TotalOperatingTime / 60.0) * 100.0 END, PercentFault = CASE WHEN @Total = 0 Then 0.0 ELSE Total / @Total * 100.0 END, 
             IncrementalTBF = CASE WHEN @Total = 0 Then 0.0 ELSE (STBF * Occurances) / @Total * 100.0 END, IncrementalTTR = CASE WHEN @Total = 0 Then 0.0 ELSE (STTR * Occurances) / @Total * 100.0 END
        From @Report d 
        Left Outer Join Variables v on v.Var_id = d.Id  and v.Pu_Id <> 0
        Order By Total DESC 
    Else If @EventType = 3
 	  	 Insert Into @SummaryTable
 	  	 Select Cause = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, d.*,  
             PercentTotal = CASE WHEN @TotalProduction = 0 Then 0.0 ELSE Total  / @TotalProduction * 100.0 END, PercentFault = CASE WHEN @Total = 0 Then 0.0 ELSE Total  / @Total * 100.0 END, 
             IncrementalTBF = CASE WHEN @Total = 0 Then 0.0 ELSE (STBF * Occurances) / @Total * 100.0 END, IncrementalTTR = CASE WHEN @Total = 0 Then 0.0 ELSE (STTR * Occurances) / @Total * 100.0 ENd
        From @Report d 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = d.Id
        Order By Total DESC 
    Else
 	  	 Insert Into @SummaryTable
 	  	 Select Cause = Case When Id Is Null Then @sUnspecified Else r.Event_Reason_Name End, d.*,  
             PercentTotal = Total  / convert(real, @TotalOperatingTime / 60.0) * 100.0, PercentFault = CASE WHEN @Total = 0 Then 0.0 ELSE Total  / @Total * 100.0 END, 
             IncrementalTBF = CASE WHEN @Total = 0 Then 0.0 ELSE (STBF * Occurances) / @Total * 100.0 END, IncrementalTTR = CASE WHEN @Total = 0 Then 0.0 ELSE (STTR * Occurances) / @Total * 100.0 END
        From @Report d 
        Left Outer Join Event_Reasons r on r.Event_Reason_id = d.Id
        Order By Total DESC 
 	 Insert Into @SummaryTable
 	 Select dbo.fnDBTranslate(@LangId, 35280, 'Totals'), Null, Sum(Total), Null, Null, Null, Null, Null, Null, Sum(Occurances), Sum(PercentTotal), Sum(PercentFault), Null, Null
 	 From @SummaryTable
 	 Select * From @SummaryTable
 	 End
--*****************************************************
--*****************************************************
-- Return Criteria Resultsets
--*****************************************************
If @HasCriteria = 1 
  Begin
    Declare @CriteriaNumber int
    Declare @ReasonName nVarChar(100)
    Select @CriteriaNumber = 0
    DECLARE @Criteria Table  (
      Id int,
      Name nvarchar(255),
      Description nvarchar(3000),
      Description_Parameter nvarchar(3000)
    )
    Select @CriteriaNumber = @CriteriaNumber + 1
    Insert Into @Criteria(Id, Name, Description)
      Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34567, 'Event Type'), @EventName)
    Select @CriteriaNumber = @CriteriaNumber + 1
    If @EventType in (2,3) and @CauseReportLevel = 0 
 	     Insert Into @Criteria(Id, Name, Description)
 	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34568, 'Cause Report Level'), dbo.fnDBTranslate(@LangId, 34569, 'Location'))
    Else If @EventType = 11 and @CauseReportLevel = 0 
 	     Insert Into @Criteria(Id, Name, Description)
 	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34568, 'Cause Report Level'), dbo.fnDBTranslate(@LangId, 34570, 'Variable'))
    Else
 	     Insert Into @Criteria(Id, Name, Description, Description_Parameter)
 	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34568, 'Cause Report Level'), dbo.fnDBTranslate(@LangId, 34571, 'Reason Level {0}'), @CauseReportLevel)
    If @CauseFilterLevel1 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @CauseFilterLevel1
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, 'Filter At Level 1', @ReasonName)
      End  
    If @CauseFilterLevel2 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @CauseFilterLevel2
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, 'Filter At Level 2', @ReasonName)
      End  
    If @CauseFilterLevel3 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @CauseFilterLevel3
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, 'Filter At Level 3', @ReasonName)
      End  
    If @CauseFilterLevel4 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @CauseFilterLevel4
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, 'Filter At Level 4', @ReasonName)
      End  
    Select @CriteriaNumber = @CriteriaNumber + 1
    Insert Into @Criteria(Id, Name, Description, Description_Parameter)
      Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34572, 'Action Report Level'), dbo.fnDBTranslate(@LangId, 34573, 'Action Level {0}'), @ActionReportLevel)
    If @ActionFilterLevel1 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @ActionFilterLevel1
 	  	     Insert Into @Criteria([Id], [Name], [Description])
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34575, 'Filter At Level 1'), @ReasonName)
      End  
    If @ActionFilterLevel2 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @ActionFilterLevel2
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34576, 'Filter At Level 2'), @ReasonName)
      End  
    If @ActionFilterLevel3 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @ActionFilterLevel3
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34577, 'Filter At Level 3'), @ReasonName)
      End  
    If @ActionFilterLevel4 Is Not Null
      Begin
 	  	     Select @CriteriaNumber = @CriteriaNumber + 1
        Select @ReasonName = Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @ActionFilterLevel4
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34578, 'Filter At Level 4'), @ReasonName)
      End  
    Select @CriteriaNumber = @CriteriaNumber + 1
    Insert Into @Criteria(Id, Name, Description)
      Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34579, 'Units Analyzed'), @UnitNameList)
    Select @CriteriaNumber = @CriteriaNumber + 1
    Insert Into @Criteria(Id, Name, Description, Description_Parameter)
      Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34580, 'Analysis Start Time'), '{0}',  dbo.fnServer_CmnConvertFromDBTime(@StartTime,@InTimeZone)  )
    Select @CriteriaNumber = @CriteriaNumber + 1
    Insert Into @Criteria(Id, Name, Description, Description_Parameter)
      Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34581, 'Analysis End Time'), '{0}',  dbo.fnServer_CmnConvertFromDBTime(@EndTime,@InTimeZone)  )
    Select @CriteriaNumber = @CriteriaNumber + 1
    If @Products Is Not Null
      Begin
 	  	  	  	 Declare Product_Cursor Insensitive Cursor 
 	  	  	  	   For Select Item From @ProductsTable 
 	  	  	  	   For Read Only
 	  	  	  	 
 	  	  	  	 Open Product_Cursor
 	  	  	  	 
 	  	  	  	 Fetch Next From Product_Cursor Into @@ProductId
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
 	  	  	  	 
 	  	  	  	     If @ProductNameList Is Null
 	  	  	  	       Select @ProductNameList = Prod_Code From Products Where Prod_Id = @@ProductId
 	  	  	  	     Else
 	  	  	  	       Select @ProductNameList = @ProductNameList + ', ' + (Select Prod_Code From Products Where Prod_Id = @@ProductId)
 	  	  	  	     Fetch Next From Product_Cursor Into @@ProductId
 	  	  	  	   End
 	  	  	  	 
 	  	  	  	 Close Product_Cursor
 	  	  	  	 Deallocate Product_Cursor  
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34582, 'Products Analyzed'), @ProductNameList)
      End
    Else
      Begin
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34582, 'Products Analyzed'), dbo.fnDBTranslate(@LangId, 34583, 'All Products'))
      End
 	  	 If @Variables Is Not Null
      Begin
 	  	  	  	 Declare @VariableNameList nvarchar(3000)
 	  	  	  	 Declare @@VariableId int
 	  	  	  	 Declare Variable_Cursor Insensitive Cursor 
 	  	  	  	   For Select Item From @VariablesTable 
 	  	  	  	   For Read Only
 	  	  	  	 
 	  	  	  	 Open Variable_Cursor
 	  	  	  	 
 	  	  	  	 Fetch Next From Variable_Cursor Into @@VariableId
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
 	  	  	  	 
 	  	  	  	     If @VariableNameList Is Null
 	  	  	  	       Select @VariableNameList = Var_Desc From Variables Where Var_Id = @@VariableId
 	  	  	  	     Else
 	  	  	  	       Select @VariableNameList = @VariableNameList + ', ' + (Select Var_Desc From Variables Where Var_Id = @@VariableId)
 	  	  	  	     Fetch Next From Variable_Cursor Into @@VariableId
 	  	  	  	   End
 	  	  	  	 
 	  	  	  	 Close Variable_Cursor
 	  	  	  	 Deallocate Variable_Cursor  
     	  	 Select @CriteriaNumber = @CriteriaNumber + 1
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 34584, 'Variables Analyzed'), @VariableNameList)
      End  	 
 	 If @CrewFilter Is Not Null
      Begin
     	  	 Select @CriteriaNumber = @CriteriaNumber + 1
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 35277, 'Crew Analyzed'), @CrewFilter)
      End 
 	 If @FaultFilter Is Not Null
      Begin
     	  	 Select @CriteriaNumber = @CriteriaNumber + 1
 	  	     Insert Into @Criteria(Id, Name, Description)
 	  	       Values (@CriteriaNumber, dbo.fnDBTranslate(@LangId, 35278, 'Fault Analyzed'), @FaultFilter)
      End 
 	  	 Select @CriteriaNumber = @CriteriaNumber + 1
 	  	 If @HasCategories = 1
 	  	  	 Begin
 	  	  	  	 DECLARE  @CategoryNamesTable Table 
 	  	  	  	 (
 	  	  	  	  	 [Name] nVarChar(1000)
 	  	  	  	 )
 	  	  	  	 Insert Into @CategoryNamesTable ([Name])
 	  	  	  	 Select ERC_Desc
 	  	  	  	 From Event_Reason_Catagories
 	  	  	  	 Where ERC_Id In (Select Item From @CategoryList)
 	  	  	  	 Declare @CategoryNames nVarChar(1000)
 	  	  	  	 Set @CategoryNames = ''
 	  	  	  	 Select @CategoryNames = @CategoryNames + [Name] + ', '
 	  	  	  	 From @CategoryNamesTable
 	  	  	 
 	  	  	  	 --Remove the final comma and space
 	  	  	  	 If Len(@CategoryNames) >= 1
 	  	  	  	  	 Set @CategoryNames = Substring(@CategoryNames, 1, Len(@CategoryNames) - 1)
 	  	  	  	  	 
 	  	  	  	 Insert Into @Criteria([Id], [Name], [Description])
 	  	  	  	 Values(@CriteriaNumber, dbo.fnDBTranslate(@LangId, 35230, 'Included Categories'), @CategoryNames)
 	  	  	 End
 	  	 If @FilterOutNPT Is Not Null And @FilterOutNPT = 1
 	  	  	 Insert Into @Criteria([Id], [Name], [Description])
 	  	  	  	 Values(@CriteriaNumber, dbo.fnDBTranslate(@LangId, 35231, 'Filtering Out Non-Productive Time'), dbo.fnDBTranslate(@LangId, 35232, 'True'))
 	  	 Else 	 
 	  	  	 Insert Into @Criteria([Id], [Name], [Description])
 	  	  	  	 Values(@CriteriaNumber, dbo.fnDBTranslate(@LangId, 35231, 'Filtering Out Non-Productive Time'), dbo.fnDBTranslate(@LangId, 35233, 'False'))
 	  	 Select * From @Criteria
      Order By ID
 	 End
--*****************************************************
--For Testing
--Select * From @MainSummaryTable
