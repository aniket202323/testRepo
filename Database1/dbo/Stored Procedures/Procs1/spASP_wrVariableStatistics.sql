CREATE PROCEDURE [dbo].[spASP_wrVariableStatistics]
@Variable int,
@StartTime datetime,
@EndTime datetime,
@NumberOfPoints int,
@Direction tinyint,
@Products nVarChar(1000) = null,
@BasisProduct int = null,
@NonProductiveTimeFilter bit = 0,
@Events 	 varchar(8000) = NULL,
@InTimeZone nvarchar(200)=NULL
AS
Declare @TimeWindow int --Days (used for getting data in 'n' day blocks for number of points queries - Calculated Below On Number of Points Requested)
Declare @NoDataRetryCount int
--/************************************************************************
-- Set Up Constants For Calculations
-- spASP_wrVariableStatistics 15, '1-1-2001','1-1-2006', null,null, '5,6', 5
--************************************************************************
IF @InTimeZone = '' SELECT @InTimeZone = NULL
 	 select @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)  
 	 select @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone) 
Declare @SpecificationSetting int  -- For Specification Comparisons
Select @SpecificationSetting = convert(int,value) From Site_Parameters Where Parm_id = 13
If @SpecificationSetting is Null Select @SpecificationSetting = 1
Declare @CPKMultiplier float
Select @CPKMultiplier = convert(float,Value) From Site_Parameters Where Parm_Id = 152
If @CPKMultiplier is Null Select @CPKMultiplier = 4.0
If @CPKMultiplier = 0 SELECT @CPKMultiplier = 4.0
Declare @WarningMultiplier float
Select @WarningMultiplier = 2.0
Declare @RejectMultiplier float
Select @RejectMultiplier = 3.0
/************************************************************************
-- **** For Testing  *****
--************************************************************************
Select @Variable = 12
--Select @Variable = 463
Select @StartTime = '1-aug-01'
Select @EndTime = '15-oct-01'
Select @NumberOfPoints = 0
--Select @Direction = 2
Select @Products = '5' --'5'
Select @BasisProduct = 5
--************************************************************************
--************************************************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @IsEventBased int
Declare @MasterUnit int
Declare @VariableName nVarChar(100)
Declare @UnitName nVarChar(100)
Declare @DataTypeId int
Declare @EngineeringUnits nvarchar(25)
Declare @Precision int
declare @IsUserDefinedBased int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @SQL varchar(8000)
Declare @NumberOfRows int
Declare @TotalRows int
Declare @Retry int
Declare @ProdCode nvarchar(25)
Declare @EventFilter VarChar(8000)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sLowerReject nVarChar(100)
DECLARE @sLowerWarning nVarChar(100)
DECLARE @sTarget nVarChar(100)
DECLARE @sUpperWarning nVarChar(100)
DECLARE @sUpperReject nVarChar(100)
SET @sLowerReject = dbo.fnTranslate(@LangId, 34667, 'Lower Reject')
SET @sLowerWarning = dbo.fnTranslate(@LangId, 34668, 'Lower Warning')
SET @sTarget = dbo.fnTranslate(@LangId, 34669, 'Target')
SET @sUpperWarning = dbo.fnTranslate(@LangId, 34670, 'Upper Warning')
SET @sUpperReject = dbo.fnTranslate(@LangId, 34671, 'Upper Reject')
--**********************************************
--***********************************************************
-- Get Initial Information
--***********************************************************
If @NumberOfPoints > 0 
  Begin
    Select @TimeWindow = 0
    Select @TimeWindow = @NumberOfPoints / 50
    If @TimeWindow = 0 
      Select @TimeWindow = 1
    Select @NoDataRetryCount = ((2 * 365) / @TimeWindow) + 1
  End
Select @MasterUnit = PU_Id, 
       @IsEventBased = Case When Event_Type = 1 Then 1 Else 0 End,
       @IsUserDefinedBased = Case When Event_Type = 14 Then 1 Else 0 End,
       @DataTypeId = Data_Type_id,
       @VariableName = Var_Desc,
       @EngineeringUnits = Eng_Units,
       @Precision = coalesce(var_precision, 0)
  From Variables 
  Where Var_Id = @Variable
Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End,
       @UnitName = Pu_Desc
  From Prod_Units Where PU_Id = @MasterUnit
--***********************************************************
-- Handle Phase parameters differently.
--***********************************************************
--declare @ProductGroup nVarChar(100)
Declare @UnitFilterForUDE VarChar(8000)
Declare @MasterUnitForUDE int
--select @ProductGroup = pug.pug_desc,
--       @IsUserDefinedBased = Case When Event_Type = 14 Then 1 Else 0 End
--from variables v
--join pu_groups pug on pug.pug_id = v.pug_id
--where var_id = @Variable
Select @MasterUnitForUDE = PUBatch.PU_Id
From Prod_Units PUPhase
Join Prod_Units PUBatch ON PUBatch.PL_id = PUPhase.PL_Id
Where PUPhase.PU_id = @MasterUnit and PUBatch.Extended_Info = 'BATCH:'
-- In case selected batches are from manu units, need to go via events
--Create Table #SelectedUnitsForUDEVar(
-- 	 UnitId Int
--)
--if @IsUserDefinedBased = 1 and @Events Is Not Null
--begin 
-- 	 Select @SQL = 'Insert Into #SelectedUnitsForUDEVar(UnitId) Select Pu_Id From Events Where Event_id In (' + @Events + ')'
-- 	 Exec(@SQL)
--end
--***********************************************************
-- Handle Phase parameters differently.
--***********************************************************
--***********************************************************
-- Check Parameters
--***********************************************************
If @Variable Is Null
  Begin
    --exec spRS_AddEngineActivity @ReportName, 0, 'Required [Variable] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [Variable] Parameter Is Missing',16,1)
    return
  End
If @StartTime Is Null
  Begin
    --exec spRS_AddEngineActivity @ReportName, 0, 'Required [StartTime] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [StartTime] Parameter Is Missing',16,1)
    return
  End
If @BasisProduct Is Null
  Begin
    --exec spRS_AddEngineActivity @ReportName, 0, 'Required [BasisProduct] Parameter Is Missing', 2, @ReportId, @RunId
    Raiserror('Required [BasisProduct] Parameter Is Missing',16,1)
    return
  End
If @DataTypeId Not In (1,2,6,7)
  Begin
    --exec spRS_AddEngineActivity @ReportName, 0, 'Variable Must Be Numeric Data Type To Use This Analysis', 2, @ReportId, @RunId
    Raiserror('Variable Must Be Numeric Data Type To Use This Analysis',16,1)
    return
  End
If DATALENGTH(@Events) > 7500
Begin
 	 Raiserror('Maximum Number Of Events In Filter Exceeded',16,1)
    return
End
if @Products =''
Begin
 	 SET @Products = NULL
End
--***********************************************************
-- Get The Timestamps / Data points For This Variable
--***********************************************************
Create Table #Report (
  Timestamp datetime, 
  ProductId int,
  RunId int,
  Value float NULL,
  LRL float NULL,
  LWL float NULL,
  TGT float NULL,
  UWL float NULL,
  URL float NULL,
  InSpec int NULL,
  Bucket float NULL
)
CREATE INDEX Report_Times ON #Report (Timestamp) 
--Turn @Products into a table
Create Table #SelectedProducts(
 	 ProductId Int
)
If @Products Is Not Null
Begin
 	 Select @SQL = 'Insert Into #SelectedProducts(ProductId) Select Prod_Id From Products Where Prod_Id In (' + @Products + ')'
 	 Exec(@SQL)
End
--Run the query
Create Table #SelectedEvents(
   EventId Int
)
If @Events Is Not Null
Begin
  Select @SQL = 'Insert Into #SelectedEvents(EventId) Select Event_Id From Events Where Event_Id In (' + @Events + ')'
  Exec(@SQL)
End 
If @IsEventBased = 1 
 Begin
 	  --***********************************************************
   -- THIS IS A PRODUCTION EVENT BASED VARIABLE
 	  --***********************************************************
   If @NumberOfPoints = 0 or @NumberOfPoints Is Null
     Begin
 	  	  	  --***********************************************************
       -- Time Query
 	  	  	  --***********************************************************
       If @Products Is Null
         Begin
 	  	  	  	  	  Print 'Time Query for Production Event Based Variable'
 	  	        Insert Into #Report (Timestamp, ProductId, RunId)
 	  	          Select e.Timestamp, 
 	  	                 Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	                 Case When e.Applied_Product Is Null Then ps.Start_Id Else -1 * e.Applied_Product End
 	  	            From Events_NPT e
 	  	            Join Production_Starts ps on ps.PU_id = @MasterUnit and 
 	  	                                   ps.Start_Time <= e.Timestamp and 
 	  	                                 ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	            Where e.PU_id = @MasterUnit and
 	  	                  e.Timestamp > @StartTime and 
 	  	                  e.Timestamp <= @EndTime          
 	  	  	  	  	  	 AND 	 (@Events IS NULL OR e.Event_Id IN (Select 	 * From #SelectedEvents))     
 	  	  	  	  	  	  	  	  	  	  And (@NonProductiveTimeFilter = 0 Or e.Non_Productive_Seconds = 0)
         End
       Else
         Begin
 	  	  	  	  	  	  	  Print 'Time Query for Production Event Based Variable with list of Products'
 	  	  	    If @Events IS NULL
 	  	  	  	   Begin
 	  	  	  	  	 SELECT @EventFilter = ' '
 	  	  	  	   End
 	  	  	    Else
 	  	  	  	   Begin
 	  	  	  	  	 SELECT @EventFilter = 'AND 	 (e.Event_Id IN (Select 	 * From #SelectedEvents)) '
 	  	  	  	   End
               Select @SQL = 'Insert Into #Report (Timestamp, ProductId, RunId) ' +
 	  	               	  	  	  	  	  	 'Select e.Timestamp, ' + 
 	  	                      	  	  	 'Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End, ' + 
 	  	                      	  	  	 'Case When e.Applied_Product Is Null Then ps.Start_Id Else -1 * e.Applied_Product End ' + 
 	  	                 	  	  	  	  	 'From Events_NPT e ' + 
 	  	                 	  	  	  	  	 'Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(20),@MasterUnit) + ' and ' + 
 	  	                                        	  	  	  	  'ps.Start_Time <= e.Timestamp and ' + 
 	  	                                      	  	  	  	  '((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null)) ' +
 	  	                 	  	  	  	  	 'Where e.PU_id = ' + convert(nvarchar(20),@MasterUnit) + ' and ' +
 	  	                       	  	  	  	  	 'e.Timestamp > ' + '''' + convert(nvarchar(30),@StartTime,109) + '''' + ' and ' + 
 	  	                       	  	  	  	  	 'e.Timestamp <= ' + '''' + convert(nvarchar(30),@EndTime,109) + '''' + ' and ' +
 	  	  	  	  	  	  	  	  	  	  	 '(((e.applied_product in (' + @Products +  ')) or (ps.prod_Id in (' + @Products + ') AND (e.applied_product is null)))) ' +
 	  	  	  	  	  	  	  	  	  	  	 @EventFilter +
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  'and (' + convert(varchar(1), @NonProductiveTimeFilter) + ' = 0 Or e.Non_Productive_Seconds = 0)'
               Exec (@SQL)
         End
     End
   Else
     Begin
 	  	  	  --***********************************************************
       -- Number Of Points Query
 	  	  	  --***********************************************************
       Select @TotalRows = 0
       Select @NumberOfRows = 0
       Select @Retry = 0
       If @Direction = 1 --Backwards 
         Select @MaxTime = @StartTime
       Else
         Select @MinTime = @StartTime
       While @TotalRows < @NumberOfPoints and @Retry < @NoDataRetryCount
        Begin
           If @Direction = 1 --Backwards 
             Select @MinTime = Dateadd(day,-1 * @TimeWindow, @MaxTime)
           Else
             Select @MaxTime = Dateadd(day,@TimeWindow, @MinTime)
           Select @NumberOfRows = @NumberOfPoints - @TotalRows
           Set Rowcount @NumberOfRows
           If @Products Is Null
             Begin
 	  	  	  	  	  	  	  Print 'Number of Points Query for Production Event Based Variable'
 	  	            Insert Into #Report (Timestamp, ProductId, RunId)
 	  	              Select e.Timestamp, 
 	  	                     Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
 	  	                     Case When e.Applied_Product Is Null Then ps.Start_Id Else -1 * e.Applied_Product End
 	  	                From Events_NPT e
 	  	                Join Production_Starts ps on ps.PU_id = @MasterUnit and 
 	  	                                       ps.Start_Time <= e.Timestamp and 
 	  	                                     ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	  	                Where e.PU_id = @MasterUnit and
 	  	                      e.Timestamp > @MinTime and 
 	  	                      e.Timestamp <= @MaxTime
 	  	  	  	  	  	  	  	  	  	  	  	  And (@NonProductiveTimeFilter = 0 Or e.Non_Productive_Seconds = 0)          
             End
           Else
             Begin
 	  	  	  	  	  	  	  Print 'Number of Points Query for Production Event Based Variable with list of Products'
               Select @SQL = 'Insert Into #Report (Timestamp, ProductId, RunId) ' +
 	  	               	  	  	  	  	  	 'Select e.Timestamp, ' + 
 	  	                      	  	  	 'Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End, ' + 
 	  	                      	  	  	 'Case When e.Applied_Product Is Null Then ps.Start_Id Else -1 * e.Applied_Product End ' + 
 	  	                 	  	  	  	  	 'From Events_NPT e ' + 
 	  	                 	  	  	  	  	 'Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(20),@MasterUnit) + ' and ' + 
 	  	                                        	  	  	  	  'ps.Start_Time <= e.Timestamp and ' + 
 	  	                                      	  	  	  	  '((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null)) ' +
 	  	                 	  	  	  	  	 'Where e.PU_id = ' + convert(nvarchar(20),@MasterUnit) + ' and ' +
 	  	                       	  	  	  	  	 'e.Timestamp > ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' + ' and ' + 
 	  	                       	  	  	  	  	 'e.Timestamp <= ' + '''' + convert(nvarchar(20),@MaxTime,109) + '''' + ' and ' +
  	                                 	    	  '((e.applied_product in ('+  @Products  + ')) or (ps.prod_Id in ('  + @Products + ')) or e.applied_product is null) ' 
               Exec (@SQL)
             End
           Select @NumberOfRows = @@Rowcount  
           Select @TotalRows = @TotalRows + @NumberofRows
           If @NumberOfRows = 0
             Select @Retry = @Retry + 1
           Else
             Select @Retry = 0
           If @Direction = 1 --Backwards 
             Select @MaxTime = @MinTime
           Else
             Select @MinTime = @MaxTime
        End
        Set Rowcount 0       
     End
 	    Select @MinTime = min(timestamp),
 	           @MaxTime = max(timestamp)  
 	      From #Report
 	     	 
 	    -- Get the values from the test table
     Update #Report Set Value = convert(float, t.Result)
 	      From #Report r
 	      Join Tests t on t.Var_id = @Variable and t.Result_On = r.Timestamp and t.Result_On Between @MinTime and @MaxTime
     -- Purge null results  
     Delete From #Report 
       Where Value Is Null
 End
Else
 Begin
 	  --***********************************************************
   -- THIS IS A NON-PRODUCTION EVENT BASED VARIABLE
 	  --***********************************************************
  If @NumberOfPoints = 0 or @NumberOfPoints Is Null
    Begin
 	  	  	  --***********************************************************
      -- This is a time query 
 	  	  	  --***********************************************************
 	  	 If @IsUserDefinedBased = 0 or @Events Is Null
 	  	 begin 
 	  	  	 Print 'Time Query for Non-Production Event Based Variable'
 	  	  	 Insert Into #Report ( Timestamp, ProductId, Value)
 	  	  	  	 Select t.result_on, ps.Prod_Id, convert(float,t.result)
 	  	  	  	 From tests_NPT t
 	  	  	  	 Join Production_Starts ps on ps.PU_id = @MasterUnit
 	  	  	  	  	 And (@Products Is Null Or ps.prod_id in (Select * From #SelectedProducts))
 	  	  	  	  	 And ps.Start_Time <= t.Result_on
 	  	  	  	  	 And (ps.End_Time > t.result_On or ps.End_Time Is Null)
 	  	  	  	 Where t.Var_id = @Variable
 	  	  	  	 And t.Result_On > @StartTime
 	  	  	  	 And t.Result_On <= @EndTime
 	  	  	  	 And t.result Is Not Null
 	  	  	  	 And (@NonProductiveTimeFilter = 0 Or t.Is_Non_Productive = 0)
 	  	 end
 	  	 else -- if @IsUserDefinedBased = 1 and @Events Is Not Null
 	  	 begin
 	  	    If @Products Is Null
 	  	  	  Begin
 	  	  	  	  	  	  Print 'UDE Event Based Variable, events not null and product null'
 	  	  	  	    Insert Into #Report (Timestamp, ProductId, RunId)
 	  	  	  	  	  Select distinct PhaseEvent.End_time, 
 	  	  	  	  	  	  	 Case When BatchEvent.Applied_Product Is Null Then ps.Prod_Id Else BatchEvent.Applied_Product End,
 	  	  	  	  	  	  	 Case When BatchEvent.Applied_Product Is Null Then ps.Start_Id Else -1 * BatchEvent.Applied_Product End
 	  	                From Events_NPT BatchEvent
 	  	  	 Join Event_Components EC 	  	  	  	 ON 	 EC.Source_Event_Id = BatchEvent.Event_Id
 	  	  	 Join Events_NPT UnitProcedureEvent  	  	 ON 	 UnitProcedureEvent.Event_Id = EC.Event_Id
 	  	  	 Join User_Defined_Events_NPT OperationEvent 	 ON 	 OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
 	  	  	 Join User_Defined_Events_NPT PhaseEvent 	 ON 	 PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
 	  	  	  	  	    Join Production_Starts ps on ps.PU_id = @MasterUnitForUDE and 
 	  	  	  	  	  	  	  	  	  	  	   ps.Start_Time <= BatchEvent.Timestamp and 
 	  	  	  	  	  	  	  	  	  	  	 ((ps.End_Time > BatchEvent.Timestamp) or (ps.End_Time Is Null))
 	  	  	  	  	    Where BatchEvent.PU_id = ps.PU_id and
 	  	  	  	  	  	  	  BatchEvent.Timestamp > @StartTime and 
 	  	  	  	  	  	  	  BatchEvent.Timestamp <= @EndTime          
 	  	  	  	  	  	  	 AND 	 (@Events IS NULL OR BatchEvent.Event_Id IN (Select 	 * From #SelectedEvents))     
 	  	  	  	  	  	  	  	  	  	  	  And (@NonProductiveTimeFilter = 0 Or BatchEvent.Non_Productive_Seconds = 0)
 	  	  	  End
 	  	    Else
 	  	  	  Begin
 	  	  	  	  	  	  Print 'UDE Event Based Variable, events not null and product not null'
 	  	  	  	    If @Events IS NULL
 	  	  	  	  	   Begin
 	  	  	  	  	  	 SELECT @EventFilter = ' '
 	  	  	  	  	   End
 	  	  	  	    Else
 	  	  	  	  	   Begin
 	  	  	  	  	  	 SELECT @EventFilter = 'AND 	 (BatchEvent.Event_Id IN (Select 	 * From #SelectedEvents)) '
 	  	  	  	  	   End
 	  	  	  	    Select @SQL = 'Insert Into #Report (Timestamp, ProductId, RunId) ' +
 	  	               	  	  	  	  	  	  	 'Select distinct PhaseEvent.End_Time, ' + 
 	  	                      	  	  	  	 'Case When BatchEvent.Applied_Product Is Null Then ps.Prod_Id Else BatchEvent.Applied_Product End, ' + 
 	  	                      	  	  	  	 'Case When BatchEvent.Applied_Product Is Null Then ps.Start_Id Else -1 * BatchEvent.Applied_Product End ' + 
 	  	                'From Events_NPT BatchEvent ' +
 	  	  	 'Join Event_Components EC 	  	  	  	 ON 	 EC.Source_Event_Id = BatchEvent.Event_Id ' +
 	  	  	 'Join Events_NPT UnitProcedureEvent  	  	 ON 	 UnitProcedureEvent.Event_Id = EC.Event_Id ' +
 	  	  	 'Join User_Defined_Events_NPT OperationEvent ON 	 OperationEvent.Event_Id = UnitProcedureEvent.Event_Id ' +
 	  	  	 'Join User_Defined_Events_NPT PhaseEvent ON 	 PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id ' +
 	  	                 	  	  	  	  	  	 'Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(20),@MasterUnitForUDE) + ' and ' + 
 	  	                                        	  	  	  	  	  'ps.Start_Time <= BatchEvent.Timestamp and ' + 
 	  	                                      	  	  	  	  	  '((ps.End_Time > BatchEvent.Timestamp) or (ps.End_Time Is Null)) ' +
 	  	                 	  	  	  	  	  	 'Where BatchEvent.PU_id = ps.PU_id and ' +
 	  	                       	  	  	  	  	  	 'BatchEvent.Timestamp > ' + '''' + convert(nvarchar(30),@StartTime,109) + '''' + ' and ' + 
 	  	                       	  	  	  	  	  	 'BatchEvent.Timestamp <= ' + '''' + convert(nvarchar(30),@EndTime,109) + '''' + ' and ' +
 	  	  	  	  	  	  	  	  	  	  	  	 '(((BatchEvent.applied_product in (' + @Products +  ')) or (ps.prod_Id in (' + @Products + ') AND (BatchEvent.applied_product is null)))) ' +
 	  	  	  	  	  	  	  	  	  	  	  	 @EventFilter +
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  	  'and (' + convert(varchar(1), @NonProductiveTimeFilter) + ' = 0 Or BatchEvent.Non_Productive_Seconds = 0)'
 	  	  	  	    Exec (@SQL)
 	  	  	 End
 	  	  	 Select @MinTime = min(timestamp),
 	  	  	 @MaxTime = max(timestamp)  
 	  	  	 From #Report
 	  	  	     	 
 	  	  	 -- Get the values from the test table
 	  	  	 Update #Report Set Value = convert(float, t.Result)
 	  	  	  From #Report r
 	  	  	 Join Tests t on t.Var_id = @Variable and t.Result_On = r.Timestamp and t.Result_On Between @MinTime and @MaxTime
 	  	     
 	  	  	 -- Purge null results  
 	  	  	 Delete From #Report 
 	  	  	   Where Value Is Null
 	  	 End
    End
  Else
    Begin
 	  	  	  --***********************************************************
      -- This is a number of points query 
 	  	  	  --***********************************************************
 	  	  	  Print 'Number of Points Query for Non-Production Event Based Variable with list of Products'
       Select @TotalRows = 0
       Select @NumberOfRows = 0
       Select @Retry = 0
       If @Direction = 1 --Backwards 
         Select @MaxTime = @StartTime
       Else
         Select @MinTime = @StartTime
       While @TotalRows < @NumberOfPoints and @Retry < @NoDataRetryCount
        Begin
           If @Direction = 1 --Backwards 
             Select @MinTime = Dateadd(day,-1 * @TimeWindow, @MaxTime)
           Else
             Select @MaxTime = Dateadd(day,@TimeWindow, @MinTime)
           Select @NumberOfRows = @NumberOfPoints - @TotalRows
           Set Rowcount @NumberOfRows
 	  	  	  	  	 Insert Into #Report ( Timestamp, ProductId, Value)
 	  	  	  	  	 Select t.result_on, ps.Prod_Id, convert(float,t.result)
 	  	  	  	  	 From tests_NPT t 
 	  	  	  	  	 Join Production_Starts ps on ps.PU_id = @MasterUnit
 	  	  	  	  	  	 And (@Products Is Null Or ps.prod_id in (Select * From #SelectedProducts))
 	  	  	  	  	  	 And ps.Start_Time <= t.Result_on
 	  	  	  	  	  	 And (ps.End_Time > t.result_On or ps.End_Time Is Null)
 	  	  	  	  	 Where t.Var_id = @Variable
 	  	  	  	  	  	 And t.Result_On > @MinTime
 	  	  	  	  	  	 And t.Result_On <= @MaxTime
 	  	  	  	  	  	 And t.result Is Not Null
 	  	  	  	  	  	 And (@NonProductiveTimeFilter = 0 Or t.Is_Non_Productive = 0)
           Select @NumberOfRows = @@Rowcount  
           Select @TotalRows = @TotalRows + @NumberofRows
           If @NumberOfRows = 0
             Select @Retry = @Retry + 1
           Else
             Select @Retry = 0
           If @Direction = 1 --Backwards 
             Select @MaxTime = @MinTime
           Else
             Select @MinTime = @MaxTime
        End
        Set Rowcount 0       
    End
  	 End      
--***********************************************************
-- Fill In Specifications
--***********************************************************
Update #Report 
  Set TGT = convert(float,vs.target), 
      UWL = convert(float,vs.u_warning),  
      LWL = convert(float,vs.l_warning),  
      URL = convert(float,vs.u_reject),  
      LRL = convert(float,vs.l_reject) 
  From #Report r  
  Left Outer Join Var_Specs vs on vs.Var_Id = @Variable and 
                            vs.Prod_Id = r.ProductId and 
                            vs.effective_date <= r.Timestamp and 
                          ((vs.expiration_date > r.Timestamp) or (vs.expiration_date Is Null)) 
--***********************************************************
-- Update In-Specification Calculation
--***********************************************************
If @SpecificationSetting = 1
  Update #Report
    Set InSpec = Case 
 	  	  	              When Value > coalesce(URL,Value) Then 2 
 	  	  	              When Value < coalesce(LRL,Value) Then -2 
 	  	  	              When Value > coalesce(UWL,Value) Then 1 
 	  	  	              When Value < coalesce(LWL,Value) Then -1 
 	  	  	              Else 0 
  	  	  	  	  	  	  	  	  End 
Else
  Update #Report
    Set InSpec = Case 
 	  	  	              When Value >= coalesce(URL,Value-1) Then 2 
 	  	  	              When Value <= coalesce(LRL,Value+1) Then -2 
 	  	  	              When Value >= coalesce(UWL,Value-1) Then 1 
 	  	  	              When Value <= coalesce(LWL,Value+1) Then -1 
 	  	  	              Else 0 
  	  	  	  	  	  	  	  	  End 
--***********************************************************
-- Get Basic Statistics Of Data Set
--***********************************************************
Declare @Avg float
Declare @Min float
Declare @Max float
Declare @Std float
Declare @Count int
Declare @PercentSigma float
Select @Avg = avg(Value), @Min = min(Value), @Max = max(Value), @Std = stdev(Value), @Count = count(Value)
  From #Report
If @Std is null
        SELECT @Std = .00001
If @Std = 0 
 	 SELECT @Std = .00001
If (Not @Avg Is Null) And (@Avg <> 0)
 	 Select @PercentSigma = abs((@Std / @Avg) * 100.0)
Else
 	 Select @PercentSigma = 0
Declare @BucketSize float
Select @BucketSize = @Std / 5.0
Declare @TGT_Current float
Declare @LRL_Current float
Declare @LWL_Current float
Declare @UWL_Current float
Declare @URL_Current float
Select @TGT_Current = target, @LRL_Current = l_reject, @LWL_Current = l_warning, @UWL_Current = u_warning, @URL_Current = u_reject
  From var_specs
  Where var_id = @Variable and
        prod_id = @BasisProduct and
        effective_date <= dbo.fnServer_CmnGetDate(getutcdate()) and
        ((expiration_date > dbo.fnServer_CmnGetDate(getutcdate())) or (expiration_date is NULL))
Declare @TGT_End float
Declare @LRL_End float
Declare @LWL_End float
Declare @UWL_End float
Declare @URL_End float
Select @TGT_End = target, @LRL_End = l_reject, @LWL_End = l_warning, @UWL_End = u_warning, @URL_End = u_reject
  From var_specs
  Where var_id = @Variable and
        prod_id = @BasisProduct and
        effective_date <= @MaxTime and
        ((expiration_date > @MaxTime) or (expiration_date is NULL))
Declare @TGT_Theoretical float
Declare @LRL_Theoretical float
Declare @LWL_Theoretical float
Declare @UWL_Theoretical float
Declare @URL_Theoretical float
If @TGT_Current Is Not Null
  Select @TGT_Theoretical = @TGT_Current
Else
  Select @TGT_Theoretical = @Avg
Select @LRL_Theoretical = @TGT_Theoretical - (@RejectMultiplier * @Std)
Select @LWL_Theoretical = @TGT_Theoretical - (@WarningMultiplier * @Std)
Select @URL_Theoretical = @TGT_Theoretical + (@RejectMultiplier * @Std)
Select @UWL_Theoretical = @TGT_Theoretical + (@WarningMultiplier * @Std)
Declare @Cpk float
Select @Cpk = Case 
 	  	  	  	          When @LRL_Current Is Not Null and @URL_Current Is Not Null Then
 	  	  	  	              Case 
 	  	  	  	                When (@URL_Current - @Avg) < (@Avg - @LRL_Current) Then
 	  	  	  	                  (@URL_Current - @Avg) / (@CPKMultiplier * @Std) 
 	  	  	  	                Else
 	  	  	  	                  (@Avg - @LRL_Current) / (@CPKMultiplier * @Std) 
 	  	  	  	               End
 	  	  	  	          When @URL_Current Is Not Null Then 
 	  	  	  	             (@URL_Current - @Avg) / (@CPKMultiplier * @Std) 
 	  	  	  	          When @LRL_Current Is Not Null Then 
 	  	  	  	             (@Avg - @LRL_Current) / (@CPKMultiplier * @Std) 
 	  	  	  	          Else NULL 
 	  	  	  	  	      End
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant,
  PromptValue_Parameter2 SQL_Variant,
  PromptValue_Parameter3 SQL_Variant,
 	 PromptValue_Parameter4 SQL_Variant
)
Select @ProdCode = Prod_Code From Products Where Prod_id = @BasisProduct
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2)
  Values('ReportName', dbo.fnTranslate(@LangId, 34867, '{0} Statistics On {1}'), @VariableName, @UnitName)
If @NumberOfPoints = 0 or @NumberOfPoints Is Null
  Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', dbo.fnTranslate(@LangId, 34647, 'For {0} From [{1}] To [{2}]'), @ProdCode, @StartTime, @EndTime)
Else
  Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3)
    Values('Criteria', dbo.fnTranslate(@LangId, 34647, 'For {0} {1} From [{2}]'), @ProdCode, @NumberOfPoints, @EndTime)
Insert into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into #Prompts (PromptName, PromptValue) Values('CriteriaSummary', dbo.fnTranslate(@LangId, 34868, 'Criteria Summary'))
Insert into #Prompts (PromptName, PromptValue) Values('ProductSummary', dbo.fnTranslate(@LangId, 34869, 'Products Analyzed'))
Insert into #Prompts (PromptName, PromptValue) Values('StatisticsSummary', dbo.fnTranslate(@LangId, 34870, 'Statistics Summary'))
Insert into #Prompts (PromptName, PromptValue) Values('LimitSummary', dbo.fnTranslate(@LangId, 34871, 'Limit Summary'))
Insert into #Prompts (PromptName, PromptValue) Values('ControlSummary', dbo.fnTranslate(@LangId, 34872, 'Control Summary'))
Insert into #Prompts (PromptName, PromptValue) Values('ProductCapability', dbo.fnTranslate(@LangId, 34873, 'Product Capability'))
Insert into #Prompts (PromptName, PromptValue) Values('RunAnalysis', dbo.fnTranslate(@LangId, 34874, 'Run Analysis'))
Insert into #Prompts (PromptName, PromptValue) Values('CusumAnalysis', dbo.fnTranslate(@LangId, 34875, 'Cusum Analysis'))
Insert into #Prompts (PromptName, PromptValue) Values('ControlChart', dbo.fnTranslate(@LangId, 34876, 'Control Chart'))
Insert into #Prompts (PromptName, PromptValue) Values('Average', dbo.fnTranslate(@LangId, 34031, 'Average'))
Insert into #Prompts (PromptName, PromptValue) Values('Minimum', dbo.fnTranslate(@LangId, 34029, 'Minimum'))
Insert into #Prompts (PromptName, PromptValue) Values('Maximum', dbo.fnTranslate(@LangId, 34030, 'Maximum'))
Insert into #Prompts (PromptName, PromptValue) Values('StandardDeviation', dbo.fnTranslate(@LangId, 34877, 'Standard Deviation'))
Insert into #Prompts (PromptName, PromptValue) Values('NumberOfPoints', dbo.fnTranslate(@LangId, 34878, '#Values'))
Insert Into #Prompts (PromptName, PromptValue) Values('ProductCode', dbo.fnTranslate(@LangId, 34973, 'Product Code'))
Insert Into #Prompts (PromptName, PromptValue) Values('ProductDescription', dbo.fnTranslate(@LangId, 34974, 'Product Description'))
Insert Into #Prompts (PromptName, PromptValue) Values('ProcessCapability', dbo.fnTranslate(@LangId, 34975, 'Process Capability'))
Insert Into #Prompts (PromptName, PromptValue) Values('Trend', dbo.fnTranslate(@LangId, 34976, 'Trend'))
Insert into #Prompts (PromptName, PromptValue) Values ('Limit', dbo.fnTranslate(@LangId, 34879, 'Limit'))
Insert into #Prompts (PromptName, PromptValue) Values ('EndLimit', dbo.fnTranslate(@LangId, 34880, 'Last Limit'))
Insert into #Prompts (PromptName, PromptValue) Values ('CurrentLimit', dbo.fnTranslate(@LangId, 34881, 'Current Limit'))
Insert into #Prompts (PromptName, PromptValue) Values ('TheoreticalLimit', dbo.fnTranslate(@LangId, 34882, 'Theoretical Limit'))
Insert into #Prompts (PromptName, PromptValue) Values ('Deviation', dbo.fnTranslate(@LangId, 34883, 'Deviation'))
Insert into #Prompts (PromptName, PromptValue) Values ('SigmaDeviation', dbo.fnTranslate(@LangId, 34884, 'Percent Sigma'))
Insert into #Prompts (PromptName, PromptValue) Values ('VariableId', Convert(nvarchar(20), @Variable))
Insert into #Prompts (PromptName, PromptValue) Values ('Precision', Convert(nvarchar(20), @Precision))
Insert Into #Prompts (PromptName, PromptValue,PromptValue_Parameter) Values ('StartTime', '{0}', @StartTime)
Insert Into #Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EndTime', '{0}', @EndTime)
Insert Into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3, PromptValue_Parameter4) Values ('NotRunOnBasisProduct', dbo.fnTranslate(@LangId, 35160, '{0} was not run on {1} from {2} to {3}.'), @ProdCode, @UnitName, @StartTime, @EndTime)
Insert Into #Prompts (PromptName, PromptValue, PromptValue_Parameter, PromptValue_Parameter2, PromptValue_Parameter3) Values ('NotRunOnProducts', dbo.fnTranslate(@LangId, 35161, 'The  selected products were not run on {0} from {1} to {2}.'), @UnitName, @StartTime, @EndTime)
select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'PromptValue_Parameter2'= case when (ISDATE(Convert(varchar,PromptValue_Parameter2))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter2),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter2
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'PromptValue_Parameter3'= case when (ISDATE(Convert(varchar,PromptValue_Parameter3))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter3),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter3
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
'PromptValue_Parameter4'= case when (ISDATE(Convert(varchar,PromptValue_Parameter4))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter4),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter4
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end
From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Basic Resultset With High Level Info
--**********************************************
-- Create Simple Return Table
Create Table #Information (
  [Id] int identity(1,1),
  [Name] nvarchar(50),
  Value nvarchar(255) NULL,
  Value_Parameter SQL_Variant,
  Hyperlink nvarchar(255) NULL
)
--**********************************************
-- Return Basic Criteria
--**********************************************
Truncate Table #Information
Insert Into #Information ([Name], Value) Values (dbo.fnTranslate(@LangId, 34847, 'Variable'), @VariableName)
Insert Into #Information ([Name], Value) Values (dbo.fnTranslate(@LangId, 34848, 'Eng Units'), @EngineeringUnits)
Insert Into #Information ([Name], Value) Values (dbo.fnTranslate(@LangId, 34850, 'Unit'), @UnitName)
If @NumberOfPoints > 0 
  Begin
    Insert Into #Information ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34158, 'Number Of Points'), '{0}', @NumberOfPoints)
    If @Direction = 1
      Insert Into #Information ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34885, 'Backwards From'), '{0}', @StartTime)
    Else
      Insert Into #Information ([Name], Value, Value_Parameter) Values (dbo.fnTranslate(@LangId, 34886, 'Forward From'), '{0}', @StartTime)
  End
Else
  Begin
    Insert Into #Information ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34011, 'Start Time'), '{0}', @StartTime)
    Insert Into #Information ([Name], Value, Value_Parameter) Values(dbo.fnTranslate(@LangId, 34012, 'End Time'), '{0}', @EndTime)
  End
Select [Id],
  [Name],
  [Value],
  'Value_Parameter'= case when (ISDATE(Convert(varchar,Value_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,Value_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Value_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end,
  Hyperlink 
From #Information Order By Id
--**********************************************
-- Return Products Analyzed
--**********************************************
Create Table #Products
(
  [Id] int
)
Insert Into #Products
  Select Distinct ProductId From #Report
Select Id, ProductCode = p.Prod_Code, ProductDescription = p.Prod_Desc
  From #Products
  Join Products p on p.Prod_Id = #Products.Id 
  Order By ProductCode ASC
Drop Table #Products
--**********************************************
-- Return Basic Statistics
--**********************************************
Select Average = @Avg, Minimum = @Min, Maximum = @Max, StandardDeviation = @Std, NumberOfPoints = @Count, Cpk = @CPk, BucketSize = @BucketSize,
       CurrentTGT = @TGT_Current, CurrentLRL = @LRL_Current, CurrentLWL = @LWL_Current, CurrentUWL = @UWL_Current, CurrentURL = @URL_Current,
       TheoreticalTGT = @TGT_Theoretical, TheoreticalLRL = @LRL_Theoretical, TheoreticalLWL = @LWL_Theoretical, TheoreticalUWL = @UWL_Theoretical, TheoreticalURL = @URL_Theoretical,
       NumberOfBuckets = convert(int,(@Max - @Min) / @BucketSize) + 1, SigmaDeviation = @PercentSigma,
 	  	  	  HasCurrentTGT = Case When @TGT_Current Is NULL Then 0 Else 1 End,
 	  	  	  HasCurrentLRL = Case When @LRL_Current Is NULL Then 0 Else 1 End,
 	  	  	  HasCurrentLWL = Case When @LWL_Current Is NULL Then 0 Else 1 End,
 	  	  	  HasCurrentUWL = Case When @UWL_Current Is NULL Then 0 Else 1 End,
 	  	  	  HasCurrentURL = Case When @URL_Current Is NULL Then 0 Else 1 End
--**********************************************
-- Return Theoretical Limit Table
--**********************************************
Create Table #Limits
(
  [Id] int identity(1,1),
  [Name] nvarchar(25),
  Label nvarchar(25),
  EndLimit float NULL,
  CurrentLimit float NULL,
  TheoreticalLimit float NULL,
  Deviation float NULL
)
Insert Into #Limits
  Select [Name] = 'LowerReject', Label = @sLowerReject,
         EndLimit = @LRL_End, CurrentLimit = @LRL_Current, TheoreticalLimit = @LRL_Theoretical,
         Deviation = @LRL_Current - @LRL_Theoretical
Insert Into #Limits
  Select [Name] = 'LowerWarning', Label =  @sLowerWarning, 
         EndLimit = @LWL_End, CurrentLimit = @LWL_Current, TheoreticalLimit = @LWL_Theoretical,
         Deviation = @LWL_Current - @LWL_Theoretical
Insert Into #Limits
  Select [Name] = 'Target', Label = @sTarget,
         EndLimit = @TGT_End, CurrentLimit = @TGT_Current, TheoreticalLimit = @TGT_Theoretical,
         Deviation = @TGT_Current - @Avg
Insert Into #Limits
  Select [Name] = 'UpperWarning', Label = @sUpperWarning,
         EndLimit = @UWL_End, CurrentLimit = @UWL_Current, TheoreticalLimit = @UWL_Theoretical,
         Deviation = @UWL_Current - @UWL_Theoretical
Insert Into #Limits
  Select [Name] = 'UpperReject', Label = @sUpperReject,
         EndLimit = @URL_End, CurrentLimit = @URL_Current, TheoreticalLimit = @URL_Theoretical,
         Deviation = @URL_Current - @URL_Theoretical
Select * From #Limits
  Order By Id
Drop Table #Limits
--**********************************************
-- Return Control Summary Chart
--**********************************************
Select InSpec,
 	  	  	 Label = Case
                   When InSpec = -2 Then @sLowerReject
                   When InSpec = -1 Then @sLowerWarning
                   When InSpec = 0 Then @sTarget
                   When InSpec = 1 Then @sUpperWarning
                   When InSpec = 2 Then @sUpperReject
                   Else @sTarget
                 End,       
 	  	  	 Value = convert(float,count(InSpec)) / convert(float,@Count) * 100.0,
 	  	  	 Color = Case
 	  	  	  	  	  	  	  	  	  -- 0xFF0000 = Color.Red
 	  	  	  	  	  	  	  	  	  -- 0x0000FF = Color.Blue
 	  	  	  	  	  	  	  	  	  -- 0x00FF00 = Color.Green
                   When InSpec = -2 Then 0xFF0000
                   When InSpec = -1 Then 0x0000FF
                   When InSpec = 0 Then 0x008000
                   When InSpec = 1 Then 0x0000FF
                   When InSpec = 2 Then 0xFF0000
                   Else 0x008000
                 End
  From #Report
  Group By InSpec
  Order By InSpec ASC
--**********************************************
-- Return Capability Histogram
--**********************************************
Select Value, ProductId, IsBasisProduct =
 	 Case 
 	  	 When ProductId = @BasisProduct Then 1
 	  	 Else 0
 	 End
 	 From #Report
 	 Order By Value
--**********************************************
-- Return Run Analysis Statistics
--**********************************************
Select RunId, Average = avg(Value), Minimum = min(Value), Maximum = max(Value), StandardDeviation = stdev(Value), NumberOfPoints = count(Value),
       MinTime =  [dbo].[fnServer_CmnConvertFromDbTime] (min([Timestamp]),@InTimeZone) ,
 	    MaxTime =  [dbo].[fnServer_CmnConvertFromDbTime] (max([Timestamp]),@InTimeZone) ,
       TheoreticalTGT = avg(Value), TheoreticalLRL = avg(Value) - @RejectMultiplier * Coalesce(Stdev(Value), 0), 
       TheoreticalLWL = avg(Value) - @WarningMultiplier * Coalesce(Stdev(Value), 0), 
       TheoreticalUWL = avg(Value) + @WarningMultiplier * Coalesce(Stdev(Value), 0), 
       TheoreticalURL = avg(Value) + @RejectMultiplier * Coalesce(Stdev(Value), 0)
  From #Report
 	 Where @RejectMultiplier Is Not Null And
 	  	 @WarningMultiplier Is Not Null And
 	  	 Value Is Not Null
  Group By RunId
  Order By MinTime ASC
--**********************************************
-- Return Trend Data
--**********************************************
Select 'Timestamp'=  [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@InTimeZone),
Value, LRL, LWL, TGT, UWL, URL From #Report
  order by timestamp ASC
Drop Table #Information
Drop Table #SelectedProducts
Drop Table #Report
DROP TABLE #SelectedEvents  	 
--DROP TABLE #SelectedUnitsForUDEVar
