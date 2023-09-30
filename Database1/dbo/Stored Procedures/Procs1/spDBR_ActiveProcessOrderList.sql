CREATE Procedure dbo.spDBR_ActiveProcessOrderList
@LineList text = NULL,
@ColumnVisibility text = NULL,
@InTimeZone varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
SET ANSI_WARNINGS off
--*****************/
/*****************************************************
-- For Testing
--*****************************************************
--select pl_id, * from prod_units where pu_id = 2
set nocount on
Declare @LineList varchar(1000)
Declare @ColumnVisibility varchar(1000)
Select @LineList = '<Root></Root>'
select @LineList = '2'
Select @ColumnVisibility = '<root></root>'
--*****************************************************/
--*****************************************************/
--Build List Of Execution Paths
--*****************************************************/
Declare @HostName varchar(255)
Declare @VirtualDirectory varchar(255)
 Select @HostName = value from site_parameters where parm_id = 27
Select @VirtualDirectory = value from site_parameters where parm_id = 30
Create Table #Paths (
  PathId int,
  PathName varchar(100) NULL,
  LineId int NULL,
  LineName varchar(100) NULL
)
Create Table #Lines (
  LineName varchar(100) NULL,
  LineId int NULL
)
if (not @LineList like '%<Root></Root>%' and not @LineList is NULL)
begin
  if (not @LineList like '%<Root>%')
  begin
    declare @Text nvarchar(4000)
    select @Text = N'LineId;' + Convert(nvarchar(4000), @LineList)
    Insert Into #Lines (LineId) EXECUTE spDBR_Prepare_Table @Text
  end
  else
  begin
    Insert Into #Lines EXECUTE spDBR_Prepare_Table @LineList
  end
  insert into #Paths (PathId, PathName, LineId, LineName) select p.path_id, p.path_code, l.LineId, l.LineName from prdexec_paths p join #Lines l on l.LineId = p.pl_id
  drop table #Lines
end
Else
  Begin
    Insert Into #Paths (PathId, PathName, LineId, LineName) 
       Select p.path_id, p.path_code, p.pl_id, l.pl_desc 
         From prdexec_paths p
         Join prod_lines l on l.pl_id = p.pl_id
  End
--*****************************************************/
--*****************************************************/
-- Cursor Through Paths And Build Results
--*****************************************************/
create table #ActiveProcessOrderList
(
 	 CurrentStatusIcon  	  	 tinyint NULL,
 	 ResourceName  	  	  	  	  	 varchar(100) NULL,
 	 CurrentProcessOrder  	 varchar(100) NULL,
 	 CurrentProduct  	  	  	  	 varchar(100) NULL,
 	 PlannedAmount  	  	  	  	 real NULL,
 	 ActualAmount  	  	  	  	  	 real NULL,
 	 AmountEngineeringUnits varchar(25) NULL,
 	 PlannedItems  	  	  	  	  	 int NULL,
 	 ActualItems  	  	  	  	  	 int NULL,
 	 ItemEngineeringUnits  	 varchar(25) NULL,
 	 PercentRate  	  	  	  	  	 real NULL,
 	 RunTime  	  	  	  	  	  	  	 varchar(25) NULL,
 	 ScheduledDeviation  	  	 varchar(1000) NULL,
 	 UnitList  	  	  	  	  	  	  	 varchar(2000) NULL,
 	 NextProcessOrder  	  	  	 varchar(100) NULL,
 	 NextProduct  	  	  	  	  	 varchar(100) NULL,
 	 NextEstimatedStart  	  	 varchar(50) NULL,
 	 NextDuration  	  	  	  	  	 varchar(25) NULL,
 	 NextProcessOrderID  	  	 int NULL,
 	 CurrentProcessOrderID int NULL,
 	 ResourceID  	  	  	  	  	  	 varchar(10) NULL,
  ImpliedSequence  	  	  	 int NULL,
 	 PlannedStartTime 	  	 datetime NULL
)
Create Table #Units (
  UnitId int,
  IsProduction int NULL,
  IsSchedule int NULL
)
Declare @@PathId int
Declare @@LineId int
Declare @@OrderId int
Declare @PathCode varchar(100)
Declare @LineName varchar(100)
Declare @NextProcessOrder   varchar(100)
Declare @NextProduct  	  	  	   varchar(100)
Declare @NextEstimatedStart datetime
Declare @NextDuration  	  	  	 int
Declare @NextProcessOrderID int
Declare @CurrentStatusIcon int
Declare 	 @CurrentProcessOrder  	   varchar(100)
Declare 	 @CurrentProduct  	  	  	   varchar(100)
Declare 	 @PlannedAmount  	  	  	  	   real
Declare 	 @ActualAmount  	  	  	  	  	 real
Declare 	 @AmountEngineeringUnits varchar(25)
Declare 	 @PlannedItems  	  	  	  	  	 int
Declare 	 @ActualItems  	  	  	  	  	   int
Declare 	 @ItemEngineeringUnits  	 varchar(25)
Declare 	 @PercentRate  	  	  	  	  	   real
Declare 	 @ScheduledDeviation  	  	 real
Declare @ImpliedSequence int
Declare @ActualDuration real
Declare @PlannedDuration real
Declare @RemainingDuration real
Declare @PlannedStartTime datetime
Declare @PlannedEndTime datetime
Declare @UnitString varchar(2000)
Declare @Hyperlink varchar(2000)
Declare @@UnitId int
Declare @@IsProduction int
Declare @@IsSchedule int
Declare @NextFlag int
Declare @UnitOrder int
Declare @UnitStatus int
Declare @UnitName varchar(100)
Declare @UnitColor varchar(10)
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
Declare Path_Cursor Insensitive Cursor 
  For Select PathId, LineId From #Paths 
  For Read Only
Open Path_Cursor
Fetch Next From Path_Cursor Into @@PathId, @@LineId
While @@Fetch_Status = 0
  Begin
    -- Look Up Resource Name
    Select @PathCode = path_code From prdexec_paths where path_id = @@PathId    
    Select @LineName = pl_desc from prod_lines where pl_id = @@LineId
    -- Look Up Next Order Information For This Path
 	  	 Select @NextProcessOrderID = NULL
 	  	 Select @NextProcessOrderID = pp.PP_Id, 
           @NextProcessOrder = pp.Process_Order,              
           @NextProduct = p.Prod_Code,
           @NextEstimatedStart = pp.Forecast_Start_Date,
 	  	  	      @NextDuration = datediff(minute,pp.Forecast_Start_Date, pp.Forecast_End_Date)
      From Production_Plan pp
      Join Products p on p.prod_id = pp.prod_id
      Where pp.Path_Id = @@PathId and
            pp.pp_status_id = 2
    -- Look Up Production Units For This Path
    Truncate Table #Units
    Insert Into #Units (UnitId, IsProduction, IsSchedule)
      Select PU_Id, Is_Production_Point, Is_Schedule_Point
        From PrdExec_Path_Units
        Where Path_Id = @@PathId
    -- Find Active Orders Along Path
 	  	 Declare Order_Cursor Insensitive Cursor 
 	  	   For Select Distinct pps.PP_Id From Production_Plan_Starts pps
                        Join Production_Plan pp on pp.pp_id = pps.pp_id and pp.path_id = @@PathId 
                        Where pps.PU_Id in (Select PU_Id From PrdExec_Path_Units Where Path_Id = @@PathId) And
                              pps.End_Time Is Null         
 	  	   For Read Only
 	  	 
 	  	 Open Order_Cursor
 	  	 
 	  	 Fetch Next From Order_Cursor Into @@OrderId
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin
 	  	  	  	 -- Get This Order Properties
 	  	  	  	 Select @CurrentProcessOrder = pp.Process_Order,              
 	  	            @CurrentProduct = p.Prod_Code,
               @PlannedStartTime = pp.Forecast_Start_Date,
               @PlannedEndTime = pp.forecast_end_date,
               @PlannedDuration = datediff(second, pp.forecast_start_date, pp.forecast_end_date) / 60.0,
               @ActualDuration = coalesce(datediff(second, pp.actual_start_time, pp.actual_end_time) / 60.0, datediff(second, pp.actual_start_time,dbo.fnServer_CmnGetDate(getutcdate())) / 60.0),
  	  	  	  	  	  	  	  @PlannedAmount = pp.forecast_quantity,
 	  	  	  	  	  	  	  @ActualAmount = pp.actual_good_quantity,
               @RemainingDuration = pp.Predicted_Remaining_Duration,
               @ImpliedSequence = pp.Implied_Sequence
 	  	       From Production_Plan pp
 	  	       Join Products p on p.prod_id = pp.prod_id
 	  	       Where pp.pp_id = @@OrderId
 	  	  	  	 Select @PlannedItems = sum(pattern_repititions),
               @ActualItems = sum(actual_repetitions)
          From Production_Setup
            Where pp_id = @@OrderId
        If @ActualDuration > 0.0
          Select @PercentRate = ((@ActualAmount / @ActualDuration) / (@PlannedAmount / @PlannedDuration)) * 100.0
        Else
          Select @PercentRate = null 
        Select @RemainingDuration = coalesce(@RemainingDuration, 0)
/*--        Select @ScheduledDeviation = datediff(second, dateadd(second,convert(int,@RemainingDuration * 60.0),getdate()), @PlannedEndTime) / 60.0                       */
        Select @ScheduledDeviation = @PlannedDuration - (@RemainingDuration + @ActualDuration)                       
        Select @UnitString = ''         
        Select @NextFlag = 0
 	  	  	  	 Select @ItemEngineeringUnits = null
 	  	  	  	 Select @AmountEngineeringUnits = null
        Select @CurrentStatusIcon = 3 --Unavailable
        Select @@UnitId = NULL
 	  	  	  	 Declare Unit_Cursor Insensitive Cursor 
 	  	  	  	   For Select UnitId, IsProduction,IsSchedule From #Units
 	  	  	  	   For Read Only
 	  	  	  	 
 	  	  	  	 Open Unit_Cursor
 	  	  	  	 
 	  	  	  	 Fetch Next From Unit_Cursor Into @@UnitId, @@IsProduction, @@IsSchedule
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
             If @@IsSchedule = 1 
               Begin
                 Select @NextFlag = 1
                  -- Recalculate Next Estimated Start, Set Next Flag
                 If @RemainingDuration > 0.0
                   If dateadd(second,convert(int,@RemainingDuration * 60.0),dbo.fnServer_CmnGetDate(getutcdate())) > @NextEstimatedStart 
                     Select @NextEstimatedStart = dateadd(second,convert(int,@RemainingDuration * 60.0),dbo.fnServer_CmnGetDate(getutcdate()))
               End
             If @@IsProduction = 1
               Begin
 	  	               Select @UnitName = NULL
 	  	               Select @UnitName = pu_desc from prod_units where pu_id = @@UnitId 
 	  	              
 	  	               Select @UnitOrder = NULL
 	  	  	  	  	  	  	  	  	 Select @UnitOrder = PP_Id
 	  	                 From Production_Plan_Starts
 	  	                 Where PU_id = @@UnitId and
 	  	                       End_Time Is Null 	 
 	  	 
                  If @UnitOrder = @@OrderId 
                    Begin
 	  	  	  	               Select @UnitStatus = NULL
 	  	  	  	               Select @UnitStatus = tedet_id
 	  	  	  	                 From Timed_Event_Details 
 	  	  	  	                 Where PU_Id = @@UnitId and
 	  	  	  	                       End_Time Is Null  
 	  	                   -- Get Event Type Properties (eng units)
 	  	  	  	  	  	  	  	  	  	  	 Select @ItemEngineeringUnits = s.event_subtype_desc,
 	  	  	  	  	  	  	  	  	  	  	        @AmountEngineeringUnits = s.dimension_x_eng_units
 	  	  	  	  	  	  	  	  	  	  	   from event_configuration e 
 	  	  	  	  	  	  	  	  	  	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	  	  	  	  	  	  	  	  	  	   where e.pu_id = @@UnitId and 
 	  	  	  	  	  	  	  	  	  	  	         e.et_id = 1
                      If @UnitStatus Is Null
                         Begin
 	  	  	  	                   If @CurrentStatusIcon = 3 --Unavailable
 	  	  	  	                     Select @CurrentStatusIcon = 1 --Running
 	  	  	  	                   If @CurrentStatusIcon = 2 -- Down
 	  	  	  	                     Select @CurrentStatusIcon = 4 --Partially Running
                           Select @UnitColor = 'black'                        
                        End
                      Else
                         Begin
                           Select @UnitColor = 'red'                       
 	  	  	  	                   If @CurrentStatusIcon = 3 --Unavailable
 	  	  	  	                     Select @CurrentStatusIcon = 2 --Down
 	  	  	  	                   If @CurrentStatusIcon = 1 -- Running
 	  	  	  	                     Select @CurrentStatusIcon = 4 --Partially Running
                         End
                    End
                  Else
                    Begin
                       Select @UnitColor = 'gray'                       
                    End
 	  	  	  	   
                  Select @Hyperlink = '<a href=javascript:OpenLink(' + '''' + @protocol + @Hostname + '/' + @VirtualDirectory + 'MainFrame.aspx?Control=Applications/Unit+Time+Accounting/UnitTimeAccounting.ascx'
                  Select @Hyperlink = @Hyperlink + '&StartTime=' + replace(convert(varchar(20),dateadd(day,-1, coalesce(dbo.fnServer_CmnConvertFromDBTime(@PlannedStartTime,@InTimeZone),dbo.fnServer_CmnConvertFromDBTime(dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))),120),' ','+')
                  Select @Hyperlink = @Hyperlink + '&EndTime=' + replace(convert(varchar(20),dateadd(day, 1, coalesce(dbo.fnServer_CmnConvertFromDBTime(@PlannedEndTime,@InTimeZone), dbo.fnServer_CmnConvertFromDBTime(dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone))), 120),' ','+')
                  Select @Hyperlink = @Hyperlink + '&Unit=' + convert(varchar(25),@@UnitId)
 	  	  	  	   Select @Hyperlink = @Hyperlink + '&TargetTimeZone=' + replace(@InTimeZone,' ','+')
                  Select @Hyperlink = @Hyperlink + '&EventTypes=19,0,1,2,3,4' + '''' + ',' + '''' + 'yes' + '''' + ',' + '''' + 'yes'+ '''' + ',3,300,800);>'
                  If @UnitString = ''
                    Select @UnitString = @Hyperlink + '<font color=' + @UnitColor + '>' + @UnitName + '</font></a>'
                  Else
                    Select @UnitString = @UnitString + @Hyperlink + ', ' + '<font color=' + @UnitColor + '>' + @UnitName + '</font></a>'
               End        
 	  	  	  	  	  	 Fetch Next From Unit_Cursor Into @@UnitId, @@IsProduction, @@IsSchedule
 	  	  	  	   End
 	  	  	  	 
 	  	  	  	 Close Unit_Cursor
 	  	  	  	 Deallocate Unit_Cursor  
        -- If No Production Unit Was Found, Grab One
        If @ItemEngineeringUnits Is Null and @@UnitId Is Not NUll
   	  	  	  	 Select @ItemEngineeringUnits = s.event_subtype_desc,
 	  	  	  	  	        @AmountEngineeringUnits = s.dimension_x_eng_units
 	  	  	  	  	  	   from event_configuration e 
 	    	  	  	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	  	  	  	  	   where e.pu_id = @@UnitId and 
 	  	  	  	  	  	         e.et_id = 1
        -- Insert Order Into Results List
        Insert Into #ActiveProcessOrderList (CurrentStatusIcon, ResourceName,CurrentProcessOrder,CurrentProduct,PlannedAmount,ActualAmount,AmountEngineeringUnits,PlannedItems,ActualItems,ItemEngineeringUnits,PercentRate,RunTime,ScheduledDeviation,UnitList,NextProcessOrder,NextProduct,NextEstimatedStart,NextDuration,NextProcessOrderID,CurrentProcessOrderID,ResourceID,ImpliedSequence, PlannedStartTime)
            Values (@CurrentStatusIcon,
 	  	  	  	  	  	  	  	  	  	 @LineName + ' (' + @PathCode + ')',
 	  	  	  	  	  	  	  	  	  	 @CurrentProcessOrder,
 	  	  	  	  	  	  	  	  	  	 @CurrentProduct,
 	  	  	  	  	  	  	  	  	  	 @PlannedAmount,
 	  	  	  	  	  	  	  	  	  	 @PlannedAmount - @ActualAmount, -- remaining amount
 	  	  	  	  	  	  	  	  	  	 --@ActualAmount,
 	  	  	  	  	  	  	  	  	  	 @AmountEngineeringUnits,
 	  	  	  	  	  	  	  	  	  	 @PlannedItems,
 	  	  	  	  	  	  	  	  	  	 @ActualItems,
 	  	  	  	  	  	  	  	  	  	 @ItemEngineeringUnits,
 	  	  	  	  	  	  	  	  	  	 @PercentRate,
 	  	  	  	  	  	  	  	  	   convert (varchar(20),@ActualDuration) + 'min',
                    Case
                       When @ScheduledDeviation < 0 Then '<font color=red><b>' + '-' + convert(varchar(25),floor(-1 * coalesce(@ScheduledDeviation / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @ScheduledDeviation) % 60 ,0)),2) +  '</b></font>'
                       Else '+' + convert(varchar(25),floor(coalesce(@ScheduledDeviation / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @ScheduledDeviation) % 60 ,0)),2)
                    End,  
 	  	  	  	  	  	  	  	  	  	 @UnitString,
 	  	  	  	  	  	  	  	  	  	 Case When @NextFlag = 1 Then @NextProcessOrder Else NULL End,
 	  	  	  	  	  	  	  	  	  	 Case When @NextFlag = 1 Then @NextProduct Else NULL End,
 	  	  	  	  	  	  	  	  	  	 Case When @NextFlag = 1 Then convert(varchar(20), @NextEstimatedStart, 109) Else NULL End,
 	  	  	  	  	  	  	  	  	  	 Case When @NextFlag = 1 and @NextProcessOrder Is Not Null Then convert(varchar(25),floor(coalesce(@NextDuration / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @NextDuration) % 60 ,0)),2) Else NULL End, 
 	  	  	  	  	  	  	  	  	  	 Case When @NextFlag = 1 Then @NextProcessOrderID Else NULL End,
 	  	  	  	  	  	  	  	  	  	 @@OrderId,
 	  	  	  	  	  	  	  	  	  	 @@PathId,
   	  	  	  	  	  	  	  	  	 @ImpliedSequence, @PlannedStartTime
                   )
 	  	  	  	 Fetch Next From Order_Cursor Into @@OrderId
 	  	   End
 	  	 
 	  	 Close Order_Cursor
 	  	 Deallocate Order_Cursor  
 	  	 Fetch Next From Path_Cursor Into @@PathId, @@LineId
  End
Close Path_Cursor
Deallocate Path_Cursor  
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
Execute spDBR_GetColumns @ColumnVisibility
---23/08/2010 - Update datetime formate in UTC into #ActiveProcessOrderList table
Update #ActiveProcessOrderList Set PlannedStartTime = dbo.fnServer_CmnConvertFromDBTime(PlannedStartTime,@InTimeZone)
--*****************************************************/
--Return Results
--*****************************************************/
select * 
  from #ActiveProcessOrderList
  order by ResourceName, ImpliedSequence
drop table #ActiveProcessOrderList
Drop table #Paths
Drop Table #Units
