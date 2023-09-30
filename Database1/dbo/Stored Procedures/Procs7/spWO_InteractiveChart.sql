Create Procedure [dbo].[spWO_InteractiveChart]
@PrimaryVariable int,
@StartTime datetime,
@EndTime datetime,
@NumberOfPoints int,
@Direction tinyint,
@IncludeSpecifications int,
@OtherVariables nvarchar(1000),
@EventType int,
@EventSubtype int,
@ProductCode nVarChar(50) = null, 
@ContextType int = null,
@ContextName nvarchar(255) = null,
@Command int = null,
@InTimeZone nvarchar(200)=NULL
AS
  	 Select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)  
 	 Select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)  
Declare @TimeWindow int --Days (used for getting data in 'n' day blocks for number of points queries - Calculated Below On Number of Points Requested)
Declare @NoDataRetryCount int
/************************************************************************
-- **** For Testing  *****
--************************************************************************
Declare @PrimaryVariable int,
@StartTime datetime,
@EndTime datetime,
@NumberOfPoints int,
@Direction tinyint,
@IncludeSpecifications int,
@OtherVariables nvarchar(1000),
@EventType int,
@EventSubtype int,
@ProductCode nvarchar(50), 
@ContextType int,
@ContextName nvarchar(255),
@Command int
Select @PrimaryVariable = 17
--Select @PrimaryVariable = 463
Select @StartTime = '1-aug-01'
Select @EndTime = '15-oct-01'
Select @IncludeSpecifications = 1
Select @NumberOfPoints = 0
Select @Direction = 2
Select @OtherVariables = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26'
--Select @OtherVariables = '55,42,446,463'
Select @EventType = 1
Select @EventSubType = 2
Select @ProductCode = NULL --'70Gloss' --'<None>'
Select @ContextType = 2
Select @ContextName = 'PM1 Backtender Logsheet'
Select @Command = 2
--************************************************************************
--************************************************************************/
Declare @ProductId int
Declare @IsEventBased int
Declare @MasterUnit int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @SQL nvarchar(3000)
Declare @ColumnName nvarchar(25)
Declare @ColumnNumber int
Declare @VariableString nvarchar(25)
Declare @NumberOfRows int
Declare @TotalRows int
Declare @Retry int
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sUnspecified nVarChar(100)
SET @sUnspecified = dbo.fnTranslate(@LangId, 34519, '<Unspecified>')
--**********************************************
If @NumberOfPoints > 0 
  Begin
    Select @TimeWindow = 0
    Select @TimeWindow = @NumberOfPoints / 50
    If @TimeWindow = 0 
      Select @TimeWindow = 1
    Select @NoDataRetryCount = ((2 * 365) / @TimeWindow) + 1
  End
if @OtherVariables = ''
  Select @OtherVariables = null
If @ProductCode Is Not Null
  Begin
    Select @ProductId = Prod_id From products Where Prod_Code = @ProductCode
    If @ProductId Is Null
      Begin
        Raiserror('SP: Product Code Specified Was Not Found', 1, 1)
        Return  
      End
  End
Declare @SheetId int
Declare @NewVariable int
Declare @CurrentOrder int
Select @NewVariable = NULL
-- See If There Is A Command To Process To Find The Next Variable
If @ContextType = 1
  Begin
    -- 'Sheet' Context Type
    Select @SheetId = Sheet_id From Sheets where Sheet_Desc = @ContextName
    Select @CurrentOrder = var_order from Sheet_Variables where sheet_id = @SheetId and Var_id = @PrimaryVariable
    If @Command = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select min(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7)  and v.Pu_Id <> 0
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order > @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
    Else If @Command = 2
      Begin
        -- Scroll Up
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select max(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7) and v.Pu_Id <> 0
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order < @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
  End
Else If @ContextType = 2
  Begin
    -- 'Unit' Context Type
    Select @MasterUnit = pu_id from Variables Where Var_Id = @PrimaryVariable
    Select @CurrentOrder = 1000 * g.pug_order + v.pug_order from variables v join pu_groups g on g.pug_id = v.pug_id where v.var_id = @PrimaryVariable
    If @Command = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select min(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) > (@CurrentOrder)
                                 )
      End
    Else If @Command = 2
      Begin
        -- Scroll Up
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select max(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) < (@CurrentOrder)
                                 )
      End
  End
If @NewVariable Is Not Null
  Select @PrimaryVariable = @NewVariable
Select @MasterUnit = PU_Id, 
       @IsEventBased = Case When Event_Type = 1 Then 1 Else 0 End
  From Variables 
  Where Var_Id = @PrimaryVariable
Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
  From Prod_Units Where PU_Id = @MasterUnit
Create Table #Report
(
  [Timestamp] datetime, 
  ProductId int
)
CREATE INDEX Report_Times ON #Report ([Timestamp]) 
Create Table #ColumnInformation
(
  Number int,
  Type int,
  LongName nvarchar(100),
  ShortName nVarChar(100) NULL,
  EngineeringUnits nvarchar(25) NULL,
  [ID] int NULL
)
Select @VariableString = convert(nvarchar(25), @PrimaryVariable)
Select @ColumnName = '_' + convert(nvarchar(25), @PrimaryVariable)
--***********************************************************
-- Get The Timestamps / Data points For The Primary Variable
--***********************************************************
     If @NumberOfPoints = 0 or @NumberOfPoints Is Null
       -- If Time Based Query, Ignore Product Filter
       Select @ProductId = NULL
     Else
       -- If Number Points Based Query, Ignore Events
       Select @EventType = NULL
     If @IsEventBased = 1
       Begin
         -- This is an event based variable, get all the events first
         If @NumberOfPoints = 0 or @NumberOfPoints Is Null
           Begin
             -- Time Query
             Insert Into #Report ([Timestamp], ProductId)
               Select e.Timestamp, 
                      Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End
                 From Events e
                 Join Production_Starts ps on ps.PU_id = @MasterUnit and 
                                        ps.Start_Time <= e.Timestamp and 
                                      ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
                 Where e.PU_id = @MasterUnit and
                       e.Timestamp > @StartTime and 
                       e.Timestamp <= @EndTime          
           End
         Else
           Begin
             -- Number Of Points Query
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
                 If @ProductId Is Null
 	            Insert Into #Report ([Timestamp], ProductId)
 	              Select e.Timestamp, 
 	                     Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End
 	                From Events e
 	                Join Production_Starts ps on ps.PU_id = @MasterUnit and 
 	                                       ps.Start_Time <= e.Timestamp and 
 	                                     ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	                Where e.PU_id = @MasterUnit and
 	                      e.Timestamp > @MinTime and 
 	                      e.Timestamp <= @MaxTime          
                 Else
 	            Insert Into #Report ([Timestamp], ProductId)
 	              Select e.Timestamp, 
 	                     Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End
 	                From Events e
 	                Join Production_Starts ps on ps.PU_id = @MasterUnit and
 	                                       ps.Start_Time <= e.Timestamp and 
 	                                     ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
 	                Where e.PU_id = @MasterUnit and
 	                      e.Timestamp > @MinTime and 
 	                      e.Timestamp <= @MaxTime and
                             ((e.applied_product = @ProductId) or (ps.prod_Id = @ProductId))                              
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
         Select @MinTime = min([timestamp]),
                @MaxTime = max([timestamp])  
           From #Report
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Value real NULL'
        Execute (@SQL)
        Select @ColumnNumber = 3 
        Insert into #ColumnInformation  (Number, Type, LongName, ShortName, EngineeringUnits, ID)
          Select @ColumnNumber, 1, Var_Desc, Coalesce(Test_name, Var_Desc), Eng_Units, @PrimaryVariable
            From Variables Where Var_Id = @PrimaryVariable
        If @IncludeSpecifications = 1        
           Begin
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Target real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 2, 'Target')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_UWL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 3, 'UWL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_LWL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 4, 'LWL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_URL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 5, 'URL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_LRL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 6, 'LRL')
             Select @SQL = 'Update #Report Set ' + @ColumnName + '_Value = convert(real, t.Result), ' 
             Select @SQL = @SQL + @ColumnName + '_Target = convert(real,vs.target), ' 
             Select @SQL = @SQL + @ColumnName + '_UWL = convert(real,vs.u_warning), ' 
             Select @SQL = @SQL + @ColumnName + '_LWL = convert(real,vs.l_warning), ' 
             Select @SQL = @SQL + @ColumnName + '_URL = convert(real,vs.u_reject), ' 
             Select @SQL = @SQL + @ColumnName + '_LRL = convert(real,vs.l_reject) '
             Select @SQL = @SQL + 'From #Report r ' 
             Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + @VariableString + ' and t.Result_On = r.Timestamp and t.Result_On Between ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' + ' and ' + '''' + convert(nvarchar(30),@MaxTime,109) + ''''  
             Select @SQL = @SQL + 'Left Outer Join Var_Specs vs on vs.Var_Id = ' + @VariableString + ' and vs.Prod_Id = r.ProductId and vs.effective_date <= r.Timestamp and ((vs.expiration_date > r.Timestamp) or (vs.expiration_date Is Null)) ' 
             Execute (@SQL)
           End
        Else
           Begin
             Select @SQL = 'Update #Report Set ' + @ColumnName + '_Value = convert(real, t.Result) ' 
             Select @SQL = @SQL + 'From #Report r ' 
             Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + @VariableString + ' and t.Result_On = r.Timestamp and t.Result_On Between ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' + ' and ' + '''' + convert(nvarchar(30),@MaxTime,109) + ''''  
             Execute (@SQL)
           End 
       End
     Else
       Begin
         -- This is a time based variable, get the data directly
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Value real NULL'
        Execute (@SQL)
        Select @ColumnNumber = 3 
        Insert into #ColumnInformation  (Number, Type, LongName, ShortName, EngineeringUnits, ID)
          Select @ColumnNumber, 1, Var_Desc, Coalesce(Test_name, Var_Desc), Eng_Units, @PrimaryVariable
            From Variables Where Var_Id = @PrimaryVariable
        If @NumberOfPoints = 0 or @NumberOfPoints Is Null
          Begin
            -- This is a time query 
            Select @SQL = 'Insert Into #Report ( Timestamp, ProductId,' +  @ColumnName + '_Value) '
            Select @SQL = @SQL + 'Select t.result_on, ps.Prod_Id, convert(real,t.result) '
            Select @SQL = @SQL + 'From tests t Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(25), @MasterUnit) + ' and '  
            Select @SQL = @SQL + 'ps.Start_Time <= t.Result_on and ' 
            Select @SQL = @SQL + '((ps.End_Time > t.result_On) or (ps.End_Time Is Null)) '
            Select @SQL = @SQL + 'Where t.Var_id = ' + @VariableString  + ' and ' 
            Select @SQL = @SQL + 't.Result_On > ' + '''' + convert(nvarchar(30),@StartTime,109) + '''' +  ' and t.Result_On <= ' + '''' + convert(nvarchar(30),@endTime,109) + '''' + ' and t.result Is Not Null'  
            Execute (@SQL)
          End
        Else
          Begin
            -- This is a number of points query 
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
                 If @ProductId Is Null
                   Begin
     	              Select @SQL = 'Insert Into #Report ( Timestamp, ProductId,' +  @ColumnName + '_Value) '
 	              Select @SQL = @SQL + 'Select t.result_on, ps.Prod_Id, convert(real,t.result) '
 	              Select @SQL = @SQL + 'From tests t Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(25), @MasterUnit) + ' and '  
 	              Select @SQL = @SQL + 'ps.Start_Time <= t.Result_on and ' 
 	              Select @SQL = @SQL + '((ps.End_Time > t.result_On) or (ps.End_Time Is Null)) '
 	              Select @SQL = @SQL + 'Where t.Var_id = ' + @VariableString  + ' and ' 
 	              Select @SQL = @SQL + 't.Result_On > ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' +  ' and t.Result_On <= ' + '''' + convert(nvarchar(30),@MaxTime,109) + '''' + ' and t.result Is Not Null'  
 	              Execute (@SQL)
                   End
                 Else
                   Begin
     	              Select @SQL = 'Insert Into #Report ( Timestamp, ProductId,' +  @ColumnName + '_Value) '
 	              Select @SQL = @SQL + 'Select t.result_on, ps.Prod_Id, convert(real,t.result) '
 	              Select @SQL = @SQL + 'From tests t Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(25), @MasterUnit) + ' and ps.prod_id = '  + convert(nvarchar(25), @ProductId) + ' and ' 
 	              Select @SQL = @SQL + 'ps.Start_Time <= t.Result_on and ' 
 	              Select @SQL = @SQL + '((ps.End_Time > t.result_On) or (ps.End_Time Is Null)) '
 	              Select @SQL = @SQL + 'Where t.Var_id = ' + @VariableString  + ' and ' 
 	              Select @SQL = @SQL + 't.Result_On > ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' +  ' and t.Result_On <= ' + '''' + convert(nvarchar(30),@MaxTime,109) + '''' + ' and t.result Is Not Null'  
 	              Execute (@SQL)
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
        If @IncludeSpecifications = 1        
           Begin
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Target real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 2, 'Target')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_UWL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 3, 'UWL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_LWL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 4, 'LWL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_URL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 5, 'URL')
             Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_LRL real NULL'
             Execute (@SQL)
             Select @ColumnNumber = @ColumnNumber + 1 
             Insert into #ColumnInformation  (Number, Type, LongName)
               values( @ColumnNumber, 6, 'LRL')
             Select @SQL = 'Update #Report Set ' + @ColumnName + '_Target = convert(real,vs.target), ' 
             Select @SQL = @SQL + @ColumnName + '_UWL = convert(real,vs.u_warning), ' 
             Select @SQL = @SQL + @ColumnName + '_LWL = convert(real,vs.l_warning), ' 
             Select @SQL = @SQL + @ColumnName + '_URL = convert(real,vs.u_reject), ' 
             Select @SQL = @SQL + @ColumnName + '_LRL = convert(real,vs.l_reject) '
             Select @SQL = @SQL + 'From #Report r ' 
             Select @SQL = @SQL + 'Join Var_Specs vs on vs.Var_Id = ' + @VariableString + ' and vs.Prod_Id = r.ProductId and vs.effective_date <= r.Timestamp and ((vs.expiration_date > r.Timestamp) or (vs.expiration_date Is Null)) ' 
             Execute (@SQL)
           End
       End      
Select @MinTime = min([timestamp]),
       @MaxTime = max([timestamp])  
   From #Report
Declare @@VariableId int
-- Get The Data For The Secondary Variables
If @OtherVariables Is Not Null
  Begin
    Create Table #Variables (
      ItemOrder int Identity(1,1),
      Item int 
    )
    Insert Into #Variables 
      Execute ('Select distinct Var_id From Variables Where Var_id In (' + @OtherVariables + ') and var_id <> ' + @VariableString + ' and data_type_id in (1,2,6,7)')
    Declare Variable_Cursor Insensitive Cursor 
      For (Select Item From #Variables)
      For Read Only
    Open Variable_Cursor
    Fetch Next From Variable_Cursor Into @@VariableId
    While @@Fetch_Status = 0
      Begin
        Select @VariableString = convert(nvarchar(25),@@VariableId)
        Select @ColumnName = '_' + convert(nvarchar(25),@@VariableId)
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Value real NULL'
        Execute (@SQL)
        Select @ColumnNumber = @ColumnNumber + 1
        Insert into #ColumnInformation  (Number, Type, LongName, ShortName, EngineeringUnits, ID)
          Select @ColumnNumber, 1, Var_Desc, Coalesce(Test_name, Var_Desc), Eng_Units, @@VariableId
            From Variables Where Var_Id = @@VariableId
        Select @SQL = 'Update #Report Set ' + @ColumnName + '_Value = convert(real, t.Result) ' 
        Select @SQL = @SQL + 'From #Report r ' 
        Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + @VariableString + ' and t.Result_On = r.Timestamp and t.Result_On Between ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' + ' and ' + '''' + convert(nvarchar(30),@MaxTime,109) + ''''  
        Execute (@SQL)
        Fetch Next From Variable_Cursor Into @@VariableId
      End
    Close Variable_Cursor
    Deallocate Variable_Cursor  
    Drop Table #Variables
  End
Select * From #ColumnInformation
Update #Report Set timestamp = dbo.fnserver_CmnConvertFromDBTime(timestamp,@InTimeZone)
Select * From #Report
  order by timestamp ASC
Drop Table #Report
Drop Table #ColumnInformation
-- Return The Event Data If Requested
If @EventType Is Not Null
  Begin
    Create Table #Events (
      Label nvarchar(255) NULL,
      StartTime datetime NULL,
      EndTime datetime,
      Hyperlink nvarchar(255) NULL
    )
    If @EventType = 1
      Begin
        --*******************************************************************  
        -- Production Events 
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = e.event_num + ' (' + s.ProdStatus_Desc + ')',
 	  	              StartTime = e.Start_Time,
 	  	              EndTime = e.Timestamp,
 	  	  	  	          Hyperlink = '<Link>EventDetail.aspx?Id=' + convert(nvarchar(20),e.Event_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	     From Events e
 	  	  	  	     Join Production_Status s on s.ProdStatus_id = e.Event_Status
 	  	  	  	     Where e.PU_id = @MasterUnit and
 	  	  	  	           e.Timestamp > @StartTime and 
 	  	  	  	           e.Timestamp <= @EndTime 
 	  	  	             Order By e.Timestamp ASC
        -- Fill In Start Times If Necessary
        If (Select Count(StartTime) From #Events Where StartTime Is Not Null) = 0
          Begin
            Update #Events
              Set StartTime = (Select max(Events.Timestamp) From Events Where Events.PU_Id = @MasterUnit and Events.Timestamp < #Events.EndTime)
              From #Events
              Where #Events.StartTime Is Null  
          End
      End
    Else If @EventType = 2
      Begin
        --*******************************************************************  
        -- Downtime
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name,@sUnspecified)),
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	    	  	 From Timed_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	  	  	  	   Where d.PU_id = @MasterUnit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Timed_Event_Details t Where t.PU_Id = @MasterUnit and t.start_time < @StartTime) and
 	  	  	    	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
  	  	  	  	 Union
 	  	    	   Select Label = coalesce('(' + tef.tefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)),
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>DowntimeDetail.aspx?Id=' + convert(nvarchar(20),d.tedet_Id) + '&TargetTimeZone='+ @InTimeZone +'</Link>'
 	  	  	  	  	  	   From Timed_Event_Details d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	           Left Outer Join Timed_Event_Fault tef on tef.tefault_id = d.tefault_id
 	  	           Where d.PU_id = @MasterUnit and
 	  	                 d.Start_Time > @StartTime and 
 	  	  	      	  	  	     d.Start_Time <= @EndTime 
      End
    Else If @EventType = 3
      Begin
        --*******************************************************************  
        -- Waste
        --*******************************************************************  
        --TODO Join In Production Rate Specification To Estimate Start Time 
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)), 
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	  	  	          Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	   From Waste_Event_Details d
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	  	  	  	   Where d.PU_id = @MasterUnit and
 	  	  	    	  	       d.Timestamp > @StartTime and 
 	  	               d.Timestamp <= @EndTime and
 	  	               d.Event_Id Is Null
 	  	  	  	 Union
 	  	    	   Select Label = coalesce('(' + wef.wefault_name + ')', coalesce(r1.event_reason_name, @sUnspecified)), 
 	  	              StartTime = d.Timestamp,
 	  	              EndTime = d.Timestamp,
 	  	  	  	          Hyperlink = '<Link>WasteDetail.aspx?Id=' + convert(nvarchar(20),d.wed_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	 From Events e
 	  	  	    	  	 Join Waste_Event_Details d on d.event_id = e.event_id
 	  	         Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.reason_level1
 	  	         Left Outer Join Waste_Event_Fault wef on wef.wefault_id = d.wefault_id
 	  	         Where e.PU_id = @MasterUnit and
 	  	  	  	  	         e.Timestamp > @StartTime and 
 	  	  	  	  	         e.Timestamp <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventType = 4
      Begin
        --*******************************************************************  
        -- Product Change
        --*******************************************************************  
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = p.Prod_code,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProductChangeDetail.aspx?Id=' + convert(nvarchar(20),d.start_Id) + '&TargetTimeZone='+ @InTimeZone +'</Link>'
 	  	  	  	  	   From Production_Starts d
 	  	         Join Products p on p.prod_id = d.prod_id
 	  	  	  	  	   Where d.PU_id = @MasterUnit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Starts t Where t.PU_Id = @MasterUnit and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Label = p.Prod_code,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProductChangeDetail.aspx?Id=' + convert(nvarchar(20),d.start_Id) + '&TargetTimeZone='+ @InTimeZone +'</Link>'
 	  	   	  	   From Production_Starts d
 	  	       Join Products p on p.prod_id = d.prod_id
 	  	       Where d.PU_id = @MasterUnit and
 	  	             d.Start_Time > @StartTime and 
 	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventType = 11 
      Begin
        --*******************************************************************  
        -- Alarms
        --*******************************************************************  
        -- Event Subtype Id = Variable Id
        Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = d.alarm_desc,
               StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
               EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	          Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	   From Alarms d
          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	   Where d.Key_Id = @EventSubtype and
                d.Alarm_Type_Id in (1,2) and 
 	    	  	         d.Start_Time = (Select Max(Start_Time) From Alarms t Where t.Key_Id = @EventSubtype and t.Alarm_Type_Id in (1,2) and t.start_time < @StartTime) and
 	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
       Union
 	  	    	   Select Label = d.alarm_desc,
               StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
               EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	          Hyperlink = '<Link>AlarmDetail.aspx?Id=' + convert(nvarchar(20),d.Alarm_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	   From Alarms d
          Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	   Where d.Key_Id = @EventSubtype and
                d.Alarm_Type_Id in (1,2) and 
 	               d.Start_Time > @StartTime and 
 	  	          	  	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventType = 14 
      Begin
        --*******************************************************************  
        -- User Defined Events
        --*******************************************************************  
        Declare @UDEType int
 	  	  	  	 Select @UDEType = duration_required From Event_Subtypes Where event_subtype_id = @EventSubtype
 	  	  	  	 If @UDEType = 1 
         	 Begin
            -- Both Start and End Times Apply
           	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	    	  	    	   Select Label = coalesce(r1.event_reason_name, @sUnspecified), 
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @MasterUnit and
                    d.Event_Subtype_id = @EventSubtype and
 	  	  	    	  	         d.Start_Time = (Select Max(Start_Time) From User_Defined_Events t Where t.PU_Id = @MasterUnit and t.Event_Subtype_id = @EventSubtype and t.start_time < @StartTime) and
 	  	  	  	   	         ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	          Union
 	    	  	    	   Select Label = coalesce(r1.event_reason_name, @sUnspecified), 
 	                  StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	                  EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @MasterUnit and
                    d.Event_Subtype_id = @EventSubtype and
 	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
            -- Only Start Time Applies
           	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	    	  	    	   Select Label = coalesce(r1.event_reason_name, @sUnspecified),
 	                  StartTime = d.Start_time,
 	                  EndTime = d.Start_Time,
 	  	  	  	  	          Hyperlink = '<Link>UserDefinedEventDetail.aspx?Id=' + convert(nvarchar(20),d.UDE_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	  	   From User_Defined_Events d
 	  	           Left Outer Join Event_Reasons r1 on r1.event_reason_id = d.cause1
 	  	  	  	  	  	   Where d.PU_Id = @MasterUnit and
                    d.Event_Subtype_id = @EventSubtype and
 	  	  	               d.Start_Time > @StartTime and 
 	  	  	  	          	  	 d.Start_Time <= @EndTime 
 	  	  	  	  	 End
        --*******************************************************************  
      End
    Else If @EventType = 19 
      Begin
        --*******************************************************************  
        -- Process Orders
        --*******************************************************************  
        	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select Label = pp.Process_Order + ' (' +  s.pp_status_desc + ')',
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone='+ @InTimeZone +  '</Link>'
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	  	  	   Where d.PU_id = @MasterUnit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts t Where t.PU_Id = @MasterUnit and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select Label = pp.Process_Order + ' (' +  s.pp_status_desc + ')',
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = '<Link>ProcessOrderDetail.aspx?Id=' + convert(nvarchar(20),pp.pp_Id) + '&TargetTimeZone='+ @InTimeZone + '</Link>'
 	  	  	  	  	   From Production_Plan_Starts d
 	           Join Production_Plan pp on pp.pp_id = d.pp_id
 	           Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
 	  	  	       Where d.PU_id = @MasterUnit and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    Else If @EventType = 0 
      Begin
        --*******************************************************************  
        -- Crew Schedule
        --*******************************************************************  
        	 Insert Into #Events (Label, StartTime, EndTime, Hyperlink)
 	  	    	   Select LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = NULL
 	  	  	  	  	   From crew_schedule d
 	  	  	  	  	   Where d.PU_id = @MasterUnit and
 	  	  	    	  	       d.Start_Time = (Select Max(Start_Time) From crew_schedule t Where t.PU_Id = @MasterUnit and t.start_time < @StartTime) and
 	  	  	     	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
 	  	  	  	 Union
 	  	    	   Select LongLabel = d.crew_desc + ' - ' + d.shift_desc,
 	  	              StartTime = Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
 	  	              EndTime = coalesce(d.End_Time, @EndTime),
 	  	  	  	          Hyperlink = NULL
 	  	  	  	  	   From crew_schedule d
 	  	  	       Where d.PU_id = @MasterUnit and
 	  	  	             d.Start_Time > @StartTime and 
 	  	  	  	          	 d.Start_Time <= @EndTime 
        --*******************************************************************  
      End
    -- Select * from #Events  Order By EndTime ASC --Sarla
 	 select Label,
      'StartTime' = [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone)  , 
      'EndTime' =  [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone) ,
      Hyperlink
 	 from #Events
      Order By EndTime ASC
    Drop Table #Events
  End
