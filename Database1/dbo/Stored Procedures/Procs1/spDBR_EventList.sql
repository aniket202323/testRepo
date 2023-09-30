CREATE Procedure dbo.spDBR_EventList
@Unit 	  	  	  	 int = NULL,
@StatusList 	  	  	 text = NULL,
@VariableList 	  	 text = NULL,
@StartTime 	  	  	 datetime = NULL,
@EndTime 	  	  	 datetime = NULL,
@ColumnVisibility 	 text = NULL,
@InTimeZone 	  	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
--*************************************************************/
set arithignore on
set arithabort off
SET ANSI_WARNINGS off
--*****************************************************/
--Build List Of Units
--*****************************************************/
declare @EventName varchar(10)
declare @Text nvarchar(4000)
if @EndTime is null select @EndTime =dbo.fnServer_CmnGetDate(getutcdate())
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
--*****************************************************/
--Build Statuses
--*****************************************************/
Create Table #Status (
  StatusName varchar(100) NULL,
  Item int
)
if (not @StatusList like '%<Root></Root>%' and not @StatusList is NULL)
  begin
    if (not @StatusList like '%<Root>%')
    begin
      select @Text = N'Item;' + Convert(nvarchar(4000), @StatusList)
      Insert Into #Status (Item) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Status EXECUTE spDBR_Prepare_Table @StatusList
    end
  end
Else
  Begin
    Insert Into #Status (Item) Select distinct prodstatus_id From production_status     
  End
--*****************************************************/
--Build Column List
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
if (not @ColumnVisibility like '%<Root></Root>%')
begin
  insert into #Columns (Prompt, ColumnName)
 	   EXECUTE spDBR_GetColumns @ColumnVisibility
end
--*****************************************************/
--Build List Of Variable Test Names / Alias
--*****************************************************/
Create Table #Variables (
  VariableName varchar(100) NULL
)
if (not @VariableList like '%<Root></Root>%' and not @VariableList is NULL)
 	 begin
 	  	 if (not @VariableList like '%<Root>%')
 	  	  	 begin
 	  	  	  	 select @Text = N'VariableName;' + Convert(nvarchar(4000), @VariableList)
 	  	  	  	 Insert Into #Variables (VariableName) 
 	  	  	  	  	 EXECUTE spDBR_Prepare_Table @Text
 	  	  	 end
 	  	 else
 	  	  	 begin
 	  	  	  	 insert into #Variables (VariableName) EXECUTE spDBR_Prepare_Table @VariableList
 	  	  	 end
 	 end
--*****************************************************/
--Build Temporary Table
--*****************************************************/
Create Table #EventList
(
 	 Id int identity(1,1),
 	 UnitID int NULL,
 	 StatusId int NULL,
 	 EventId int NULL,
 	 EventNumber varchar(100) NULL,
 	 UnitName varchar(100) NULL,
 	 LocationName varchar(100) NULL,
 	 StartTime datetime NULL,
 	 EndTime datetime NULL,
 	 Age varchar(50) NULL,
 	 Product varchar(100) NULL,
 	 Status varchar(100) NULL,
 	 TimeInStatus varchar(100) NULL,
 	 DimensionX decimal(10,2) NULL,
 	 DimensionXEngUnits varchar(10) NULL,
 	 DimensionY decimal(10,2) NULL,
 	 DimensionYEngUnits varchar(10) NULL,
 	 DimensionZ decimal(10,2) NULL,
 	 DimensionZEngUnits varchar(10) NULL,
 	 DimensionA decimal(10,2) NULL,
 	 DimensionAEngUnits varchar(10) NULL,
 	 PercentTested real NULL,
 	 PercentConformance varchar(50) NULL,
 	 Signoff1 varchar(50) NULL,
 	 Signoff2 varchar(50) NULL,
 	 Comment varchar(1000) NULL,
 	 HighAlarmCount int NULL,
 	 MediumAlarmCount int NULL,
 	 LowAlarmCount int NULL
)
--*****************************************************/
--Alter Table For Extra Variables
--*****************************************************/
Declare @@VariableName varchar(100)
Declare @SQL varchar(1000) 
If (Select Count(VariableName) From #Variables) > 0 
 	 Begin
 	  	 Declare Variable_Cursor Insensitive Cursor 
 	  	 For Select VariableName From #Variables 
 	  	 For Read Only
 	  	 Open Variable_Cursor
 	  	 Fetch Next From Variable_Cursor Into @@VariableName
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	  	 Select @SQL = 'Alter Table #EventList Add [' + @@VariableName + '] varchar(50) NULL'
 	  	  	  	 exec (@SQL)
 	  	  	  	 Fetch Next From Variable_Cursor Into @@VariableName
 	  	  	 End
 	  	 Close Variable_Cursor
 	  	 Deallocate Variable_Cursor  
 	 End 
--*****************************************************/
--Load Results Into Temporary Table
--*****************************************************/
Declare @@StatusId int
Declare @@EventId int
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @@ThisStatusId int
Declare @@Status varchar(100)
Declare @EventType varchar(50)
Declare @DimXName varchar(25)
Declare @DimXUnits varchar(25)
Declare @DimYName varchar(25)
Declare @DimYUnits varchar(25)
Declare @DimZName varchar(25)
Declare @DimZUnits varchar(25)
Declare @DimAName varchar(25)
Declare @DimAUnits varchar(25)
Declare @NewStartTime datetime
Declare @HighAlarmCount int
Declare @MediumAlarmCount int
Declare @LowAlarmCount int
Declare @TimeInStatus int
Declare @Value varchar(25)
Declare @VariableId int
    -- Look Up Dimension Information    
Select @EventType = s.event_subtype_desc,
       @DimXName = s.dimension_x_name,
       @DimYName = s.dimension_y_name,
       @DimZName = s.dimension_z_name,
       @DimAName = s.dimension_a_name,
       @DimXUnits = s.dimension_x_eng_units,
       @DimYUnits = s.dimension_y_eng_units,
       @DimZUnits = s.dimension_z_eng_units,
       @DimAUnits = s.dimension_a_eng_units
From   event_configuration e 
JOIN   event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
Where  e.pu_id = @Unit
       and e.et_id = 1
Select @EventName = @EventType
Insert Into #EventList (UnitId, EventNumber, UnitName, LocationName, StartTime, EndTime, Age, Product, Status, TimeInStatus, DimensionX, DimensionXEngUnits, DimensionY, DimensionYEngUnits, DimensionZ, DimensionZEngUnits, DimensionA, DimensionAEngUnits, PercentTested, PercentConformance, Signoff1, Signoff2, Comment, StatusId, EventId)
Select top 101 
 	 UnitId = @Unit, 
 	 EventNumber = Case
 	  	  	 When s.count_for_production = 0 Then '<font color=red>' + e.event_num + '</font>'
 	  	  	 When s.count_for_production = 1 and  s.count_for_inventory = 1 Then '<font color=blue>' + e.event_num + '</font>'
 	  	  	 Else e.event_num
 	  	 End,
 	 UnitName = u.pu_desc, 
 	 LocationName = l.location_code, 
 	 StartTime = e.Start_Time,
 	 EndTime = e.timestamp, 
 	 Age = convert(varchar(10),floor(datediff(minute,e.timestamp,getdate()) / 60.0)) + ':' + right('0' + convert(varchar(10),datediff(minute,e.timestamp,getdate()) % 60),2),
 	 Product = Case When e.applied_product is null then p1.prod_code else p2.prod_code End,
 	 Status = Case
 	  	  	 When s.count_for_production = 0 Then '<font color=red>' + s.prodstatus_desc + '</font>'
 	  	  	 When s.count_for_production = 1 and  s.count_for_inventory = 1 Then '<font color=blue>' + s.prodstatus_desc + '</font>'
 	  	  	 Else s.prodstatus_desc
 	  	 End,
 	 TimeInStatus = Case
 	  	  	 When s.count_for_production = 0 Then '<font color=red>'
 	  	  	 When s.count_for_production = 1 and  s.count_for_inventory = 1 Then '<font color=blue>' 
 	  	  	 Else null
 	  	 End,                 
 	 DimensionX = coalesce(convert(decimal(10,2), ed.initial_dimension_x), '0'), 
 	 DimensionXEngUnits = @DimXUnits, 
 	 DimensionY = coalesce(convert(decimal(10,2), ed.initial_dimension_y), '0'), 
 	 DimensionYEngUnits = @DimYUnits, 
 	 DimensionZ = coalesce(convert(decimal(10,2), ed.initial_dimension_z), '0'), 
 	 DimensionZEngUnits = @DimZUnits, 
 	 DimensionA = coalesce(convert(decimal(10,2), ed.initial_dimension_a), '0'),
 	 DimensionAEngUnits = @DimAUnits, 
 	 PercentTested = coalesce(convert(real,Testing_prct_Complete), '0'),
 	 PercentConformance = Case 
 	  	  	 When e.Conformance = 1 Then '<font color=blue>' + dbo.fnDBTranslate(N'0', 38428, 'User') + '</font>'
 	  	  	 When e.Conformance = 2 Then '<font color=blue>' + dbo.fnDBTranslate(N'0', 38429, 'Warning') + '</font>'
 	  	  	 When e.Conformance = 3 Then '<font color=red>' + dbo.fnDBTranslate(N'0', 38430, 'Reject') + '</font>'
 	  	  	 When e.Conformance = 4 Then '<font color=red>' + dbo.fnDBTranslate(N'0', 38431, 'Entry') + '</font>'
 	  	  	 Else dbo.fnDBTranslate(N'0', 38434,'Good')
 	  	 End,
 	 Signoff1 = user1.username, 
 	 Signoff2 = user2.username, 
 	 Comment = convert(varchar(1000), c.comment_text), 
 	 StatusId = e.event_status, 
 	 EventId = e.event_id
From Events e
 	 JOIN prod_units u on u.pu_id = e.pu_id
 	 JOIN Production_Status s on s.prodstatus_id = e.event_status
 	 JOIN production_starts ps on ps.pu_id = @Unit and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
 	 JOIN products p1 on p1.prod_id = ps.prod_id 
 	 LEFT OUTER JOIN products p2 on p2.prod_id = e.applied_product
 	 LEFT OUTER JOIN Event_Details ed on ed.Event_id = e.Event_id
 	 LEFT OUTER JOIN Unit_Locations l on l.Location_Id = ed.Location_id
 	 LEFT OUTER JOIN comments c on c.comment_id = e.comment_id
 	 LEFT OUTER JOIN esignature esig on esig.signature_id = e.signature_id
 	 LEFT OUTER JOIN users user1 on user1.[user_id] = esig.perform_user_id
 	 LEFT OUTER JOIN users user2 on user2.[user_id] = esig.verify_user_id
 	 JOIN #Status stat on stat.item = e.event_status
Where e.pu_id = @Unit 
order by e.timestamp desc 
-- Update The Event StartTime if it is NULL
Update  d1
 	 Set d1.StartTime = d2.EndTime
 	 From #EVentList d2
 	 JOIN #EVentList d1 on d1.id = (d2.id - 1)
 	 where d1.starttime is null
Delete From #EventList where Id = 101
if (not @StartTime is null and not @EndTime is null)
begin
 	 delete from #EventList where not starttime between @StartTime and @EndTime and not endtime between @StartTime and @EndTime
end
if (@StartTime is null and not @EndTime is null)
begin
 	 delete from #EventList where endtime > @EndTime
end
if (not @StartTime is null and @EndTime is null)
begin
 	 delete from #EventList where starttime < @StartTime
end
Declare Event_Cursor Insensitive Cursor 
  For Select EventId, StartTime, EndTime, StatusId, TimeInStatus From #EventList Where UnitId = @Unit 
  For Read Only
Open Event_Cursor
 	  	 
Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime, @@ThisStatusId, @@Status 	  	 
While @@Fetch_Status = 0
 	 Begin
 	  	 -- get start time if necessary
 	  	 If @@StartTime Is Null
 	  	  	 Select @NewStartTime = max(Timestamp) From Events Where PU_id = @Unit and Timestamp < @@EndTime
 	  	 Else
 	  	  	 Select @NewStartTime = @@StartTime
        -- get alarm counts for event
 	  	 Select @HighAlarmCount = 0, @MediumAlarmCount = 0, @LowAlarmCount = 0
 	  	 execute spCMN_GetUnitAlarmCounts
 	  	  	 @Unit,
 	  	  	 @NewStartTime, 
 	  	  	 @@EndTime,
 	  	  	 @HighAlarmCount OUTPUT,
 	  	  	 @MediumAlarmCount OUTPUT,
 	  	  	 @LowAlarmCount OUTPUT
        -- get time in status
        Select @TimeInStatus = NULL
        Select @TimeInStatus = sum(datediff(minute, start_time, end_time)) From event_status_transitions where event_id = @@EventId and event_status = @@ThisStatusId
        If @TimeInStatus is NULL Or @TimeInStatus = 0
          Select @TimeInStatus = datediff(minute, entry_on,dbo.fnServer_CmnGetDate(getutcdate())) From events where event_id = @@EventId
        -- update event record
        If @@Status Is Null
          Update #EventList 
            Set TimeInStatus = convert(varchar(10),floor(@TimeInStatus / 60.0)) + ':' + right('0' + convert(varchar(10),@TimeInStatus % 60),2),
                HighAlarmCount = @HighAlarmCount, MediumAlarmCount = @MediumAlarmCount, LowAlarmCount = @LowAlarmCount,
                StartTime = coalesce(@@StartTime, @NewStartTime)
            Where EventId = @@EventId  
        Else           
          Update #EventList 
            Set TimeInStatus = TimeInStatus + convert(varchar(10),floor(@TimeInStatus / 60.0)) + ':' + right('0' + convert(varchar(10),@TimeInStatus % 60),2) + '</font>',
                HighAlarmCount = @HighAlarmCount, MediumAlarmCount = @MediumAlarmCount, LowAlarmCount = @LowAlarmCount,
                StartTime = coalesce(@@StartTime, @NewStartTime)
            Where EventId = @@EventId  
        -- Get Individual Variable Data
 	  	 Declare Variable_Cursor Insensitive Cursor 
 	  	   For Select VariableName From #Variables 
 	  	   For Read Only
 	  	 
 	  	 Open Variable_Cursor 	  	  	  	 
 	  	 Fetch Next From Variable_Cursor Into @@VariableName 	  	  	  	 
 	  	  	 While @@Fetch_Status = 0
 	  	  	  	 Begin
 	  	  	  	  	 Select @Value = NULL, @VariableId = NULL
 	  	  	  	  	 Select @VariableId = v.var_id 
 	  	  	  	  	 From variables v
 	  	  	  	  	  	 JOIN prod_units p on p.pu_id = v.pu_id and p.pu_id = @Unit or p.master_unit = v.pu_id
 	  	  	  	  	 Where v.test_name = @@VariableName
 	  	              
 	  	  	  	  	 If @VariableId Is Null
 	  	  	  	  	  	 Select @VariableId = v.var_id 
 	  	  	  	  	  	 From variables v
 	  	  	  	  	  	  	 JOIN prod_units p on p.pu_id = v.pu_id and p.pu_id = @Unit or p.master_unit = v.pu_id
 	  	  	  	  	  	 Where v.var_desc = @@VariableName 
 	  	             
 	  	  	  	  	 If @VariableId Is Not Null
 	  	  	  	  	  	 Select @Value = result from Tests Where var_id = @VariableId and result_on = @@EndTime
 	  	             
 	  	  	  	  	 If @Value is Not Null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Select @SQL = 'Update #EventList Set [' + @@VariableName + '] = ' + '''' + @Value + '''' + ' Where EventId = ' + convert(varchar(25),@@EventId)  	 
 	  	  	  	  	  	  	 exec (@SQL)
 	  	  	  	  	  	 End
 	  	   
 	  	  	  	  	 Fetch Next From Variable_Cursor Into @@VariableName
 	  	  	  	 End
 	  	  	  	 
 	  	  	 Close Variable_Cursor
 	  	  	 Deallocate Variable_Cursor  
 	  	 Fetch Next From Event_Cursor Into @@EventId, @@StartTime, @@EndTime, @@ThisStatusId, @@Status
 	 End
 	  	 
Close Event_Cursor
Deallocate Event_Cursor  
--*****************************************************
--Return Header and Translation Information
--*****************************************************
Update #Columns Set Prompt = (Select @EventName)
Where ColumnName = 'EventNumber'   
If @DimXName Is Not Null
  Update #Columns Set Prompt = @DimXName
    Where ColumnName = 'DimensionX'   
Else
  Delete From #Columns Where ColumnName = 'DimensionX'   
If @DimYName Is Not Null
  Update #Columns Set Prompt = @DimYName
    Where ColumnName = 'DimensionY'   
Else
  Delete From #Columns Where ColumnName = 'DimensionY'   
If @DimZName Is Not Null
  Update #Columns Set Prompt = @DimZName
    Where ColumnName = 'DimensionZ'
Else
  Delete From #Columns Where ColumnName = 'DimensionZ'   
If @DimAName Is Not Null
  Update #Columns Set Prompt = @DimAName
    Where ColumnName = 'DimensionA'
Else
  Delete From #Columns Where ColumnName = 'DimensionA'      
insert into #columns (Prompt, ColumnName) select VariableName, VariableName from #Variables
select * from #Columns
drop table #Columns
---23/08/2010 - Update datetime formate in UTC into #EVentList table
Update #EVentList Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	    EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone)
--*****************************************************
--Return Results
--*****************************************************
Select Top 100 UnitID, StatusId, EventId, EventNumber, UnitName, LocationName, StartTime, EndTime, Age, Product, Status, TimeInStatus, DimensionX, DimensionXEngUnits,
DimensionY, DimensionYEngUnits, DimensionZ, DimensionZEngUnits, DimensionA, DimensionAEngUnits, PercentTested, PercentConformance, Signoff1, Signoff2, Comment,
HighAlarmCount, MediumAlarmCount, LowAlarmCount
From #EVentList
Order By UnitName, StartTime DESC
Drop table #EventList
Drop Table #Variables
Drop Table #Status
