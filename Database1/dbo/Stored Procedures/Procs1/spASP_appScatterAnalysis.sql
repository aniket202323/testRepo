CREATE procedure [dbo].[spASP_appScatterAnalysis]
@PrimaryVariable int,
@StartTime datetime,
@EndTime datetime,
@NumberOfPoints int,
@Direction tinyint,
@OtherVariables nvarchar(1000),
@ProductId Int,
@FilterNPTime Int = NULL,
@InTimeZone nvarchar(200) = NULL
AS
Declare @TimeWindow int --Days (used for getting data in 'n' day blocks for number of points queries - Calculated Below On Number of Points Requested)
Declare @NoDataRetryCount int
/************************************************************************
-- **** For Testing  *****
--************************************************************************
Select @PrimaryVariable = 17
--Select @PrimaryVariable = 463
Select @StartTime = '1-aug-01'
Select @EndTime = '15-oct-01'
Select @NumberOfPoints = 0
Select @Direction = 2
Select @OtherVariables = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26'
--Select @OtherVariables = '55,42,446,463'
Select @ProductCode = NULL --'70Gloss' --'<None>'
--************************************************************************
--************************************************************************/
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
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
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
Select @MasterUnit = PU_Id, 
       @IsEventBased = Case When Event_Type = 1 Then 1 Else 0 End
  From Variables 
  Where Var_Id = @PrimaryVariable
Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
  From Prod_Units Where PU_Id = @MasterUnit
Create Table #Report (
  Timestamp datetime, 
  ProductId int
)
CREATE INDEX Report_Times ON #Report (Timestamp) 
Create Table #ColumnInformation (
  Number int,
  Type int,
  LongName nvarchar(100),
  ShortName nVarChar(100) NULL,
  EngineeringUnits nvarchar(25) NULL,
  ID int NULL
)
Select @VariableString = convert(nvarchar(25),@PrimaryVariable)
Select @ColumnName = '_' + convert(nvarchar(25),@PrimaryVariable)
--***********************************************************
-- Get The Timestamps / Data points For The Primary Variable
--***********************************************************
     If @NumberOfPoints = 0 or @NumberOfPoints Is Null
       -- If Time Based Query, Ignore Product Filter
       Select @ProductId = NULL 
     If @IsEventBased = 1 and @ProductId Is Not Null
       Begin
         -- This is an event based variable requesting product, need to get all the events first
         If @NumberOfPoints = 0 or @NumberOfPoints Is Null
           Begin
             -- Time Query
             Insert Into #Report (Timestamp, ProductId)
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
 	  	  	  	            Insert Into #Report (Timestamp, ProductId)
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
 	  	  	  	            Insert Into #Report (Timestamp, ProductId)
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
         Select @MinTime = min(timestamp),
                @MaxTime = max(timestamp)  
           From #Report
        Select @SQL = 'Alter Table #Report Add ' + @ColumnName + '_Value real NULL'
        Execute (@SQL)
        Select @ColumnNumber = 3 
        Insert into #ColumnInformation  (Number, Type, LongName, ShortName, EngineeringUnits, ID)
          Select @ColumnNumber, 1, Var_Desc, Coalesce(Test_name, Var_Desc), Eng_Units, @PrimaryVariable
            From Variables Where Var_Id = @PrimaryVariable
 	        Select @SQL = 'Update #Report Set ' + @ColumnName + '_Value = convert(real, t.Result) ' 
 	        Select @SQL = @SQL + 'From #Report r ' 
 	        Select @SQL = @SQL + 'Join Tests t on t.Var_id = ' + @VariableString + ' and t.Result_On = r.Timestamp and t.Result_On Between ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' + ' and ' + '''' + convert(nvarchar(30),@MaxTime,109) + ' '''
 	  	  	  	  Select @SQL = @SQL + 'Join Variables v On t.Var_Id = v.Var_Id '
 	  	  	  	  	 
 	  	  	  	  If @FilterNPTime Is Not Null And @FilterNPTime = 1
 	  	  	  	  	  Select @SQL = @SQL + 'Where dbo.fnWA_IsNonProductiveTime(v.PU_Id, t.Result_On, NULL) = 0 '
 	        Execute (@SQL)
       End
     Else
       Begin
         -- This is a time based variable or product is not requested get the data directly without getting events first
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
            Select @SQL = @SQL + 'From tests t Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(25), @MasterUnit) + case when @ProductId Is Not Null Then ' and ps.prod_id = '  + convert(nvarchar(25), @ProductId) + ' and ' Else ' and ' End    
            Select @SQL = @SQL + 'ps.Start_Time <= t.Result_on and ' 
            Select @SQL = @SQL + '((ps.End_Time > t.result_On) or (ps.End_Time Is Null)) '
 	  	  	  	  	  	 Select @SQL = @SQL + 'Join Variables v On t.Var_Id = v.Var_Id '
            Select @SQL = @SQL + 'Where t.Var_id = ' + @VariableString  + ' and ' 
            Select @SQL = @SQL + 't.Result_On > ' + '''' + convert(nvarchar(30),@StartTime,109) + '''' +  ' and t.Result_On <= ' + '''' + convert(nvarchar(30),@endTime,109) + '''' + ' and t.result Is Not Null '  
 	  	  	  	  If @FilterNPTime Is Not Null And @FilterNPTime = 1
 	  	  	  	  	  Select @SQL = @SQL + 'And dbo.fnWA_IsNonProductiveTime(v.PU_Id, t.Result_On, NULL) = 0 '
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
   	              Select @SQL = 'Insert Into #Report ( Timestamp, ProductId,' +  @ColumnName + '_Value) '
 	  	              Select @SQL = @SQL + 'Select t.result_on, ps.Prod_Id, convert(real,t.result) '
         	  	  	  	  Select @SQL = @SQL + 'From tests t Join Production_Starts ps on ps.PU_id = ' + convert(nvarchar(25), @MasterUnit) + case when @ProductId Is Not Null Then ' and ps.prod_id = '  + convert(nvarchar(25), @ProductId) + ' and ' Else ' and ' End    
 	  	  	  	  	  	  	  	  Select @SQL = @SQL + 'Join Variables v On t.Var_Id = v.Var_Id '
 	  	              Select @SQL = @SQL + 'ps.Start_Time <= t.Result_on and ' 
 	  	              Select @SQL = @SQL + '((ps.End_Time > t.result_On) or (ps.End_Time Is Null)) '
 	  	              Select @SQL = @SQL + 'Where t.Var_id = ' + @VariableString  + ' and ' 
 	  	              Select @SQL = @SQL + 't.Result_On > ' + '''' + convert(nvarchar(30),@MinTime,109) + '''' +  ' and t.Result_On <= ' + '''' + convert(nvarchar(30),@MaxTime,109) + '''' + ' and t.result Is Not Null '  
 	  	  	  	  	  	  	  	  
 	  	  	  	  If @FilterNPTime Is Not Null And @FilterNPTime = 1
 	  	  	  	  	  Select @SQL = @SQL + 'And dbo.fnWA_IsNonProductiveTime(v.PU_Id, t.Result_On, NULL) = 0 '
 	  	              Execute (@SQL)
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
Select @MinTime = min(timestamp),
       @MaxTime = max(timestamp)  
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
 	  	  	  	 Select @SQL = @SQL + 'Join Variables v On t.Var_Id = v.Var_Id ' 
 	  	  	  	  	  	  	  	  If @FilterNPTime Is Not Null And @FilterNPTime = 1
 	  	  	  	  	  Select @SQL = @SQL + 'Where dbo.fnWA_IsNonProductiveTime(v.PU_Id, t.Result_On, NULL) = 0 '
        Execute (@SQL)
        Fetch Next From Variable_Cursor Into @@VariableId
      End
    Close Variable_Cursor
    Deallocate Variable_Cursor  
    Drop Table #Variables
  End
Select * From #ColumnInformation
If @ProductId Is Null
  Begin
    Create Table #Products (
      Id int
    )
    Insert Into #Products
      Select Distinct ProductId 
        From #Report
    Select ProductId = Id, ProductCode = p.Prod_Code
      From #Products 
      Join Products p on p.Prod_Id = #Products.Id
      Order By ProductCode ASC
    Drop Table #Products
  End
Else
  Begin
    Select ProductId = @ProductId, ProductCode = (Select Prod_Code From Products Where Prod_id = @ProductId)
  End
Update #Report Set timestamp = dbo.fnServer_CmnConvertFromDBTime(timestamp,@InTimeZone)
Select * From #Report
  order by timestamp ASC
Drop Table #Report
Drop Table #ColumnInformation
