CREATE Procedure dbo.spDBR_EventSearch
@UnitList text = NULL
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @UnitList varchar(1000)
Select @UnitList = '<Root></Root>'
--*****************************************************/
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
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (UnitId) EXECUTE spDBR_Prepare_Table @Text
      update #Units set UnitName = pu_desc from prod_units where pu_id = UnitId
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, UnitId) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (UnitId, UnitName) 
      Select distinct pu_id, pu_desc From prod_units where pu_id > 0     
  End
/*****************************************************
-- For Testing
--*****************************************************
truncate table #Units
insert into #units (unitid, unitname) values (2, 'P1 Machine')
--*****************************************************/
Declare @EventType varchar(100)
Declare @@UnitId int
Declare Unit_Cursor Insensitive Cursor 
  For Select UnitId From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin
    -- Look Up Dimension Information    
 	  	 Select @EventType = s.event_subtype_desc
 	  	   from event_configuration e 
 	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	   where e.pu_id = @@UnitId and 
 	  	         e.et_id = 1
    Update #Units set EventName = @EventType Where UnitId = @@UnitId
    Fetch Next From Unit_Cursor Into @@UnitId
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
--*****************************************************/
--*****************************************************/
--Build List Of Statuses
--*****************************************************/
create table #Statuses
(
 	 StatusId int,
 	 StatusName varchar(50)
)
insert into #Statuses 
  select distinct s.prodstatus_id, s.prodstatus_desc
    from prdexec_trans t 
    join production_status s on s.prodstatus_id = t.to_prodstatus_id
    join #Units u on u.UnitId = t.pu_id 
--*****************************************************/
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(255)
)
Declare @Title varchar(255)
Declare @EventPrompt varchar(255)
If (Select count(Distinct EventName) From #Units) > 1 
  Select @EventPrompt = dbo.fnDBTranslate(N'0', 38426, 'Events')
Else 
  Select @EventPrompt = min(EventName) From #Units
Select @Title = dbo.fnDBTranslate(N'0', 38425, 'Search For') + ' ' + @EventPrompt
insert into #Columns values('Title', @Title)
insert into #Columns values('Unit', dbo.fnDBTranslate(N'0', 38129, 'Unit'))
insert into #Columns values('Status', dbo.fnDBTranslate(N'0', 38118, 'Status'))
insert into #Columns values('ProductCode', dbo.fnDBTranslate(N'0', 38391, 'Product Code'))
insert into #Columns values('Time', dbo.fnDBTranslate(N'0', 38289, 'Time'))
insert into #Columns values('Search', dbo.fnDBTranslate(N'0', 38108, 'Search'))
insert into #Columns values('InProcess', dbo.fnDBTranslate(N'0', 38427, 'Show In-Process Items Only'))
select * from #Columns
drop table #Columns
--*****************************************************/
--Return Unit List
--*****************************************************/
select UnitId, UnitName from #Units
  Order By UnitName
drop table #Units
--*****************************************************/
--Return Status List
--*****************************************************/
select * from #Statuses
  Order By StatusName
drop table #Statuses
