CREATE Procedure dbo.spDBR_InventoryDistribution
@UnitList text = NULL,
@UnitFilter int = NULL,
@StatusFilter int = NULL,
@ProductFilter int = null,
@CrewFilter varchar(10) = null,
@ShowTopNBars int = 20
AS
SET ANSI_WARNINGS off
set arithignore on
set arithabort off
set ansi_warnings off
/*****************************************************
-- For Testing
--*****************************************************
Declare
@UnitList varchar(1000),
@UnitFilter int,
@StatusFilter int,
@ProductFilter int,
@CrewFilter varchar(10)
Select @UnitList = '<Root></Root>'
Select @ProductFilter = null
Select @CrewFilter = NULL
Select @StatusFilter = NULL
Select @UnitFilter = 2
--*****************************************************/
Declare @@UnitId int
Declare @SQL1 varchar(2000)
Declare @DimXUnits varchar(25)
Declare @EventName varchar(50)
Create Table #Summary (
  Timestamp  datetime,
  ProductId  int NULL,
  UnitId     int NULL,
  StatusId   int NULL,
  Crew       varchar(10) NULL,
  Amount     real NULL
) 
Declare @TotalProduction real
Select @TotalProduction = 0
--*****************************************************/
--Build List Of Units
--*****************************************************/
create table #Units
(
  LineName varchar(100) NULL, 
  LineId int NULL,
 	 UnitName varchar(100) NULL,
 	 Item int
)
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'Item;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (Item) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, Item) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (Item) 
      Select distinct pu_id From event_configuration where et_id = 1
  End
-- Purge Units When Unit Filter Is Set
If @UnitFilter Is Not Null
  Delete From #Units Where Item <> @UnitFilter
--*****************************************************/
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
  Begin    
    -- Get Engineering Units
    If @DimXUnits Is Null  
 	  	  	  	 Select @EventName = s.event_subtype_desc,
               @DimXUnits = s.dimension_x_eng_units
 	  	  	  	   from event_configuration e 
 	  	  	  	   join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	  	  	   where e.pu_id = @@UnitId and 
 	  	  	  	         e.et_id = 1
 	  	 --*****************************************************
 	  	 -- Production EVENTS
 	  	 --*****************************************************
 	  	 Insert Into #Summary (Timestamp,ProductId,UnitId,StatusId,Crew,Amount)
      Select e.Timestamp, Case When e.applied_product is null then ps.prod_id Else e.applied_product End,  e.PU_id, e.event_status, c.Crew_Desc, coalesce(ed.final_dimension_x,0)
        From Events e
        join production_status s on s.prodstatus_id = e.event_status and s.count_for_inventory = 1
        join Event_Details ed on ed.event_id = e.event_id
        Join production_starts ps on ps.pu_id = @@UnitId and ps.start_time <= e.Timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null)) 
        left outer join Crew_Schedule c on c.PU_Id = @@UnitId and c.Start_Time <= e.Timestamp and C.End_Time > e.Timestamp        
        Where e.pu_id = @@UnitId
    Fetch Next From Unit_Cursor Into @@UnitId
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
-- Filter By Product
If @ProductFilter Is Not Null
  Delete From #Summary Where ProductId <> @ProductFilter
-- Filter By Status
If @StatusFilter Is Not Null
  Delete From #Summary Where StatusId <> @StatusFilter
-- Filter By Crew
If @CrewFilter Is Not Null
  Delete From #Summary Where Crew <> @CrewFilter 
-- Get Total Production
Select @TotalProduction = coalesce((Select sum(Amount)From #Summary),0)
--*********************************************************************************
-- Return Resultset #1 - Resultset Name List
--*********************************************************************************
Create Table #Resultsets (
  ResultSetName varchar(50),
  ResultSetTabName varchar(50),
  ParameterName varchar(50),
  ParameterUnits varchar(50) NULL ,
  DataColumns    varchar(50) NULL,
  LabelColumns   varchar(50) NULL,
  IconDesc 	  varchar(1000) NULL,
  RS_ID 	  	 int 
)
insert into #Resultsets values (null, dbo.fnDBTranslate(N'0', 38376, 'Inventory Distribution'), 'blue', NULL, NULL, NULL, NULL, NULL)
If @UnitFilter Is Null
  insert into #Resultsets values ('UnitPareto', dbo.fnDBTranslate(N'0', 38129, 'Unit'), '38254', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38378, 'units')), '2','1',NULL, 1)
If @StatusFilter Is Null
  insert into #Resultsets values ('StatusPareto', dbo.fnDBTranslate(N'0', 38118, 'Status'), '38255', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38378, 'units')), '2','1',NULL, 2)
If @ProductFilter Is Null
  insert into #Resultsets values ('ProductPareto', dbo.fnDBTranslate(N'0', 38337, 'Product'), '38244', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38378, 'units')), '2','1',NULL, 3)
If @CrewFilter Is Null
  insert into #Resultsets values ('CrewPareto', dbo.fnDBTranslate(N'0', 38338, 'Crew'), '38245', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38378, 'units')), '2','1',NULL, 4)
Select * From #Resultsets
Drop Table #Resultsets
Create Table #Results (
  Id int NULL,
  Name varchar(100) NULL,
  Total real NULL,
  Average real NULL,
  Minimum real NULL,
  Maximum real NULL,
  PercentTotal real NULL,
  NumberOfEvents int NULL 
)
--*********************************************************************************
-- Return Resultset #2 - Unit Pareto
--*********************************************************************************
If @UnitFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, Average, Minimum, Maximum, PercentTotal, NumberOfEvents)
      Select UnitId, sum(Amount), Avg(Amount),min(Amount) ,max(Amount),sum(Amount) / convert(real,@TotalProduction), Count(Amount)
        From #Summary
        Group By UnitId
    Select @SQL1 = 'Select r.Id, u.pu_desc as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 1 as RS_ID From #Results r left outer join Prod_Units u on u.pu_id = r.Id Order By ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultset #3 - Status Pareto
--*********************************************************************************
If @StatusFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, Average, Minimum, Maximum, PercentTotal, NumberOfEvents)
      Select StatusId, sum(Amount), Avg(Amount),min(Amount) ,max(Amount),sum(Amount) / convert(real,@TotalProduction), Count(Amount)
        From #Summary
        Group By StatusId
    Select @SQL1 = 'Select r.Id, s.prodstatus_desc as [\@' + dbo.fnDBTranslate(N'0', 38118, 'Status') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 2 as RS_ID From #Results r left outer join production_status s on s.prodstatus_id = r.Id Order By ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultset #4 - Product Pareto
--*********************************************************************************
If @ProductFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, Average, Minimum, Maximum, PercentTotal, NumberOfEvents)
      Select ProductId, sum(Amount), Avg(Amount),min(Amount) ,max(Amount),sum(Amount) / convert(real,@TotalProduction), Count(Amount)
        From #Summary
        Group By ProductId
    Select @SQL1 = 'Select r.Id, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 3 as RS_ID From #Results r join products p on p.prod_id = r.Id Order By ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    Exec (@SQL1)
  End
--*********************************************************************************
-- Return Resultset #5 - Crew Pareto
--*********************************************************************************
If @CrewFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Name, Total, Average, Minimum, Maximum, PercentTotal, NumberOfEvents)
      Select Crew, sum(Amount), Avg(Amount),min(Amount) ,max(Amount),sum(Amount) / convert(real,@TotalProduction), Count(Amount)
        From #Summary
        Group By Crew
    Select @SQL1 = 'Select Id = NULL, Name as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 4 as RS_ID From #Results r Order By ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    Exec (@SQL1)
  End
Drop Table #Results
Drop Table #Summary
Drop Table #Units
