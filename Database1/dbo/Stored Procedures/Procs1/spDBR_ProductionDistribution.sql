CREATE Procedure dbo.spDBR_ProductionDistribution
@UnitList text = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@FilterNonProductiveTime int = 0,
@UnitFilter int = NULL,
@StatusFilter int = NULL,
@ProductFilter int = null,
@CrewFilter varchar(10) = null,
@ProductionOnly int = NULL,
@ShowTopNBars int = 20,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
--**************************************************/
set arithignore on
set arithabort off
set ansi_warnings off
Declare @@UnitId int
Declare @SQL1 varchar(2000)
Declare @DimXUnits varchar(25)
Declare @EventName varchar(50)
Create Table #Summary (
 	 Timestamp 	  	 datetime,
 	 ProductId 	  	 int NULL,
 	 UnitId 	  	  	 int NULL,
 	 StatusId 	  	 int NULL,
 	 Crew 	  	  	 varchar(10) NULL,
 	 Amount 	  	  	 real NULL,
 	 IsProduction 	 int NULL
) 
Declare @MinProdTime 	 datetime
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
create table #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
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
-------------------------------------------------
-- Get Productive Times and
-- Production_Starts with Applied Product
-------------------------------------------------
DECLARE @Production_Starts TABLE (id int identity, Start_Time datetime, End_Time datetime, PU_ID int, Prod_Id int)
declare @curPU_Id int
Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
For ( Select Item From #Units )
For Read Only
Open PRODUCTIVETIME_CURSOR
Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
While @@Fetch_Status = 0
 	 Begin
 	  	 insert into @Production_Starts(Start_Time, End_Time, Prod_Id, PU_ID)
 	  	 select StartTime, EndTime, ProductKey, @curPU_Id from dbo.fnCMN_SplitGradeChanges(@StartTime, @EndTime, @curPU_Id)
 	  	 if (@FilterNonProductiveTime = 1)
 	  	  	 Begin
 	  	  	  	 insert into #ProductiveTimes (StartTime, EndTime)  
 	  	  	  	  	 execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	  	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) 
 	  	  	  	 select @curPU_Id, @StartTime, @EndTime
 	  	  	 End
 	  	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 End
Close PRODUCTIVETIME_CURSOR
Deallocate PRODUCTIVETIME_CURSOR
declare @curStartTime datetime, @curEndTime datetime
Declare @UnitProdVariD int, @UnitVarProduction real, @ProductionType int
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
 	 Begin    
 	  	 Select @curStartTime=Null, @curEndTime=Null
 	  	 Declare TIME_CURSOR INSENSITIVE CURSOR
 	  	   For (
 	  	  	  Select StartTime, EndTime From #ProductiveTimes where PU_Id = @@UnitId
 	  	  	   )
 	  	   For Read Only
 	  	   Open TIME_CURSOR  
 	  	 BEGIN_TIME_CURSOR:
 	  	 Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin    
 	  	  	  	 If @DimXUnits Is Null  
 	  	  	  	  	 Select @EventName = s.event_subtype_desc, @DimXUnits = s.dimension_x_eng_units
 	  	  	  	  	 from event_configuration e 
 	  	  	  	  	  	 join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
 	  	  	  	  	 where e.pu_id = @@UnitId and 
 	  	  	  	  	  	 e.et_id = 1
 	  	  	  	 select @UnitProdVariD = coalesce(production_variable, production_variable, 0) from prod_units where pu_id = @@UnitID
 	  	  	  	 if (@UnitProdVarID > 0)
 	  	  	  	  	 begin
 	  	  	  	  	  	 ------------------------------------------------------
 	  	  	  	  	  	 -- Production From Variable
 	  	  	  	  	  	 ------------------------------------------------------
 	  	  	  	  	  	 Insert Into #Summary (Timestamp,ProductId,UnitId,StatusId,Crew,Amount)
 	  	  	  	  	  	  	 Select t.Result_on [Result_On], ps.prod_Id [Prod_Id], @@UnitID [pu_id], IsNull(pl.pp_status_id, 0) [PP_Status_Id], IsNull(c.Crew_Desc, dbo.fnDBTranslate(N'0',38330,'Unknown')) [Crew_Desc], t.result [Result]
 	  	  	  	  	  	  	 From tests t
 	  	  	  	  	  	  	  	 Join @Production_Starts ps on ps.pu_id = @@UnitId and t.result_on > ps.Start_Time and t.result_on <= ps.End_Time
 	  	  	  	  	  	  	  	 Left Join Crew_Schedule c on c.PU_ID = @@UnitID and c.Start_Time <= t.result_on and C.End_Time > t.result_on
 	  	  	  	  	  	  	  	 Left Outer Join Production_Plan_Starts pps on pps.pu_id = @@UnitID and pps.Start_Time <= t.result_on and ((pps.End_Time > t.result_on) or (pps.End_Time is Null))
 	  	  	  	  	  	  	  	 Left Outer Join Production_Plan PL on pl.pp_id = pps.pp_id
 	  	  	  	  	  	  	 Where var_id = @UnitProdVarId 
 	  	  	  	  	  	  	  	 and t.result_on >= @curStartTime 
 	  	  	  	  	  	  	  	 and t.result_on < @curEndTime
 	  	  	  	  	 end
 	  	  	  	 else
 	  	  	  	  	 begin   	  
 	  	  	  	  	  	 ------------------------------------------------------
 	  	  	  	  	  	 -- Production EVENTS
 	  	  	  	  	  	 ------------------------------------------------------
 	  	  	  	  	  	 Select top 1 @MinProdTime = start_time 
 	  	  	  	  	  	 From @Production_Starts 
 	  	  	  	  	  	 Where PU_ID = @@UnitId 
 	  	  	  	  	  	  	 and start_time <= @curStartTime order by start_time desc
 	  	  	  	  	  	 -- go 1 month back
 	  	  	  	  	  	 Select @MinProdTime = IsNull(@MinProdTime, @curStartTime-30)
 	  	  	  	  	  	 If @ProductionOnly = 1 
 	  	  	  	  	  	  	 Insert Into #Summary (Timestamp,ProductId,UnitId,StatusId,Crew,Amount, IsProduction)
 	  	  	  	  	  	  	  	 Select e.Timestamp, ps.Prod_Id, e.PU_id, e.event_status, c.Crew_Desc, coalesce(ed.initial_dimension_x,0), s.Count_For_Production
 	  	  	  	  	  	  	  	 From Events e
 	  	  	  	  	  	  	  	  	 join Event_Details ed on ed.event_id = e.event_id
 	  	  	  	  	  	  	  	  	 Join @Production_Starts ps on ps.pu_id = @@UnitId and e.Timestamp > ps.Start_Time and e.Timestamp <= ps.End_Time
 	  	  	  	  	  	  	  	  	 left outer join production_status s on s.prodstatus_id = e.event_status 
 	  	  	  	  	  	  	  	  	 left outer join Crew_Schedule c on c.PU_Id = @@UnitId and c.Start_Time <= e.Timestamp and C.End_Time > e.Timestamp        
 	  	  	  	  	  	  	  	 Where e.pu_id = @@UnitId and
 	  	  	  	  	  	  	  	  	 e.Timestamp > @curStartTime and 
 	  	  	  	  	  	  	  	  	 e.Timestamp <= @curEndTime
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Insert Into #Summary (Timestamp,ProductId,UnitId,StatusId,Crew,Amount)
 	  	  	  	  	  	  	  	 Select e.Timestamp, ps.Prod_Id, 	 e.PU_id, e.event_status, c.Crew_Desc, coalesce(ed.initial_dimension_x,0)
 	  	  	  	  	  	  	  	 From Events e
 	  	  	  	  	  	  	  	  	 join Event_Details ed on ed.event_id = e.event_id
 	  	  	  	  	  	  	  	  	 Join @Production_Starts ps on ps.pu_id = @@UnitId and e.Timestamp > ps.Start_Time and e.Timestamp <= ps.End_Time
 	  	  	  	  	  	  	  	  	 left outer join Crew_Schedule c on c.PU_Id = @@UnitId and c.Start_Time <= e.Timestamp and C.End_Time > e.Timestamp        
 	  	  	  	  	  	  	  	 Where e.pu_id = @@UnitId and
 	  	  	  	  	  	  	  	  	   e.Timestamp > @curStartTime and 
 	  	  	  	  	  	  	  	  	   e.Timestamp <= @curEndTime
 	  	  	  	  	 end    
 	  	  	  	 GOTO BEGIN_TIME_CURSOR
 	  	  	 End
 	  	  	 Close TIME_CURSOR
 	  	  	 Deallocate TIME_CURSOR
 	     Fetch Next From Unit_Cursor Into @@UnitId
 	 End
Close Unit_Cursor
Deallocate Unit_Cursor  
-- Filter By Production Status
If @ProductionOnly = 1 
  Delete From #Summary Where IsProduction <> 1
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
  ParameterUnits varchar(50) NULL,
  DataColumns    varchar(50) NULL,
  LabelColumns   varchar(50) NULL,
  IconDesc 	  varchar(1000) NULL,
  RS_ID int  
)
insert into #Resultsets values (null, dbo.fnDBTranslate(N'0', 38401, 'Production Distribution'), 'blue', NULL, NULL, NULL, NULL, NULL)
If @UnitFilter Is Null
  insert into #Resultsets values ('UnitPareto', dbo.fnDBTranslate(N'0', 38129, 'Unit'), '38254', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38130, 'Units')), 2, 1, NULL, 1)
If @StatusFilter Is Null
  insert into #Resultsets values ('StatusPareto', dbo.fnDBTranslate(N'0', 38118,'Status'), '38255', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38130, 'Units')),2, 1, NULL, 2)
If @ProductFilter Is Null
  insert into #Resultsets values ('ProductPareto', dbo.fnDBTranslate(N'0', 38157, 'Product'), '38244', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38130, 'Units')),2, 1, NULL, 3)
If @CrewFilter Is Null
  insert into #Resultsets values ('CrewPareto', dbo.fnDBTranslate(N'0', 38338, 'Crew'), '28245', coalesce(@DimXUnits,dbo.fnDBTranslate(N'0', 38130, 'Units')),2, 1, NULL, 4)
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
    Select @SQL1 = 'Select r.Id, u.pu_desc as [\@' + dbo.fnDBTranslate(N'0', 38335, 'Location') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340,'Total') +'], '
   Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [\@' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [\@' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [\@' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + coalesce(@EventName, @EventName, 'Events') + '] ' 
    Select @SQL1 = @SQL1 + ', 1 as RS_ID From #Results r join Prod_Units u on u.pu_id = r.Id Order By Total ASC'
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
 	  	 if (@UnitProdVarID > 0)
 	  	 begin
 	     Select @SQL1 = 'Select r.Id, s.pp_status_desc as [\@' + dbo.fnDBTranslate(N'0', 38118, 'Status') + '], '
 	  	 end
 	  	 else
 	  	 begin
    	  Select @SQL1 = 'Select r.Id, s.prodstatus_desc as [\@' + dbo.fnDBTranslate(N'0', 38118, 'Status') + '], '
 	  	 end
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [\@' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [\@' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [\@' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
 	  	 if (@UnitProdVarID > 0)
 	  	 begin
     	 Select @SQL1 = @SQL1 + ', 2 as RS_ID From #Results r join production_plan_statuses s on s.pp_status_id = r.Id Order By Total ASC'
 	  	 end
 	  	 else
 	  	 begin
     	 Select @SQL1 = @SQL1 + ', 2 as RS_ID From #Results r join production_status s on s.prodstatus_id = r.Id Order By Total ASC'
 	  	 end
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
    Select @SQL1 = 'Select r.Id, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38157, 'Product') + '], '
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [\@' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [\@' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [\@' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 3 as RS_ID From #Results r join products p on p.prod_id = r.Id Order By Total ASC'
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
    Select @SQL1 = @SQL1 + 'convert(decimal(15,2),Total) as [' + dbo.fnDBTranslate(N'0', 38340,'Total') +'], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Average) as [\@' + dbo.fnDBTranslate(N'0', 38377, 'Average') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Minimum) as [\@' + dbo.fnDBTranslate(N'0', 38360, 'Minimum') + '], '
    Select @SQL1 = @SQL1 + 'Convert(decimal(15,2),r.Maximum) as [\@' + dbo.fnDBTranslate(N'0', 38357, 'Maximum') + '], '  
    Select @SQL1 = @SQL1 + 'convert(decimal(10,1),r.PercentTotal*100.0) as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], '
    Select @SQL1 = @SQL1 + 'r.NumberOfEvents as [\@' + '#' + @EventName + '] ' 
    Select @SQL1 = @SQL1 + ', 4 as RS_ID From #Results r Order By Total ASC'
    Exec (@SQL1)
  End
Drop Table #Results
Drop Table #Summary
Drop Table #Units
Drop Table #ProductiveTimes
