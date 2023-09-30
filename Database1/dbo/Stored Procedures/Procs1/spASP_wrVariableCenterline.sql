CREATE PROCEDURE [dbo].[spASP_wrVariableCenterline]
--Declare
@SheetName nvarchar(100),
@StartTime datetime,
@EndTime datetime,
@NonProductiveTimeFilter bit = 0,
@ProductIdIn int = null,
@Events 	 varchar(8000) = null,
@InTimeZone nvarchar(200)=NULL,
@NumberOfPoints int = null
AS
--TODO: Look at specification activation
set arithignore on
set arithabort off
set ansi_warnings off
/*******************************************
-- For Testing
Select @SheetName = 'PM1 Backtender Logsheet'
Select @StartTime = '2001-10-01'
Select @EndTime = '2001-10-03'
--*******************************************/
If DATALENGTH(@Events) > 7500
Begin
 	 Raiserror('Maximum Number Of Events In Filter Exceeded',16,1)
    return
End
select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
--Run the query
Declare @SQL varchar(8000)
Create Table #SelectedEvents(
   EventId Int
)
If @Events Is Not Null
Begin
  Select @SQL = 'Insert Into #SelectedEvents(EventId) Select Event_Id From Events Where Event_Id In (' + @Events + ')'
  Exec(@SQL)
End 
-- Get Sheet Information
Create Table #Variables (
  VariableId int,
  VariableOrder int NULL 
)
Declare @SheetId int
Select @SheetId = NULL
Select @SheetId = Sheet_Id 
  From Sheets 
  Where Sheet_Desc = @SheetName
/*
select * from Sheets
*/
If @SheetId Is Null
BEGIN
  SELECT @SheetId = MIN(Sheet_Id)
  FROM Sheets
END
-- Get Sheet Variables
Insert into #Variables
  Select v.Var_Id, sv.Var_Order
    From Sheet_Variables sv 
    Join Variables v on v.var_id = sv.var_id and v.data_type_id in (1,2,6,7)
    Where sv.Sheet_Id = @SheetId and
          sv.Var_Id Is Not Null
Declare @UpperRejectColor int
Declare @UpperWarningColor int
Declare @TargetColor int
Declare @LowerWarningColor int
Declare @LowerRejectColor int
Declare @UpperReject real
Declare @UpperWarning real
Declare @Target real
Declare @LowerWarning real
Declare @LowerReject real
Declare @CSId Int
Select @CSId = Value from sheet_Display_options where display_Option_Id = 31 and Sheet_Id = @SheetId
Select @CSId = Coalesce(@CSId,1)
--Select @UpperRejectColor = 141
Select @UpperRejectColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 78
Select @LowerRejectColor = @UpperRejectColor
--Select @TargetColor = 79
Select @TargetColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 77
--Select @UpperWarningColor = 37
Select @UpperWarningColor = coalesce(csd.Color_Scheme_Value,csf.Default_Color_Scheme_Color)
From  Color_Scheme_Fields csf  
Left Join Color_Scheme_Data csd On csd.Color_Scheme_Field_Id = csf.Color_Scheme_Field_Id and CS_Id = @CSId
Where   csf.Color_Scheme_Field_Id = 79
Select @LowerWarningColor = @UpperWarningColor
Declare @Average real
Declare @StdDev real
Declare @Minimum real
Declare @Maximum real
Declare @AlarmCount int
Declare @CommentCount int
Declare @SpecSetting Int
Select @SpecSetting = value from site_Parameters where parm_Id = 13 and hostname =''
Select @SpecSetting = Coalesce(@SpecSetting,1) 
Declare @@VariableId int
Declare @MasterUnit int
Declare @ProductId int
Declare @RunStartTime datetime
Declare @RunEndTime datetime
Declare @LastUnit int
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
Select @LastUnit = 0
Create Table #Data (
  [Timestamp] datetime,
  Value real NULL,
  Color int NULL,
  CommentId int NULL,
  EventId int NULL,
  EventNumber nvarchar(25)
)
-- Cursor Through Each Variable
Declare Variable_Cursor Insensitive Cursor 
  For Select VariableId From #Variables Order By VariableOrder
  For Read Only
Open Variable_Cursor
Fetch Next From Variable_Cursor Into @@VariableId
While @@Fetch_Status = 0
  Begin
    Select @MasterUnit = Case When pu.Master_Unit Is Null Then pu.PU_Id Else pu.Master_Unit End
      From Variables v
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Where Var_Id = @@VariableId
    If @LastUnit <> @MasterUnit 
      Begin
 	  	 if @ProductIdIn is NULL
 	  	 begin
 	  	  	 If @Events is not null -- get the product applied for this event
 	  	  	 begin
 	  	  	  	 declare @eEndTime as datetime
 	  	  	  	 select @ProductId = Applied_Product, @eEndTime = e.timestamp from events e 
 	  	  	  	  	 where event_id in (Select eventId From #SelectedEvents)
 	  	  	  	 Select @ProductId = coalesce(@ProductId, Prod_Id),
 	  	  	  	  	    @RunStartTime = Start_Time,
 	  	  	  	  	    @RunEndTime = coalesce(End_Time, @EndTime)
 	  	  	  	   From Production_Starts 
 	  	  	  	   Where PU_Id = @MasterUnit and
 	  	  	  	  	  	 Start_Time <= @eEndTime and
 	  	  	  	  	  	 ((End_Time > @eEndTime) or (End_Time Is NULL))
 	  	  	  	 If @RunStartTime < @StartTime 
 	  	  	  	   Select @RunStartTime = @StartTime   
 	  	  	  	 If @RunEndTime > @EndTime 
 	  	  	  	   Select @RunEndTime = @EndTime
 	  	  	 end
 	  	  	 else  -- none of events or product is passed. do as before.
 	  	  	 begin 
 	  	  	  	 Select @ProductId = Prod_Id,
 	  	  	  	  	    @RunStartTime = Start_Time,
 	  	  	  	  	    @RunEndTime = coalesce(End_Time, @EndTime)
 	  	  	  	   From Production_Starts 
 	  	  	  	   Where PU_Id = @MasterUnit and
 	  	  	  	  	  	 Start_Time <= @EndTime and
 	  	  	  	  	  	 ((End_Time > @EndTime) or (End_Time Is NULL))
 	  	         
 	  	  	  	 If @RunStartTime < @StartTime 
 	  	  	  	   Select @RunStartTime = @StartTime   
 	  	  	  	 If @RunEndTime > @EndTime 
 	  	  	  	   Select @RunEndTime = @EndTime
 	  	  	 end
 	  	 end
 	  	 else -- if product is passed get all the specs based on the product passed
 	  	 begin
 	  	  	 Select @ProductId = @ProductIdIn
 	  	  	 Select @RunStartTime = @StartTime   
 	  	  	 Select @RunEndTime = @EndTime
 	  	 end
        Select @LastUnit = @MasterUnit
      End
    -- Get Specification Limits
    Select @UpperReject = NULL
    Select @LowerReject = NULL
    Select @UpperWarning = NULL
    Select @LowerWarning = NULL
    Select @Target = NULL
    Select @Average = NULL
    Select @StdDev = NULL
    Select @UpperReject = convert(real,u_reject), @LowerReject = convert(real,l_reject), 
           @UpperWarning = convert(real,u_warning), @LowerWarning = convert(real,l_warning), 
           @Target = convert(real,target)
      From Var_Specs 
      Where Var_Id = @@VariableId and 
            Prod_Id = @ProductId and 
            effective_date <= @RunEndTime and 
           (Expiration_Date > @RunEndTime or Expiration_Date Is Null)
    -- Calculate Specifications From Historical Data If Necessary
    If @Target Is Null
      Begin
        If @UpperReject Is Not Null and @LowerReject Is Not Null
          Select @Target = (@UpperReject + @LowerReject) / 2.0
        Else If @UpperWarning Is Not Null and @LowerWarning Is Not Null
          Select @Target = (@UpperWarning + @LowerWarning) / 2.0
        Else
          Begin
            -- Go To RSum Data
            Select @Average = avg(convert(real,d.value)), @StdDev = avg(d.StDev)
              From gb_rsum g
              Join gb_rsum_data d on d.rsum_id = g.rsum_id and d.var_id = @@VariableId
              Where g.PU_id = @MasterUnit and
                    g.Prod_id = @ProductId and
                    g.Start_Time between dateadd(day,-180,@StartTime) and @EndTime
            Select @Target = @Average
         End
      End
    If @UpperReject Is Null
      Begin
        If @UpperWarning Is Not Null and @Target Is Not Null
          Select @UpperReject = ((@UpperWarning - @Target) * 3.0 / 2.0) + @Target
        Else If @LowerReject Is Not Null and @Target Is Not Null
          Select @UpperReject = (@Target - @LowerReject) + @Target
        Else If @LowerWarning Is Not Null and @Target Is Not Null
          Select @UpperReject = ((@Target - @LowerWarning) * 3.0 / 2.0) + @Target
        Else
          Begin
            -- Go To RSum Data
            If @Average Is Null
              Begin
 	  	             Select @Average = avg(convert(real,d.value)), @StdDev = avg(d.StDev)
 	  	               From gb_rsum g
 	  	               Join gb_rsum_data d on d.rsum_id = g.rsum_id and d.var_id = @@VariableId
 	  	               Where g.PU_id = @MasterUnit and
 	  	                     g.Prod_id = @ProductId and
 	  	                     g.Start_Time between dateadd(day,-180,@StartTime) and @EndTime
              End
            If @StdDev > 0.0 
              Select @UpperReject = @Target + 3.0 * @StdDev
          End
      End   
    If @LowerReject Is Null
      Begin
        If @LowerWarning Is Not Null and @Target Is Not Null
          Select @LowerReject = @Target - ((@Target - @LowerWarning) * 3.0 / 2.0) 
        Else If @UpperReject Is Not Null and @Target Is Not Null
          Select @LowerReject = @Target - (@UpperReject - @Target)
        Else If @UpperWarning Is Not Null and @Target Is Not Null
          Select @LowerReject = @Target - ((@UpperWarning - @Target) * 3.0 / 2.0) 
        Else
          Begin
            -- Go To RSum Data
            If @Average Is Null
              Begin
 	  	             Select @Average = avg(convert(real,d.value)), @StdDev = avg(d.StDev)
 	  	               From gb_rsum g
 	  	               Join gb_rsum_data d on d.rsum_id = g.rsum_id and d.var_id = @@VariableId
 	  	               Where g.PU_id = @MasterUnit and
 	  	                     g.Prod_id = @ProductId and
 	  	                     g.Start_Time between dateadd(day,-180,@StartTime) and @EndTime
              End
            If @StdDev > 0.0 
              Select @LowerReject = @Target - 3.0 * @StdDev
          End
      End   
    If @UpperWarning Is Null
      Begin
        If @LowerWarning Is Not Null and @Target Is Not Null
          Select @UpperWarning = (@Target - @LowerWarning) + @Target
        Else If @UpperReject Is Not Null and @Target Is Not Null
          Select @UpperWarning = ((@UpperReject - @Target) * 2.0 / 3.0) + @Target
        Else If @LowerReject Is Not Null and @Target Is Not Null
          Select @UpperWarning = ((@Target - @LowerReject) * 2.0 / 3.0) + @Target
        Else
          Begin
            -- Go To RSum Data
            If @Average Is Null
              Begin
 	  	             Select @Average = avg(convert(real,d.value)), @StdDev = avg(d.StDev)
 	  	               From gb_rsum g
 	  	               Join gb_rsum_data d on d.rsum_id = g.rsum_id and d.var_id = @@VariableId
 	  	               Where g.PU_id = @MasterUnit and
 	  	                     g.Prod_id = @ProductId and
 	  	                     g.Start_Time between dateadd(day,-180,@StartTime) and @EndTime
              End
            If @StdDev > 0.0 
              Select @UpperWarning = @Target + 2.0 * @StdDev
          End
      End   
    If @LowerWarning Is Null
      Begin
        If @UpperWarning Is Not Null and @Target Is Not Null
          Select @LowerWarning = @Target - (@UpperWarning - @Target) 
        Else If @UpperReject Is Not Null and @Target Is Not Null
          Select @LowerWarning = @Target - ((@UpperReject - @Target) * 2.0 / 3.0)
        Else If @LowerReject Is Not Null and @Target Is Not Null
          Select @LowerWarning = @Target - ((@Target - @LowerReject) * 2.0 / 3.0)
        Else
          Begin
            -- Go To RSum Data
            If @Average Is Null
              Begin
 	  	             Select @Average = avg(convert(real,d.value)), @StdDev = avg(d.StDev)
 	  	               From gb_rsum g
 	  	               Join gb_rsum_data d on d.rsum_id = g.rsum_id and d.var_id = @@VariableId
 	  	               Where g.PU_id = @MasterUnit and
 	  	                     g.Prod_id = @ProductId and
 	  	                     g.Start_Time between dateadd(day,-180,@StartTime) and @EndTime
              End
            If @StdDev > 0.0 
              Select @LowerWarning = @Target - 2.0 * @StdDev
          End
      End   
    -- Get Data For Time Period
    Truncate Table #Data
 	 if (@ProductIdIn is NULL and @Events is NULL)
 	 begin
    Insert into #Data (Timestamp, Value, Color, CommentId,EventId)
 	     Select Timestamp = t.Result_On, Value = convert(real,t.Result),
 	            Color = Case 
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) > @UpperReject) Then @UpperRejectColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) < @LowerReject) Then @LowerRejectColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) > @UpperWarning) Then @UpperWarningColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) < @LowerWarning) Then @LowerWarningColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) >= @UpperReject) Then @UpperRejectColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) <= @LowerReject) Then @LowerRejectColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) >= @UpperWarning) Then @UpperWarningColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) <= @LowerWarning) Then @LowerWarningColor
 	                      Else
 	                        @TargetColor
 	                    End,
             CommentId = t.Comment_Id,
             t.Event_Id
 	       From Tests_NPT t
 	       Where t.Var_Id = @@VariableId and
 	             t.Result_On >= @RunStartTime and 
 	             t.Result_On <= @RunEndTime and
 	             t.Result Is Not Null and
 	  	  	  	 (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0)     	 
 	 end
 	 else
 	 begin
    Insert into #Data (Timestamp, Value, Color, CommentId,EventId)
 	     Select Timestamp = t.Result_On, Value = convert(real,t.Result),
 	            Color = Case 
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) > @UpperReject) Then @UpperRejectColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) < @LowerReject) Then @LowerRejectColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) > @UpperWarning) Then @UpperWarningColor
 	                      When (@SpecSetting = 1) and (convert(real,t.Result) < @LowerWarning) Then @LowerWarningColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) >= @UpperReject) Then @UpperRejectColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) <= @LowerReject) Then @LowerRejectColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) >= @UpperWarning) Then @UpperWarningColor
 	                      When (@SpecSetting = 2) and (convert(real,t.Result) <= @LowerWarning) Then @LowerWarningColor
 	                      Else
 	                        @TargetColor
 	                    End,
             CommentId = t.Comment_Id,
             t.Event_Id
 	       From Tests_NPT t
 	  	   --Filter By ProductId and Events 
 	  	  	 left join events e on t.event_id = e.event_id          	              
 	  	  	 Left Join Production_Starts ps2 on (@ProductId Is Null Or @ProductId = ps2.prod_id)
 	  	  	  	  	  	  	  	  	  	  	  	    --ps1.prod_id = 4 
 	  	  	  	  	  	  	  	  	  	  	  	    and ps2.PU_id = @MasterUnit 
 	  	  	  	  	  	  	  	  	  	  	  	    and ps2.Start_Time < t.Result_on 
 	  	  	  	  	  	  	  	  	  	  	  	    and (ps2.End_Time >= t.result_On or ps2.End_Time Is Null)
 	       Where t.Var_Id = @@VariableId and
 	             t.Result_On >= @RunStartTime and 
 	             t.Result_On <= @RunEndTime and
 	             t.Result Is Not Null and
 	  	  	  	 (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0)     	 
 	  	  	  	 and (@ProductId Is Null 
 	  	  	  	  	 Or @ProductId = case when e.applied_product is not null then e.applied_product else ps2.prod_id end)
 	  	  	  	 AND (@Events IS NULL 
 	  	  	  	  	 OR e.Event_Id IN (SELECT EventId FROM #SelectedEvents))  	 
 	 end 	 
    -- Get Statistics
    Select @Average = NULL
    Select @StdDev = NULL
    Select @Minimum = NULL
    Select @Maximum = NULL
    Select @CommentCount = 0
    Select @Average = avg(value), @StdDev = stdev(value), @Minimum = min(value), @Maximum = max(value), @CommentCount = count(CommentId)
      From #Data
    -- Get Alarm Count
    Select @AlarmCount = 0
    Select @AlarmCount = count(alarm_id)
      From Alarms 
      Where Key_Id = @@VariableId and
            Alarm_Type_id in (1,2) and
            Start_Time <= @EndTime and 
            ((End_Time > @EndTime) or (End_Time Is Null))
    -- Return Variable Information First
    Select Id = v.Var_id, LongName = v.Var_Desc, ShortName = v.Test_Name, 
           EngineeringUnits = v.Eng_Units, Unit = pu.PU_Desc, UnitId = pu.PU_ID ,
           CommentCount = @CommentCount,
           AlarmCount = @AlarmCount,
           Average = @Average,
 	    StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (@StartTime,@InTimeZone)   , 
  	    EndTime = [dbo].[fnServer_CmnConvertFromDbTime] ( @EndTime,@InTimeZone)  ,
 	          Color = Case 
                     When (@SpecSetting = 1) and (@Average > @UpperReject) Then @UpperRejectColor
                     When (@SpecSetting = 1) and (@Average < @LowerReject) Then @LowerRejectColor
                     When (@SpecSetting = 1) and (@Average > @UpperWarning) Then @UpperWarningColor
                     When (@SpecSetting = 1) and (@Average < @LowerWarning) Then @LowerWarningColor
                     When (@SpecSetting = 2) and (@Average >= @UpperReject) Then @UpperRejectColor
                     When (@SpecSetting = 2) and (@Average <= @LowerReject) Then @LowerRejectColor
                     When (@SpecSetting = 2) and (@Average >= @UpperWarning) Then @UpperWarningColor
                     When (@SpecSetting = 2) and (@Average <= @LowerWarning) Then @LowerWarningColor
                     Else
                       @TargetColor
                   End,
           Minimum = @Minimum, Maximum = @Maximum,
           UpperBound = @Average + 3.0 * @StdDev, LowerBound = @Average - 3.0 * @StdDev,
           Target = @Target,
           UpperReject = @UpperReject,
           LowerReject = @LowerReject,
           UpperWarning = @UpperWarning,
           LowerWarning = @LowerWarning,
 	  	    TargetTimeZone = @InTimeZone,
 	  	    No_Of_Datapoints = @NumberOfPoints 
      From Variables v
      Join Prod_Units pu on pu.pu_id = v.pu_id
      Where v.Var_Id = @@VariableId    
 	 Update d set EventNumber  = e.Event_Num
 	 FROM Events e JOIN #Data d ON e.Event_Id = d.EventId
 	 
    -- Return Variable Data Second
    Select 'Timestamp'= [dbo].[fnServer_CmnConvertFromDbTime] ( [Timestamp],@InTimeZone) ,  
          Value, Color,EventNumber  
    From #Data       Order By Timestamp ASC
    Fetch Next From Variable_Cursor Into @@VariableId
  End
Close Variable_Cursor
Deallocate Variable_Cursor  
Drop Table #Variables
Drop Table #Data
DROP TABLE #SelectedEvents  	 
