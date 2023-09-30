CREATE procedure [dbo].[spASP_wrVariableConformance]
@ReportId int,
@RunId int = NULL
AS
--**************************************************/
/********************************************
set nocount on
Declare @ReportId int, @RunId int
Select @ReportId=41
--*******************************************/
set arithignore on
set arithabort off
set ansi_warnings off
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @Unit int
Declare @StartTime datetime
Declare @EndTime datetime
Declare @Variables varchar(7000)
Declare @Products varchar(7000)
Declare @Grouped int
Declare @IncludeRejects int 
Declare @SQL varchar(1000)
Declare @CPKMultiplier real
Declare @CPKWarningHigh real
Declare @CPKWarningLow real
Declare @CPKRejectHigh real
Declare @CPKRejectLow real
Declare @NonProductiveTimeFilter int
Declare @NPTLabel varchar(255)
Declare @NPTLabelDefault varchar(255)
Declare @LocaleId int, @LangId int
-- New Variable Statistics
Declare @USL REAL, @TGT REAL, @LSL REAL, @Mean Decimal(10,2), @Min REAL, @Max REAL
Declare @Pp REAL, @PpK REAL, @Ppu REAL, @Ppl REAL
Declare @Cp REAL, @CpK REAL, @Cpu REAL, @Cpl REAL
Declare @TargetTimeZone varchar(200)
Declare @NumberOfPoints int
declare @maxRecords bit
SET @maxRecords = 0
select @NPTLabelDefault = '(npt)'
if (Select Count(*) from Site_Parameters where parm_id = 316) = 0
  Select @NPTLabel=@NPTLabelDefault
Else
  select @NPTLabel = Coalesce(case Value when '' then @NPTLabelDefault else value end, @NPTLabelDefault) from Site_Parameters where parm_Id = 316
--TODO: Get CPK Warnings From Site Parameters
--TODO: Can we order the products any better (based on when run?)
--TODO: Add Language Prompts
--TODO: Recognize Requested Regional Settings
Select @CPKMultiplier = convert(real,Value) From Site_Parameters Where Parm_Id = 152
If @CPKMultiplier is Null Select @CPKMultiplier = 3.0
Select @CPKRejectHigh = 1.7
Select @CPKWarningHigh = 1.33
Select @CPKWarningLow = 1.33
Select @CPKRejectLow = 1.0
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
DECLARE @TimeOption int
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
--/**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Declare @ReturnValue varchar(7000)
SELECT 	 @ReturnValue = NULL
EXEC 	 spRS_GetReportParamValue 'LocaleId', @ReportId, @ReturnValue output
SELECT 	 @LocaleId = CASE @ReturnValue WHEN NULL THEN 0 ELSE abs(convert(INT, @ReturnValue)) END
SELECT @LangId = Language_id From Language_Locale_Conversion Where LocaleId=@LocaleId
If @LangId is Null SET @LangId = 0
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'NonProductiveTimeFilter', @ReportId, @ReturnValue output
Select @NonProductiveTimeFilter = ABS(Coalesce(convert(int,@ReturnValue), 0))
Select @ReportName = Report_Name From Report_Definitions Where Report_Id = @ReportId
If @ReportName Is Null
 	 Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36248, 'Variable Conformance')
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'MasterUnit', @ReportId, @ReturnValue output
Select @Unit = convert(int,@ReturnValue)
exec spRS_GetReportParamValue 'Products', @ReportId, @Products output
If @Products is Null
  Select @Products = '0'  -- Any Product
If LTrim(RTrim(@Products)) = ''
  Select @Products = '0'  -- Any Product
exec spRS_GetReportParamValue 'Variables', @ReportId, @Variables output
Select @TargetTimeZone = NULL  
exec spRS_GetReportParamValue 'TargetTimeZone', @ReportId,@TargetTimeZone output
SELECT @NumberOfPoints = NULL
EXEC 	 spRS_GetReportParamValue 'No_Of_DataPoints', @ReportId, @NumberOfPoints output  
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'TimeOption', @ReportId, @ReturnValue output 
Select @TimeOption = convert(int,@ReturnValue)
If @TimeOption = 0
     Begin
 	  	 Select @ReturnValue = NULL
 	  	 exec spRS_GetReportParamValue 'StartTime', @ReportId, @ReturnValue output
 	  	 Select @StartTime = convert(datetime, @ReturnValue)
 	  	 Select @ReturnValue = NULL
 	  	 exec spRS_GetReportParamValue 'EndTime', @ReportId, @ReturnValue output
 	  	 Select @EndTime = convert(datetime, @ReturnValue)
 	  END
 	  ELSE
 	  BEGIN
 	  	  Insert Into #TimeOptions 
          exec spRS_GetTimeOptions @TimeOption,@TargetTimeZone
          Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	  END
 Drop Table #TimeOptions
PRINT @StartTime
PRINT @EndTime
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'IsGrouped', @ReportId, @ReturnValue output
Select @Grouped = convert(int, @ReturnValue)
Select @ReturnValue = NULL
exec spRS_GetReportParamValue 'BrokeEventFilter', @ReportId, @ReturnValue output
Select @IncludeRejects = convert(int, @ReturnValue)
If @IncludeRejects = 1 
  Select @IncludeRejects = 0
Else
  Select @IncludeRejects = 1
SELECT @StartTime= [dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@TargetTimeZone)--Ramesh
SELECT @EndTime= [dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@TargetTimeZone)--Ramesh
PRINT @StartTime
PRINT @EndTime
--**********************************************
-- Check For Required Parameters And Set Defaults
--**********************************************
If @ReportName Is Null 
  Select @ReportName = dbo.fnRS_TranslateString_New(@LangId, 36248, 'Variable Conformance')
If @Unit Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [MasterUnit] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [MasterUnit] Parameter Is Missing',16,1)
    return
  End
If @Variables Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [Variables] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Variables] Parameter Is Missing',16,1)
    return
  End
If @StartTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [StartTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [StartTime] Parameter Is Missing',16,1)
    return
  End
If @EndTime Is Null
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Required [EndTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [EndTime] Parameter Is Missing',16,1)
    return
  End
--If @Products = '0'
--  Select @Products = NULL
If @Grouped Is Null 
  Select @Grouped = 0 
If @Grouped = -1
  Select @Grouped = 1
If @IncludeRejects Is Null 
  Select @IncludeRejects = 1
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @PromptRSReturned bit
Set @PromptRSReturned = 0
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(30),
  PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', dbo.fnRS_TranslateString_New(@LangId, 36178, 'Created') + ': ' + convert(varchar(25),dbo.fnServer_CmnConvertFromDbTime(dbo.fnServer_CmnGetDate(getutcdate()),@TargetTimeZone),120))
  	 
Insert into #Prompts (PromptName, PromptValue) Values ('Variable', dbo.fnRS_TranslateString_New(@LangId, 36163, 'Variable'))
Insert into #Prompts (PromptName, PromptValue) Values ('Average', dbo.fnRS_TranslateString_New(@LangId, 36182, 'Average'))
Insert into #Prompts (PromptName, PromptValue) Values ('StandardDeviation', dbo.fnRS_TranslateString_New(@LangId, 36250, 'Std'))
Insert into #Prompts (PromptName, PromptValue) Values ('Minimum', dbo.fnRS_TranslateString_New(@LangId, 36251, 'Min'))
Insert into #Prompts (PromptName, PromptValue) Values ('Maximum', dbo.fnRS_TranslateString_New(@LangId, 36252, 'Max'))
Insert into #Prompts (PromptName, PromptValue) Values ('ControlSummary', dbo.fnRS_TranslateString_New(@LangId, 36253, 'Control Summary'))
Insert into #Prompts (PromptName, PromptValue) Values ('Target', dbo.fnRS_TranslateString_New(@LangId, 36144, 'Target'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerReject', dbo.fnRS_TranslateString_New(@LangId, 36093, 'Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('LowerWarning', dbo.fnRS_TranslateString_New(@LangId, 36170, 'Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperWarning', dbo.fnRS_TranslateString_New(@LangId, 36170, 'Warning'))
Insert into #Prompts (PromptName, PromptValue) Values ('UpperReject', dbo.fnRS_TranslateString_New(@LangId, 36093, 'Reject'))
Insert into #Prompts (PromptName, PromptValue) Values ('CapabilitySummary', dbo.fnRS_TranslateString_New(@LangId, 36254, 'Capability'))
Insert into #Prompts (PromptName, PromptValue) Values ('CPK', dbo.fnRS_TranslateString_New(@LangId, 36255, 'CpK'))
Insert into #Prompts (PromptName, PromptValue) Values ('PPK', dbo.fnRS_TranslateString_New(@LangId, 36331, 'PpK'))
Insert into #Prompts (PromptName, PromptValue) Values ('StandardDeviationStandard', dbo.fnRS_TranslateString_New(@LangId, 36250, 'Std') + ' (s)')
Insert into #Prompts (PromptName, PromptValue) Values ('StandardDeviationTarget', dbo.fnRS_TranslateString_New(@LangId, 36250, 'Std') + ' (t)')
Insert into #Prompts (PromptName, PromptValue) Values ('SamplingSummary', dbo.fnRS_TranslateString_New(@LangId, 36256, 'Sampling'))
Insert into #Prompts (PromptName, PromptValue) Values ('Total', dbo.fnRS_TranslateString_New(@LangId, 36257, 'Total'))
Insert into #Prompts (PromptName, PromptValue) Values ('Tested', dbo.fnRS_TranslateString_New(@LangId, 36231, 'Tested'))
Insert into #Prompts (PromptName, PromptValue) Values ('Rejected', dbo.fnRS_TranslateString_New(@LangId, 36258, 'Rejected'))
Insert into #Prompts (PromptName, PromptValue) Values ('CommentsAvailable', dbo.fnRS_TranslateString_New(@LangId, 36021, 'Comments Available'))
Insert into #Prompts (PromptName, PromptValue) Values ('CPKRejectHigh', Convert(varchar(15),@CPKRejectHigh))
Insert into #Prompts (PromptName, PromptValue) Values ('CPKWarningHigh', Convert(varchar(15),@CPKWarningHigh))
Insert into #Prompts (PromptName, PromptValue) Values ('CPKWarningLow', Convert(varchar(15),@CPKWarningLow))
Insert into #Prompts (PromptName, PromptValue) Values ('CPKRejectLow', Convert(varchar(15),@CPKRejectLow))
Insert into #Prompts (PromptName, PromptValue) Values ('StartTime', Convert(varchar(30),dbo.fnServer_CmnConvertFromDBTime(@StartTime,@TargetTimeZone), 20))
Insert into #Prompts (PromptName, PromptValue) Values ('EndTime', Convert(varchar(30),dbo.fnServer_CmnConvertFromDBTime(@EndTime,@TargetTimeZone), 20))
Insert into #Prompts (PromptName, PromptValue) Values ('Comment', dbo.fnRS_TranslateString_New(@LangId, 36179, 'Comment'))
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@TargetTimeZone)
Insert into #Prompts (PromptName, PromptValue) Values ('No_Of_DataPoints',@NumberOfPoints)
-- Fix for the bug 36433 - moved this to end of the stored proc.
--SELECT * FROM #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
-- 2 Pages Per Product 
-- 1st Page Is Header Information
-- 2nd Page Is Specifications Order By Group
Declare @@ProductId int
Declare @@VariableId int
Create Table #Products(
 	 ProductId int
)
Create Table #Events (
  Timestamp datetime,
  IsGood int,
  ProductId int,
  IS_NPT int,
  End_Time datetime
)
Create Table #TimeEvents (
  Timestamp datetime,
  IsGood int,
  ProductId int,
  IS_NPT int
)
Create Table #Variables (
  ItemOrder int,
  Item int,
  Event_Type int,
  Unit int
)
-- test append
--print 'Appending additional variables...'
--Select @Variables = @Variables + ',49,50'
-- Insert variables into temp table
Insert Into #Variables (Item, ItemOrder)
  execute ('Select Distinct Var_Id, ItemOrder = CharIndex('',''+ convert(varchar(10),Var_Id) + '','',' + ''',' + @Variables + ','''+ ',1)  From Variables Where Var_Id in (' + @Variables + ')' + ' and data_type_id in (1,2,6,7) and pu_id <> 0')
Update O 
     Set unit = pu_id
     From Variables v
     Join #Variables O on O.Item = v.var_Id
if (select count(*) from #Variables where unit <> @unit) > 0
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'Variables Can Only Be Selected From One Unit', 2, @ReportId, @RunId
    Raiserror('Variables Can Only Be Selected From One Unit',16,1)
    return
  End
---------------------------------------------------------
-- Get The Event Type (Time Based=0, Event Based<>0)
---------------------------------------------------------
Declare @@Event_Type Int
Update O 
     Set o.Event_Type = p.Event_Type
     From Variables p 
     Join #Variables O on O.Item = P.Var_Id
Create Table #Report (
  Id int,
  Variable varchar(100),
  Units varchar(25) NULL,
  NumberOfDigits int NULL, 
  LRL varchar(25) NULL,
  LWL varchar(25) NULL,
  Target varchar(25) NULL,
  UWL varchar(25) NULL,
  URL varchar(25) NULL,
  Average real NULL,
  Minimum real NULL,
  Maximum real NULL,
  StandardDeviation real NULL,
  InRejectLow real NULL,
  InWarningLow real NULL,
  InTarget real NULL,
  InWarningHigh real NULL,
  InRejectHigh real NULL,
  NumberSamples int NULL,
  NumberTested int NULL,
  NumberRejects int NULL,
  StandardDeviationTarget real NULL,
  StandardDeviationMean real NULL,
  CoefficientVariationTarget real NULL,
  CoefficientVariationMean real NULL,
  PPK real NULL,  
  CPK real NULL,
  CommentCount int NULL
) 
Create Table #Data (
  Id int IDENTITY (1, 1),
  Value real NULL, 
  IsGood int, 
  IsTested int,
  LRL varchar(25) NULL,
  LWL varchar(25) NULL,
  Target varchar(25) NULL,
  UWL varchar(25) NULL,
  URL varchar(25) NULL,
  LimitIdentity varchar(150) NULL,
  InRejectLow int,
  InWarningLow int,
  InTarget int,
  InWarningHigh int,
  InRejectHigh int,
  TargetDeviation real NULL,
  IsComment int NULL
  , IS_NPT int
)
-------------------------------------------------------------------
-- Determin what products are being used for this time frame
-------------------------------------------------------------------
-- Check if any Time-Based variables have been selected
If (select count(*) from #Variables where Event_Type = 0) > 0
 	 Begin
 	  	 Print '== Time Based Variables Are Present =='
 	  	 Print 'Getting Products From Production_Starts'
 	  	 ------------------------------------------
 	  	 -- Time Based Variables
 	  	 ------------------------------------------
 	  	 Insert Into #Events (ProductId, IsGood, Timestamp, End_Time)
 	  	 select 
 	  	  	 Prod_Id, 1,
 	  	  	 [Start_Time] = Case When ps.Start_Time < @StartTime Then @StartTime Else ps.Start_Time End,
 	  	  	 [End_Time] = Case When ps.End_Time Is Null Then @EndTime
 	  	  	  	  	  	  	   When ps.End_Time > @EndTime Then @EndTime
 	  	  	  	  	  	  	   Else ps.End_Time END
 	  	 from production_Starts ps
 	  	 where ps.PU_ID=@Unit
 	  	 AND 
 	  	 (
 	  	  	  	 (ps.Start_Time >= @StartTime AND (ps.Start_Time < @EndTime))
 	  	  	 or
 	  	  	  	 (ps.Start_Time <= @StartTime AND ((ps.End_Time > @StartTime) or ps.End_Time Is Null))
 	  	 )
        -- Gets last production run if no records in #events
        If (select count(*)from #events) = 0
            Insert Into #Events (Timestamp, ProductId, IsGood)
            Select top 1 start_time, prod_id, 1 from Production_starts where pu_id = @Unit order by start_time desc            
 	  	 Update #Events Set Timestamp = @StartTime where Timestamp < @StartTime
 	  	 If (Select Count(*) From #Events) = 1
 	  	  	 Insert Into #Events(Timestamp, IsGood, ProductId)
 	  	  	  	 Select @EndTime, IsGood, ProductId From #Events
          	 
 	 End
--Else
 	 Begin
 	  	 Print '== Using Event Based Variables Only ==' 
 	  	 Print 'Getting Products From Events and Production_Starts'
 	  	 ------------------------------------------
 	  	 -- Event Based Variables
 	  	 ------------------------------------------
 	  	 If @IncludeRejects = 1  
 	  	   Insert Into #Events (Timestamp, ProductId, IsGood, IS_NPT)
 	  	     Select e.Timestamp, 
 	  	         Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	         Case When s.status_valid_for_input > 0 Then 1 Else 0 End,
 	  	  	  	 Case When e.Non_Productive_Seconds > 0 Then 1 Else 0 End
 	  	     From Events_NPT e
 	  	  	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	 and ps.Start_Time <= e.Timestamp 
 	  	  	  	  	 and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	 Join Production_Status s on s.ProdStatus_id = e.Event_Status 
 	  	     Where e.PU_id = @Unit 
 	  	  	  	 and e.Timestamp >  @StartTime 
 	  	  	  	 and e.Timestamp <= @EndTime 
 	  	  	  	 and (@NonProductiveTimeFilter = 0 or e.Non_Productive_Seconds = 0) 
 	  	  	 -- Changed
 	  	 Else
 	  	   Insert Into #Events (Timestamp, ProductId, IsGood, IS_NPT)
 	  	     Select e.Timestamp, 
 	  	         Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	         1,
 	  	  	  	 Case When e.Non_Productive_Seconds > 0 Then 1 Else 0 End
 	  	     From Events_NPT e
 	  	  	  	 Join Production_Starts ps on ps.PU_id = @Unit 
 	  	  	  	  	 and ps.Start_Time <= e.Timestamp 
 	  	  	  	  	 and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	 Join Production_Status s on s.ProdStatus_id = e.Event_Status and s.status_valid_for_input = 1
 	  	     Where e.PU_id = @Unit 
 	  	  	  	 and e.Timestamp >  @StartTime 
 	  	  	  	 and e.Timestamp <= @EndTime 
 	  	  	  	 and (@NonProductiveTimeFilter = 0 or e.Non_Productive_Seconds = 0) 
 	  	  	 -- Changed
 	 End
If LTrim(RTrim(@Products)) = '0'
    Print 'Any Product Run Will Be Used'
Else
    -- Purge The Products We Don't Want
    Execute ('Delete From #Events Where ProductId Not In (' + @Products + ')')
-- Verify that there are products to report on
If (Select Count(*) From #Events) = 0
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'There Are No Product Runs To Report On For Selected Time Range.  Try Changing Product Selection Or Choose [Any Product]', 2, @ReportId, @RunId
    Raiserror('There Are No Product Runs To Report On For Selected Time Range.  Try Changing Product Selection Or Choose [Any Product]',16,1)
    return
  End
Insert Into #Products
 	 Select ProductId From #Events
Insert Into #Products
 	 Select ProductId from #TimeEvents
Declare @MinTime datetime, @MaxTime datetime
Declare @GroupSize Int, @SampleCount Int, @MaxId INT
If @Grouped = 1 Goto IsGrouped
------------------------------------------------------------------------
-- Variable Is NOT Grouped LOOP
------------------------------------------------------------------------
Print 'Variable Is NOT Grouped - LOOP'
Declare Product_Cursor Insensitive Cursor 
  For (Select Distinct ProductId From #Products)
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
While @@Fetch_Status = 0
  Begin
    Declare Variable_Cursor Insensitive Cursor 
      For Select Item, Event_Type From #Variables Order By ItemOrder
      For Read Only
    Open Variable_Cursor
    Fetch Next From Variable_Cursor Into @@VariableId, @@Event_Type
    While @@Fetch_Status = 0
      Begin    
 	  	 If @@Event_Type = 0 
 	  	  	 Begin
 	  	  	  	 --------------------------------
 	  	  	  	 -- Time Based Variable
 	  	  	  	 -- Adds Is_NPT to the #Data table
 	  	  	  	 --------------------------------
 	  	  	  	 Select @MinTime = min(Timestamp) From #TimeEvents Where ProductId = @@ProductId                  
 	  	  	  	 Select @MaxTime = max(Timestamp) From #TimeEvents Where ProductId = @@ProductId                  
 	  	  	  	 Insert Into #Data(Value, IsGood, IsTested, LRL, LWL, Target, UWL, URL, LimitIdentity, InRejectLow, InWarningLow, InTarget, InWarningHigh, InRejectHigh, TargetDeviation, IsComment, IS_NPT)
 	  	  	  	  	 Select 
 	  	  	  	  	 t.Result,
 	  	  	  	  	 1,
 	  	  	  	  	 Case When t.Result Is Null Then 0 Else 1 End, 
 	  	  	  	  	 vs.l_reject, vs.l_warning, vs.target, vs.u_warning, vs.u_reject,
 	  	  	  	  	 coalesce(vs.l_reject, '*') + coalesce(vs.l_warning, '*') + coalesce(vs.target, '*')+ coalesce(vs.u_warning, '*')+ coalesce(vs.u_reject, '*'),
 	  	  	  	  	 Case 
 	  	  	  	  	  	 When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_reject) Then 1 
 	  	  	  	  	  	 When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_reject) Then 1 
 	  	  	  	  	  	 Else 0 
 	  	  	  	  	 End,
 	  	  	  	  	  	 Case 
 	  	  	  	  	  	  	 When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_warning) and not (convert(real,t.result) < convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
 	  	  	  	  	  	  	 When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_warning) and not (convert(real,t.result) <= convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
 	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	 0 
 	  	  	  	  	  	 End,
 	  	  	  	  	  	 InTarget = 1, 
 	  	  	  	  	  	 Case 
 	  	  	  	  	  	  	 When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_warning) and not (convert(real,t.result) >  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
 	  	  	  	  	  	  	 When @SpecificationSetting = 2 and convert(real,t.result) >=  convert(real,vs.u_warning) and not (convert(real,t.result) >=  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
 	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	 0 
 	  	  	  	  	  	 End,
 	  	  	  	  	  	 Case 
 	  	  	  	  	  	  	 When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_reject) Then 1 
 	  	  	  	  	  	  	 When @SpecificationSetting = 2 and convert(real,t.result) >  convert(real,vs.u_reject) Then 1 
 	  	  	  	  	  	 Else 
 	  	  	  	  	  	  	 0 
 	  	  	  	  	  	 End,
 	  	  	  	  	  	 convert(real,t.Result) - convert(real,vs.Target),
 	  	  	  	  	  	 Case When t.Comment_Id Is Not Null then 1 Else 0 end 
 	  	  	  	  	  	 ,t.Is_Non_Productive 	  	  	 
 	  	  	  	  	 From Tests_NPT t
 	  	  	  	  	  	 --Join #Variables iv on iv.item = t.var_id
 	  	  	  	  	  	 Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= t.result_on and ((ps.end_time > t.result_on) or (ps.end_time is null))
 	  	  	  	  	  	 Join Products p on p.Prod_Id = ps.prod_id
 	  	  	  	  	  	 Left Outer Join Var_Specs vs on vs.Var_Id = @@VariableId and vs.Prod_Id = ps.Prod_Id 
 	  	  	  	  	  	  	 and vs.effective_date <= t.result_on 
 	  	  	  	  	  	  	 and ((vs.expiration_date > t.result_on) or (vs.expiration_date is null))   	  	  	  	 
 	  	  	  	  	 Where t.var_Id = @@VariableId
 	  	  	  	  	  	 and IsNumeric(t.Result) = 1
 	  	  	  	  	  	 and t.result_on > @StartTime 
 	  	  	  	  	  	 and t.result_on <= @EndTime
 	  	  	  	  	  	 and ps.Prod_Id = @@ProductId
 	  	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0) 
 	  	  	  	 print 'Searching data for var_id ' + convert(varchar(5), @@VariableID)
 	  	  	 
 	  	  	  	 --Select @STartTime, @EndTime, @Unit
 	  	  	  	 --select * from #Data 	  	 
 	  	  	 End -- If @@Event_Type = 0
 	  	 Else
 	  	  	 Begin
 	  	  	  	 --------------------------------
 	  	  	  	 -- Event Based Variable
 	  	  	  	 -- Adds IS_NPT to the #Data table
 	  	  	  	 --------------------------------
 	  	  	  	 Select @MinTime = min(Timestamp) From #Events Where ProductId = @@ProductId                  
 	  	  	  	 Select @MaxTime = max(Timestamp) From #Events Where ProductId = @@ProductId                  
 	  	  	  	 Print 'inserting event based variable'
 	  	  	  	 Insert Into #Data(Value, IsGood, IsTested, LRL, LWL, Target, UWL, URL, LimitIdentity, InRejectLow, InWarningLow, InTarget, InWarningHigh, InRejectHigh, TargetDeviation, IsComment, IS_NPT)
 	  	  	  	   Select Value = convert(real,t.Result), IsGood = e.IsGood, IsTested = Case When t.Result Is Null Then 0 Else 1 End, 
 	  	  	  	  	  	  LRL = vs.l_reject, LWL = vs.l_warning, Target = vs.Target, UWL = vs.u_warning, URL = vs.u_reject,
 	  	  	  	  	  	  LimitIdentity = coalesce(vs.l_reject, '*') + coalesce(vs.l_warning, '*') + coalesce(vs.target, '*')+ coalesce(vs.u_warning, '*')+ coalesce(vs.u_reject, '*'),
 	  	  	  	  	  	  InRejectLow = Case 
 	  	  	  	  	  	  	  	  	  	  When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_reject) Then 1 
 	  	  	  	  	  	  	  	  	  	  When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_reject) Then 1 
 	  	  	  	  	  	  	  	  	  	  Else 0 
 	  	  	  	  	  	  	  	  	    End,
 	  	  	  	  	  	  InWarningLow = Case 
 	  	  	  	  	  	  	  	  	  	   When @SpecificationSetting = 1 and convert(real,t.result) < convert(real,vs.l_warning) and not (convert(real,t.result) < convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
 	  	  	  	  	  	  	  	  	  	   When @SpecificationSetting = 2 and convert(real,t.result) <= convert(real,vs.l_warning) and not (convert(real,t.result) <= convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 
 	  	  	  	  	  	  	  	  	  	   Else 0 
 	  	  	  	  	  	  	  	  	  	 End,
 	  	  	  	  	  	  InTarget = 1, 
 	  	  	  	  	  	  InWarningHigh = Case 
 	  	  	  	  	  	  	  	  	  	    When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_warning) and not (convert(real,t.result) >  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
 	  	  	  	  	  	  	  	  	  	    When @SpecificationSetting = 2 and convert(real,t.result) >=  convert(real,vs.u_warning) and not (convert(real,t.result) >=  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 
 	  	  	  	  	  	  	  	  	  	    Else 0 
 	  	  	  	  	  	  	  	  	  	  End,
 	  	  	  	  	  	  InRejectHigh = Case 
 	  	  	  	  	  	  	  	  	  	   When @SpecificationSetting = 1 and convert(real,t.result) >  convert(real,vs.u_reject) Then 1 
 	  	  	  	  	  	  	  	  	  	   When @SpecificationSetting = 2 and convert(real,t.result) >  convert(real,vs.u_reject) Then 1 
 	  	  	  	  	  	  	  	  	  	   Else 0 
 	  	  	  	  	  	  	  	  	  	 End,
 	  	  	  	  	  	  TargetDeviation = convert(real,t.Result) - convert(real,vs.Target),
 	  	  	  	  	  	  IsComment = Case When t.Comment_Id Is Not Null then 1 Else 0 end
 	  	  	  	  	  	  ,IS_NPT
 	  	  	  	  	 From #Events e
 	  	  	  	  	  	 Left Outer Join Tests t on t.Var_Id = @@VariableId and t.Result_On = e.Timestamp
 	  	  	  	  	  	 Left Outer Join Var_Specs vs on vs.Var_Id = @@VariableId and vs.Prod_Id = @@ProductId 
 	  	  	  	  	  	  	 and vs.effective_date <= e.Timestamp 
 	  	  	  	  	  	  	 and ((vs.expiration_date > e.Timestamp) or (vs.expiration_date is null))  
 	  	  	  	  	 Where e.ProductId = @@ProductId
 	  	  	  	  	 and (@NonProductiveTimeFilter = 0 or e.IS_NPT = 0) 
 	  	  	   -- Changed
 	   End
 	  	 --------------------------------------------------------------
 	  	 -- decide whether or not to drop a row based on sample size
 	  	 -- conditions:
 	  	 -- 1) SubGroups will be used for Cpk Calc AND
 	  	 -- 2) More than 1 subgroup exists AND
 	  	 -- 3) The last subgroup contains 1 sample value
 	  	 --------------------------------------------------------------
 	  	 -- Get Sample Size From Variables Table
 	  	 Select @GroupSize = Coalesce(CpK_Subgroup_Size, 1) From Variables Where Var_Id = @@VariableId
 	  	 Select @SampleCount = Count(*) From #Data
 	  	 If (@SampleCount / @GroupSize) > 1 and ((@SampleCount % @GroupSize) = 1)
 	  	  	 Begin
 	  	  	  	 select @MaxId= max(id) from #Data 
 	  	  	  	 delete from #Data where id = @MaxId
 	  	  	 End
 	  	 select @Ppk=Ppk, @Cpk=Cpk from fnCMN_GetVariableStatistics(@StartTime, @EndTime, @@VariableId, @@ProductId, @NonProductiveTimeFilter)
        -------------------------------------------------------------------                    
        -- Return This Variable's Results Into The Report
 	  	 -- This was changed to alter the variable name for NPT
 	  	 -------------------------------------------------------------------
        Insert Into #Report (Id,Variable,Units,NumberOfDigits, LRL,LWL,Target,UWL,URL,Average,Minimum,Maximum,StandardDeviation,InRejectLow,InWarningLow,InTarget,InWarningHigh,InRejectHigh,NumberSamples,NumberTested,NumberRejects,StandardDeviationTarget,StandardDeviationMean,CoefficientVariationTarget,CoefficientVariationMean, PPK, CPK, CommentCount)
 	  	  	 Select Id = @@VariableId, 
 	  	  	  	  	   Variable = (Select Var_Desc From Variables Where Var_Id = @@VariableId) + case when Sum(d.IS_NPT) > 0 then @NPTLabel else '' end,
 	  	  	  	  	   Units = (Select Eng_Units From Variables Where Var_Id = @@VariableId), 
 	  	  	  	  	   NumberOfDigits = Coalesce((Select Var_Precision From Variables Where Var_Id = @@VariableId),0),
                      LRL = min(d.LRL), LWL = min(d.LWL), Target = min(d.Target), UWL = min(d.UWL), URL = min(d.URL),
                      Average = avg(d.Value), Minimum = min(d.Value), Maximum = max(d.Value) ,StandardDeviation = ABS(stdev(d.Value)),
                      InRejectLow = sum(d.InRejectLow) / convert(real,Count(d.Value)) * 100.0,
                      InWarningLow = sum(d.InWarningLow) / convert(real,Count(d.Value)) * 100.0,
                      InTarget = (Count(d.Value) - sum(d.InRejectLow) - sum(d.InWarningLow) - sum(d.InWarningHigh) - sum(d.InRejectHigh)) / convert(real,Count(d.Value)) * 100.0,
                      InWarningHigh = sum(d.InWarningHigh) / convert(real,Count(d.Value)) * 100.0,
                      InRejectHigh= sum(d.InRejectHigh) / convert(real,Count(d.Value)) * 100.0,
                      NumberSamples = count(d.IsTested),
                      NumberTested = sum(d.IsTested),
                      NumberRejects = count(d.IsTested) - convert(int, sum(d.IsGood)),
                     -- StandardDeviationTarget = ABS(stdev(d.TargetDeviation)),
                     -- Fix for the RTS #39629: Standarad Deviation(Target) calculation is done with formula. Using Standard Deviation function from sql is giving a different value.
                      StandardDeviationTarget = ABS(Sqrt(Sum(d.TargetDeviation*d.TargetDeviation)/count(d.TargetDeviation))),
                      StandardDeviationMean = ABS(stdev(d.Value)),
                      CoefficientVariationTarget = ABS(stdev(d.TargetDeviation)) / min(convert(real,d.Target)) * 100.0,
                      CoefficientVariationMean = ABS(stdev(d.Value)) / avg(d.Value) * 100.0, 
 	  	  	  	  	   PPK=@PPK,
 	  	  	  	  	   CPK=@CPK,
 	  	  	  	  	   /*
                      CPK = Case 
                               When min(d.LRL) Is Not Null and min(d.URL) Is Not Null Then
                                   Case 
                                     When abs(convert(real,min(d.URL)) - avg(d.Value)) < abs(avg(d.Value) - convert(real,min(d.LRL))) Then
                                       abs(convert(real,min(d.URL)) - avg(d.Value)) / (@CPKMultiplier * ABS(stdev(d.Value))) 
                                     Else
                                       abs(avg(d.Value) - convert(real,min(d.LRL))) / (@CPKMultiplier * ABS(stdev(d.Value))) 
                                     End
                               When min(d.URL) Is Not Null Then 
                                  abs(convert(real,min(d.URL)) - avg(d.Value)) / (@CPKMultiplier * ABS(stdev(d.Value))) 
                               When min(d.LRL) Is Not Null Then 
                                  abs(avg(d.Value) - convert(real,min(d.LRL))) / (@CPKMultiplier * ABS(stdev(d.Value))) 
                               Else NULL 
                           End,
 	  	  	  	  	   */
                      CommentCount = sum(d.IsComment)
 	  	  	 From #Data d
 	  	  	 Group By d.LimitIdentity                              
        Truncate Table #Data 
        Fetch Next From Variable_Cursor Into @@VariableId, @@Event_Type
      End     
    Close Variable_Cursor
    Deallocate Variable_Cursor
  -- Fix for the bug 36433 - Variable Conformance & Spec By Variable Reports have bad formatting
-- Returning this boolean value true if the number of records exceeds 500 records.
If (Select Count(*) From #Report) > 500
BEGIN 
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36249, 'Quality Conformance For Unit') + ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
SELECT @CriteriaString  = @CriteriaString + '<br><i> Exceeded the Maximum number of records, Limiting the records to Top 500 records </i>'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
SET @maxRecords =1
END
ELSE
BEGIN
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36249, 'Quality Conformance For Unit') + ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
END
 	 if (@PromptRSReturned <> 1)
 	 Begin
 	  	 Set @PromptRSReturned = 1
 	  	 SELECT * From #Prompts
 	 End
    -- Return This Page Of Results
    Select Id = @@ProductId, Product = p.Prod_Code, Description = p.Prod_Desc, Comment = c.Comment_Text
      From Products p 
      Left Outer Join Comments c on c.Comment_id = p.Comment_id
      Where p.Prod_id = @@ProductId
 If(@maxRecords = 1)
 BEGIN
    Select Top 500 * From #Report r 
 	   join #Variables v on v.Item = r.Id
 	   order by v.ItemOrder
END
ELSE
BEGIN
 Select  * From #Report r 
 	   join #Variables v on v.Item = r.Id
 	   order by v.ItemOrder
END
    Truncate Table #Report
    Fetch Next From Product_Cursor Into @@ProductId
  End
Close Product_Cursor
Deallocate Product_Cursor  
Goto EndProcedure
------------------------------------------------------------------------
-- Variable Is Grouped LOOP
------------------------------------------------------------------------
IsGrouped:
Print 'Variable Is Grouped - LOOP'
Declare @ProductList varchar(1000)
Declare @FirstVariable int
Declare @FirstProduct int
Declare Variable_Cursor Insensitive Cursor 
  For Select Item, Event_Type From #Variables Order By ItemOrder
  For Read Only
Open Variable_Cursor
Fetch Next From Variable_Cursor Into @@VariableId, @@Event_Type
Select @FirstVariable = @@VariableId
Select @ProductList = ''
While @@Fetch_Status = 0
  Begin
    Declare Product_Cursor Insensitive Cursor 
      For (Select Distinct ProductId From #Events)
      For Read Only
    Open Product_Cursor
    Fetch Next From Product_Cursor Into @@ProductId
    If @FirstProduct Is Null
       Select @FirstProduct = @@ProductId
    While @@Fetch_Status = 0
      Begin
        If @@VariableId = @FirstVariable 
          Begin
            If len(@ProductList) = 0 
              Select @ProductList = (Select Prod_Code From Products Where Prod_Id = @@ProductId)
            Else
              Select @ProductList = @ProductList + ', ' + (Select Prod_Code From Products Where Prod_Id = @@ProductId)
          End
        Select @MinTime = min(Timestamp) From #Events Where ProductId = @@ProductId                  
        Select @MaxTime = max(Timestamp) From #Events Where ProductId = @@ProductId                  
 	 If @@Event_Type = 0 
 	   Begin
 	  	 --------------------------------
 	  	 -- Time Based Variable
 	  	 -- Adds IS_NPT to the #Data table
 	  	 --------------------------------
 	  	 Insert Into #Data(Value, IsGood, IsTested, LRL, LWL, Target, UWL, URL, LimitIdentity, InRejectLow, InWarningLow, InTarget, InWarningHigh, InRejectHigh, TargetDeviation, IsComment, IS_NPT)
 	  	     Select 
 	  	  	  	 t.Result,
 	  	  	  	 1,
 	  	  	  	 Case When t.Result Is Null Then 0 Else 1 End, 
 	  	  	  	 vs.l_reject, 
 	  	  	  	 vs.l_warning, 
 	  	  	  	 vs.target, 
 	  	  	  	 vs.u_warning, 
 	  	  	  	 vs.u_reject,
 	  	  	  	 Coalesce(vs.l_reject, '*') + coalesce(vs.l_warning, '*') + coalesce(vs.target, '*')+ coalesce(vs.u_warning, '*')+ coalesce(vs.u_reject, '*'),
 	  	  	  	 Case When convert(real,t.result) <  convert(real,vs.l_reject) Then 1 Else 0 End,
 	  	  	  	 Case When convert(real,t.result) < convert(real,vs.l_warning) and not (convert(real,t.result) <  convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 Else 0 End,
 	  	         InTarget = 1, 
 	  	  	  	 Case When convert(real,t.result) >  convert(real,vs.u_warning) and not (convert(real,t.result) >  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 Else 0 End,
 	  	  	  	 Case When convert(real,t.result) >  convert(real,vs.u_reject) Then 1 Else 0 End,
 	  	         Convert(real,t.Result) - convert(real,vs.Target),
 	  	         Case When t.Comment_Id Is Not Null then 1 Else 0 end
 	  	  	  	 ,t.Is_Non_Productive  	  	  	 
 	  	     From Tests_NPT t
 	  	  	  	 Join #Variables iv on iv.item = t.var_id
 	  	  	  	 Join production_starts ps on ps.pu_id = @Unit and ps.start_time <= t.result_on and ((ps.end_time > t.result_on) or (ps.end_time is null))
 	  	  	  	 Join Products p on p.Prod_Id = ps.prod_id
 	  	  	  	 Left Outer Join Var_Specs vs on vs.Var_Id = @@VariableId and vs.Prod_Id = ps.Prod_Id 
 	  	  	  	  	 and vs.effective_date <= t.result_on 
 	  	  	  	  	 and ((vs.expiration_date > t.result_on) or (vs.expiration_date is null))   	  	  	  	 
 	  	     Where t.var_Id = @@VariableId
 	  	  	  	 and IsNumeric(t.Result) = 1
 	  	  	  	 and t.result_on > @StartTime 
 	  	         and t.result_on <= @EndTime
 	   End
 	 Else
 	   Begin
 	  	 --------------------------------
 	  	 -- Event Based Variable
 	  	 --------------------------------
 	         Insert Into #Data(Value, IsGood, IsTested, LRL, LWL, Target, UWL, URL, LimitIdentity, InRejectLow, InWarningLow, InTarget, InWarningHigh, InRejectHigh, TargetDeviation, IsComment, IS_NPT)
 	  	  	  	 Select Value = convert(real,t.Result), 
 	  	  	  	  	 IsGood = e.IsGood, 
 	  	  	  	  	 IsTested = Case When t.Result Is Null Then 0 Else 1 End, 
 	                 LRL = vs.l_reject, LWL = vs.l_warning, Target = vs.Target, UWL = vs.u_warning, URL = vs.u_reject,
 	                 LimitIdentity = coalesce(vs.l_reject, '*') + coalesce(vs.l_warning, '*') + coalesce(vs.target, '*')+ coalesce(vs.u_warning, '*')+ coalesce(vs.u_reject, '*'),
 	                 InRejectLow = Case When convert(real,t.result) <  convert(real,vs.l_reject) Then 1 Else 0 End,
 	                 InWarningLow = Case When convert(real,t.result) < convert(real,vs.l_warning) and not (convert(real,t.result) <  convert(real,vs.l_reject) and vs.l_reject is not null) Then 1 Else 0 End,
 	                 InTarget = 1, --Case When convert(real,t.result) >= convert(real,coalesce(vs.l_warning,t.result)) and convert(real,t.result) > convert(real,coalesce(vs.l_reject,convert(real,t.result)-1.0)) and convert(real,t.result) <= convert(real,coalesce(vs.u_warning,t.result)) and convert(real,t.result) < convert(real,coalesce(vs.u_reject,convert(real,t.result)+1.0)) Then 1 Else 0 End,
 	                 InWarningHigh = Case When convert(real,t.result) >  convert(real,vs.u_warning) and not (convert(real,t.result) >  convert(real,vs.u_reject) and vs.u_reject is not null) Then 1 Else 0 End,
 	                 InRejectHigh = Case When convert(real,t.result) >  convert(real,vs.u_reject) Then 1 Else 0 End,
 	                 TargetDeviation = convert(real,t.Result) - convert(real,vs.Target),
 	                 IsComment = Case When t.Comment_Id Is Not Null then 1 Else 0 end 
 	  	  	  	  	 ,IS_NPT
 	  	  	  	 From #Events e
 	  	  	  	  	 Left Outer Join Tests t on t.Var_Id = @@VariableId 
 	  	  	  	  	  	 and t.Result_On = e.Timestamp
 	  	  	  	  	 Left Outer Join Var_Specs vs on vs.Var_Id = @@VariableId 
 	  	  	  	  	  	 and vs.Prod_Id = @@ProductId 
 	  	  	  	  	  	 and vs.effective_date <= e.Timestamp  
 	             Where e.ProductId = @@ProductId                
 	 
 	   End
        Fetch Next From Product_Cursor Into @@ProductId
      End     
 	  	 --------------------------------------------------------------
 	  	 -- decide whether or not to drop a row based on sample size
 	  	 -- conditions:
 	  	 -- 1) SubGroups will be used for Cpk Calc AND
 	  	 -- 2) More than 1 subgroup exists AND
 	  	 -- 3) The last subgroup contains 1 sample value
 	  	 --------------------------------------------------------------
 	  	 -- Get Sample Size From Variables Table
 	  	 Select @GroupSize = Coalesce(CpK_Subgroup_Size, 1) From Variables Where Var_Id = @@VariableId
 	  	 Select @SampleCount = Count(*) From #Data
 	  	 If (@SampleCount / @GroupSize) > 1 and ((@SampleCount % @GroupSize) = 1)
 	  	  	 Begin
 	  	  	  	 select @MaxId= max(id) from #Data 
 	  	  	  	 delete from #Data where id = @MaxId
 	  	  	 End
 	 select @Ppk=Ppk, @Cpk=Cpk from fnCMN_GetVariableStatistics(@StartTime, @EndTime, @@VariableId, @@ProductId, @NonProductiveTimeFilter)
    -------------------------------------------------------------------
    -- Return This Variable's Results Into The Report
 	 -- This was changed to alter the variable name for NPT
    -------------------------------------------------------------------
    Insert Into #Report (Id,Variable,Units,NumberOfDigits, LRL,LWL,Target,UWL,URL,Average,Minimum,Maximum,StandardDeviation,InRejectLow,InWarningLow,InTarget,InWarningHigh,InRejectHigh,NumberSamples,NumberTested,NumberRejects,StandardDeviationTarget,StandardDeviationMean,CoefficientVariationTarget,CoefficientVariationMean, PPK, CPK, CommentCount)
      Select Id = @@VariableId, 
 	  	  	 Variable = (Select Var_Desc From Variables Where Var_Id = @@VariableId) + case when Sum(d.IS_NPT) > 0 then @NPTLabel else '' end,
 	  	  	 Units = (Select Eng_Units From Variables Where Var_Id = @@VariableId), 
 	  	  	 NumberOfDigits = Coalesce((Select Var_Precision From Variables Where Var_Id = @@VariableId),0),
 	  	  	 LRL = min(d.LRL), LWL = min(d.LWL), Target = min(d.Target), UWL = min(d.UWL), URL = min(d.URL),
 	  	  	 Average = avg(d.Value), Minimum = min(d.Value), Maximum = max(d.Value) ,StandardDeviation = ABS(stdev(d.Value)),
 	  	  	 InRejectLow = sum(d.InRejectLow) / convert(real,Count(d.Value)) * 100.0,
 	  	  	 InWarningLow = sum(d.InWarningLow) / convert(real,Count(d.Value)) * 100.0,
 	  	  	 InTarget = (Count(d.Value) - sum(d.InRejectLow) - sum(d.InWarningLow) - sum(d.InWarningHigh) - sum(d.InRejectHigh)) / convert(real,Count(d.Value)) * 100.0,
 	  	  	 InWarningHigh = sum(d.InWarningHigh) / convert(real,Count(d.Value)) * 100.0,
 	  	  	 InRejectHigh= sum(d.InRejectHigh) / convert(real,Count(d.Value)) * 100.0,
 	  	  	 NumberSamples = count(d.IsTested),
 	  	  	 NumberTested = sum(d.IsTested),
 	  	  	 NumberRejects = count(d.IsTested) - convert(int, sum(d.IsGood)),
 	  	  	 StandardDeviationTarget = ABS(stdev(d.TargetDeviation)),
 	  	  	 StandardDeviationMean = ABS(stdev(d.Value)),
 	  	  	 CoefficientVariationTarget = ABS(stdev(d.TargetDeviation)) / min(convert(real,d.Target)) * 100.0,
 	  	  	 CoefficientVariationMean = ABS(stdev(d.Value)) / avg(d.Value) * 100.0, 
 	  	  	 PPK=@PPK,
 	  	  	 CPK=@CPK,
 	  	  	 /*
 	  	  	 CPK = Case 
 	  	  	  	   When min(d.LRL) Is Not Null and min(d.URL) Is Not Null Then 
 	  	  	  	  	 (convert(real,min(d.URL)) - convert(real,min(d.LRL))) / (2.0 * @CPKMultiplier * ABS(stdev(d.Value))) 
 	  	  	  	   When min(d.URL) Is Not Null and min(d.Target) Is Not Null Then 
 	  	  	  	  	 (convert(real,min(d.URL)) - convert(real,min(d.Target))) / (@CPKMultiplier * ABS(stdev(d.Value))) 
 	  	  	  	   When min(d.LRL) Is Not Null and min(d.Target) Is Not Null Then 
 	  	  	  	  	 (convert(real,min(d.Target)) - convert(real,min(d.LRL))) / (@CPKMultiplier * ABS(stdev(d.Value))) 
 	  	  	  	   Else NULL 
 	  	  	  	 End,
 	  	  	 */
            CommentCount = sum(d.IsComment)
      From #Data d
      Group By d.LimitIdentity                                    
    Truncate Table #Data 
    Close Product_Cursor
    Deallocate Product_Cursor  
    Fetch Next From Variable_Cursor Into @@VariableId, @@Event_Type
  End
Close Variable_Cursor
Deallocate Variable_Cursor
-------------------------------------------------------------------
-- Return The Report
-------------------------------------------------------------------
-- Fix for the bug 36433 - Variable Conformance & Spec By Variable Reports have bad formatting
-- Returning this boolean value true if the number of records exceeds 500 records.
If (Select Count(*) From #Report) > 500
BEGIN 
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36249, 'Quality Conformance For Unit') + ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
SELECT @CriteriaString  = @CriteriaString + '<br><i> Exceeded the Maximum number of records, Limiting the records to Top 500 records </i>'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
SET @maxRecords =1
END
ELSE
BEGIN
Select @CriteriaString = dbo.fnRS_TranslateString_New(@LangId, 36249, 'Quality Conformance For Unit') + ': ' + (Select PU_Desc From Prod_Units Where PU_Id = @Unit)
Select @CriteriaString = @CriteriaString + 
 	 Case 
 	  	 When @NonProductiveTimeFilter=0 Then '<br><i>' + @NPTLabel + ' ' + dbo.fnRS_TranslateString_New(@LangId, 36026, 'Contains') + ' ' + dbo.fnRS_TranslateString_New(@LangId, 42120, 'Non-Productive Time') + '</i>' Else '<br><i>' + dbo.fnRS_TranslateString_New(@LangId, 35193, 'Non-Productive Time Removed') + '</i>' 
 	 End
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
END
 	 if (@PromptRSReturned <> 1)
 	 Begin
 	  	 Set @PromptRSReturned = 1
 	  	 SELECT * From #Prompts
 	 End
Select Id=@FirstProduct, Product = 'Group', Description = 'Group Of Products', Comment = '(' + @ProductList + ')'
If (Select Count(*) From #Report) = 0
  Begin
    exec spRS_AddEngineActivity @ReportName, 0, 'There Is No Data To Report On For Selected Time Range', 2, @ReportId, @RunId
    Raiserror('There Is No Data To Report On For Selected Time Range',16,1)
    return
  End
if( @maxRecords =1)
BEGIN
Select Top 500 * From #Report r 
  join #Variables v on v.Item = r.Id
  order by v.ItemOrder
END
ELSE
BEGIN
Select * From #Report r 
  join #Variables v on v.Item = r.Id
  order by v.ItemOrder
END
-------------------------------------------------------------------
-- End Of Procedure
-------------------------------------------------------------------
EndProcedure:
Drop Table #Prompts
Drop Table #Data
Drop Table #Report
Drop Table #Events
Drop Table #Variables
Drop Table #Products
Drop Table #TimeEvents
--/**************************************
