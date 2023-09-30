CREATE Procedure dbo.spDBR_EventSearchResults
@UnitList 	  	  	 text = NULL,
@StatusList 	  	  	 text = NULL,
@ProductCode 	  	 varchar(50) = null,
@StartTime 	  	  	 datetime = NULL,
@EndTime 	  	  	 datetime = NULL,
@EventNumber 	  	 varchar(50) = NULL,
@InProcessFlag 	  	 bit = 0,
@InTimeZone 	  	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
--*************************************************/
SET ANSI_WARNINGS off
Declare @UnitDescription varchar(255)
Select @UnitDescription = ''
--*****************************************************/
--Build List Of Units
--*****************************************************/
Create Table #Units (
  LineName varchar(100) NULL,
  LineId int NULL, 
  UnitName varchar(100) NULL, 
  UnitId int NULL,
  EventName varchar(10) NULL
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (UnitId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, UnitId) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (UnitId, UnitName) 
      Select distinct pu_id, pu_desc From prod_units     
  End
--*****************************************************/
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
    Insert Into #Status (Item)
      Select distinct prodstatus_id From production_status     
  End
--*****************************************************/
--*****************************************************/
--Prepare Parameters
--*****************************************************/
If @ProductCode Is Null
  Select @ProductCode = ''
Select @ProductCode = '%' + @ProductCode + '%'
If @EventNumber Is Null
  Select @EventNumber = ''
Select @EventNumber = '%' + @EventNumber + '%'
If @InProcessFlag Is Null
  Select @InProcessFlag = 0
--*****************************************************/
--Load Results Into Temporary Table
--*****************************************************/
create table #EventResults
(
 	 IsCurrentIcon bit NULL,
 	 EventNumber varchar(100) NULL,
 	 Unit varchar(50) NULL,
 	 Location varchar(50) NULL,
 	 Status varchar(255) NULL,
 	 ProductCode varchar(50) NULL,
 	 Conformance varchar(255) NULL,
 	 DimensionXName varchar(50) NULL,
 	 DimensionYName varchar(50) NULL,
 	 DimensionZName varchar(50) NULL,
 	 DimensionAName varchar(50) NULL,
 	 DimensionXUnits varchar(50) NULL,
 	 DimensionYUnits varchar(50) NULL,
 	 DimensionZUnits varchar(50) NULL,
 	 DimensionAUnits varchar(50) NULL,
 	 DimensionXValue decimal NULL, 	 
 	 DimensionYValue decimal NULL, 	 
 	 DimensionZValue decimal NULL, 	 
 	 DimensionAValue decimal NULL, 	 
 	 StartTime datetime NULL,
 	 EndTime datetime NULL,
 	 EventID int NULL,
 	 UnitID int NULL,
 	 --Timestamp varchar(255) NULL
 	 Timestamp datetime NULL
)
Declare @@UnitId int
Declare @EventType varchar(50)
Declare @DimXName varchar(25)
Declare @DimXUnits varchar(25)
Declare @DimYName varchar(25)
Declare @DimYUnits varchar(25)
Declare @DimZName varchar(25)
Declare @DimZUnits varchar(25)
Declare @DimAName varchar(25)
Declare @DimAUnits varchar(25)
Declare @MaxTime datetime
Declare @CurrentEvent int
Declare Unit_Cursor Insensitive Cursor 
  For Select UnitId From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    -- Look Up Unit Name
    If @UnitDescription = '' 
      Select @UnitDescription = (Select pu_desc From Prod_Units where pu_id = @@UnitId)
    Else
      Select @UnitDescription = @UnitDescription + ', ' + (Select pu_desc From Prod_Units where pu_id = @@UnitId)
    -- Find Current Event For This Unit
    Select @MaxTime = max(timestamp) From Events Where pu_id = @@UnitId
    Select @CurrentEvent = Event_Id From Events Where pu_id = @@UnitId and timestamp = @MaxTime
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
 	  	   from event_configuration e 
 	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	   where e.pu_id = @@UnitId and 
 	  	         e.et_id = 1
    Update #Units set EventName = @EventType Where UnitId = @@UnitId
    -- Put search results into temp table
    Insert Into #EventResults (IsCurrentIcon, EventNumber, Unit, Location, Status, ProductCode, Conformance, DimensionXName, DimensionXValue, DimensionXUnits, DimensionYName, DimensionYValue, DimensionYUnits, DimensionZName, DimensionZValue, DimensionZUnits, DimensionAName, DimensionAValue, DimensionAUnits, StartTime, EndTime, EventId, UnitId, Timestamp)
      Select IsCurrentIcon = Case
                               When e.Event_Id = @CurrentEvent Then 1 
                               Else 0
                             End, 
             EventNumber = e.Event_Num, 
             Unit = u.pu_desc, 
             Location = l.location_code,
             Status = Case
                        When s.count_for_production = 0 Then '<font color=red>' + s.prodstatus_desc + '</font>'
                        When s.count_for_production = 1 and  s.count_for_inventory = 1 Then '<font color=blue>' + s.prodstatus_desc + '</font>'
                        Else s.prodstatus_desc
                      End,
             ProductCode = Case When e.applied_product is null then p1.prod_code else p2.prod_code End,
             Conformance = Case 
                        When Conformance = 1 Then '<font color=blue>' +  dbo.fnDBTranslate(N'0', 38428, 'User') + '</font>'
                        When Conformance = 2 Then '<font color=blue>' +  dbo.fnDBTranslate(N'0', 38429, 'Warning') + '</font>'
                        When Conformance = 3 Then '<font color=red>' +  dbo.fnDBTranslate(N'0', 38430, 'Reject') + '</font>'
                        When Conformance = 3 Then '<font color=red>' +  dbo.fnDBTranslate(N'0', 38431, 'Entry') + '</font>'
                        Else dbo.fnDBTranslate(N'0', 38434,'Good')
                      End,
 	      DimensionXName = coalesce(@DimXName, ''),
 	      DimensionXValue = convert(decimal(10,2),ed.final_dimension_x), 
 	      DimensionXUnits = coalesce(@DimXUnits,''), 
 	      DimensionYName = coalesce(@DimYName, ''),
 	      DimensionYValue = convert(decimal(10,2),ed.final_dimension_y), 
 	      DimensionYUnits = coalesce(@DimYUnits,''), 
 	      DimensionZName = coalesce(@DimZName, ''),
 	      DimensionZValue = convert(decimal(10,2),ed.final_dimension_z), 
 	      DimensionZUnits = coalesce(@DimZUnits,''), 
 	      DimensionAName = coalesce(@DimAName, ''),
 	      DimensionAValue = convert(decimal(10,2),ed.final_dimension_a), 
 	      DimensionAUnits = coalesce(@DimAUnits,''), 
/* 	      Dimensions = coalesce(@DimXName + '=' + convert(varchar(25),convert(decimal(10,2),ed.final_dimension_x)) + coalesce(' ' + @DimXUnits,''),'') + 
                          coalesce(', ' + @DimYName + '=' + convert(varchar(25),convert(decimal(10,2),ed.final_dimension_y)) + coalesce(' ' + @DimYUnits,''),'') +  
                          coalesce(', ' + @DimZName + '=' + convert(varchar(25),convert(decimal(10,2),ed.final_dimension_z)) + coalesce(' ' + @DimZUnits,''),'') +  
                          coalesce(', ' + @DimAName + '=' + convert(varchar(25),convert(decimal(10,2),ed.final_dimension_a)) + coalesce(' ' + @DimAUnits,''),''),*/
             StartTime = Case 
                            When e.Start_Time Is Null Then dateadd(hour,-8, e.Timestamp) 
                            Else dateadd(second,-4 * datediff(second,e.Start_Time, e.Timestamp),e.Start_Time) 
                         End,
             EndTime = Case 
                            When e.Start_Time Is Null and dateadd(hour,8, e.Timestamp) >dbo.fnServer_CmnGetDate(getutcdate()) Then dbo.fnServer_CmnGetDate(getutcdate()) 
                            When e.Start_Time Is Null and dateadd(hour,8, e.Timestamp) < dbo.fnServer_CmnGetDate(getutcdate()) Then dateadd(hour,8, e.Timestamp) 
                            Else dateadd(second,4 * datediff(second,e.Start_Time, e.Timestamp),e.Timestamp) 
                         End,
             EventId = e.Event_id,
             UnitId = @@UnitId,
             Timestamp = e.timestamp
       From Events e
       Join prod_units u on u.pu_id = e.pu_id
       Join #Status sl on sl.Item = e.event_status
       Join Production_Status s on s.prodstatus_id = e.event_status
       join production_starts ps on ps.pu_id = @@UnitId and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
       Join products p1 on p1.prod_id = ps.prod_id 
       left outer join products p2 on p2.prod_id = e.applied_product
       Left Outer Join Event_Details ed on ed.Event_id = e.Event_id
       Left Outer Join Unit_Locations l on l.Location_Id = ed.Location_id
       Where e.pu_id = @@UnitId and
             e.Timestamp > @StartTime and e.Timestamp <= @EndTime and
             e.Event_Num Like @EventNumber and
             ((e.applied_Product is Null and p1.Prod_Code like @ProductCode) or (e.applied_Product is not Null and p2.Prod_Code like @ProductCode)) and
             ((@InProcessFlag = 0) or (@InProcessFlag = 1 and s.Count_For_Inventory = 1))
    Fetch Next From Unit_Cursor Into @@UnitId
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
--*****************************************************/
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(255)
)
Declare @Description varchar(255)
Declare @EventPrompt varchar(255)
If len(@UnitDescription) > 200 
  Select @Description =  dbo.fnDBTranslate(N'0', 38392, 'Multiple Units') + case When @ProductCode = '%%' then '; ' +  dbo.fnDBTranslate(N'0', 38393, 'Product=All') Else '; ' +  dbo.fnDBTranslate(N'0', 38394, 'Product Like') + ' ' + @ProductCode End
Else 
  Select @Description =  dbo.fnDBTranslate(N'0', 38130, 'Units') + '=' + @UnitDescription + case When @ProductCode = '%%' then '; ' +  dbo.fnDBTranslate(N'0', 38393, 'Product=All') Else '; ' +  dbo.fnDBTranslate(N'0', 38394, 'Product Like') + ' ' + @ProductCode End
If (Select count(Distinct EventName) From #Units) > 1 
  Select @EventPrompt =  dbo.fnDBTranslate(N'0', 38426, 'Events')
Else 
  Select @EventPrompt = min(EventName) From #Units
insert into #Columns (ColumnName, Prompt) values('Description',@Description)
insert into #Columns (ColumnName, Prompt) values('EventNumber',@EventPrompt)
insert into #Columns (ColumnName, Prompt) values('Unit', dbo.fnDBTranslate(N'0', 38129, 'Unit'))
insert into #Columns (ColumnName, Prompt) values('ProductCode', dbo.fnDBTranslate(N'0', 38157, 'Product'))
insert into #Columns (ColumnName, Prompt) values('Conformance', dbo.fnDBTranslate(N'0', 38432, 'Conformance'))
insert into #Columns (ColumnName, Prompt) values('Status', dbo.fnDBTranslate(N'0', 38118, 'Status'))
insert into #Columns (ColumnName, Prompt) values('DimensionXName', dbo.fnDBTranslate(N'0', 38433,'Dimensions'))
insert into #Columns (ColumnName, Prompt) values('TimeStamp', dbo.fnDBTranslate(N'0', 38125, 'Timestamp'))
select * from #Columns
Drop table #Columns
---23/08/2010 - Update datetime formate in UTC into #EventResults table
Update #EventResults Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	    EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone),
 	  	  	  	  	    Timestamp = dbo.fnServer_CmnConvertFromDBTime(Timestamp,@InTimeZone)
--*****************************************************/
--Return Search Results
--*****************************************************/
If @EventNumber = '%%' 
 	 select top 100 * from #EventResults
 	   order by StartTime DESC, EventNumber
Else
 	 select top 100 * from #EventResults
 	   order by EventNumber, StartTime ASC
Drop table #EventResults
Drop table #Units
Drop table #Status
