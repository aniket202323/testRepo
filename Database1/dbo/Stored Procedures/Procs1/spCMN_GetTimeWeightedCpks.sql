CREATE PROC dbo.spCMN_GetTimeWeightedCpks
@StartTime DATETIME, 
@EndTime DATETIME, 
@Variable INT, 
@ProductFilter text, 
@FilterNonProductiveTime int
AS
 	 Declare @Pp REAL, @PpK REAL, @Cp REAL, @CpK REAL
  select @Pp = 0, @Ppk = 0, @Cp = 0, @Cpk = 0
/*create table #twProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)*/
/*create table #twProducts (
  [Product Name] varchar(100) null,
  Item1 int,
  Item2 int
)*/
Create Table #twProductChanges (
  ProductName varchar(100),
  ProductId int,
  StartTime datetime,
  EndTime datetime,
) 
create Table #twCpks (
  DurationInMinutes int,
  PercentTotal real null,
  Cpk real,
  Ppk real, 
  Pp real,
  Cp real
)
--*****************************************************/
--Parse Product Filter
--*****************************************************/
/*declare @Text nvarchar(4000)
if (not @ProductFilter like '%<Root></Root>%' and not @ProductFilter is NULL)
  begin
   if (not @ProductFilter like '%<Root>%')
    begin
      select @Text = N'Item1,Item2;' + Convert(nvarchar(4000), @ProductFilter)
      Insert Into #twProducts (Item1,Item2) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #twProducts EXECUTE spDBR_Prepare_Table @ProductFilter
    end
  end
*/
--*****************************************************/
--Get Productive Times
--*****************************************************/
declare @UnitId int
select @UnitId = pu_id from variables where var_id = @Variable
/*
if (@FilterNonProductiveTime = 1)
begin
 	 insert into #twProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @UnitId, @StartTime, @EndTime
end
else
begin
 	 insert into #twProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
*/
/*if (@FilterNonProductiveTime = 1)
begin
insert into #twProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from events_npt where PU_Id = @UnitId 
and coalesce(Start_Time, Actual_Start_Time) >= @StartTime and timestamp <= @EndTime
insert into #twProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from events_npt where PU_Id = @UnitId 
and coalesce(Start_Time, Actual_Start_Time) < @StartTime and @EndTime between coalesce(Start_Time, Actual_Start_Time) and timestamp
insert into #twProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from events_npt where PU_Id= @UnitId 
and timestamp > @EndTime and @StartTime between coalesce(Start_Time, Actual_Start_Time) and timestamp
insert into #twProductiveTimes (StartTime, EndTime) select Productive_Start_Time, Productive_End_Time from events_npt where PU_Id = @UnitId 
and timestamp > @EndTime and @StartTime > coalesce(Start_Time, Actual_Start_Time)
end
else
begin
 	  	 insert into #twProductiveTimes (StartTime, EndTime) select @StartTime, @EndTime
end
delete from #ProductiveTimes where starttime is null
delete from #ProductiveTimes where starttime = endtime
declare @LastEndTime datetime, @NextStartTime datetime, @NextEndTime datetime, @MaxEndTime datetime
select @MaxEndTime = max(Endtime) from #ProductiveTimes
select @LastEndTime = min(EndTime) from #ProductiveTimes
select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime
while (@LastEndTime < @MaxEndTime)
begin
 	 while @LastEndTime = @NextStartTime
 	 begin
 	  	 update #ProductiveTimes set EndTime = @NextEndTime where endtime = @LastEndTime
 	   delete from #ProductiveTimes where starttime = @NextStartTime and endtime = @NextEndTime
 	 
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
 	 end
 	 select @LastEndTime = @NextEndTime
 	 select @NextStartTime = min(StartTime) from #ProductiveTimes where StartTime >= @LastEndTime
 	 select @NextEndTime = min(EndTime) from #ProductiveTimes where StartTime = @NextStartTime 	 
end
*/
--*****************************************************/
--Define Productive Time Cursor
--*****************************************************/
declare @curStartTime datetime, @curEndTime datetime
/*Declare TIMEWEIGHTED_TIME_CURSOR INSENSITIVE CURSOR
  For (
     Select StartTime, EndTime From #twProductiveTimes
      )
  For Read Only
*/
--*****************************************************/
--Fillin Product Run Times
--*****************************************************/
/*Open TIMEWEIGHTED_TIME_CURSOR  
TIMEWEIGHTED_BEGIN_TIME_CURSOR:
Fetch Next From TIMEWEIGHTED_TIME_CURSOR Into @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
*/
/*   Insert Into #twProductChanges (ProductName, ProductId, StartTime, EndTime)
      Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @curStartTime Then @curStartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @curEndTime Then @curEndTime Else coalesce(d.End_Time, getdate()) End
        From Production_Starts d, Products b
    	  	   Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	   	  	       d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @UnitId and t.start_time < @curStartTime) and
 	  	   	       ((d.End_Time > @curStartTime) or (d.End_Time is Null))
       Union
        Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @curStartTime Then @curStartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @curEndTime Then @curEndTime Else coalesce(d.End_Time, getdate()) End
        From Production_Starts d, Products b
 	  	     Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	           d.Start_Time >= @curStartTime and 
 	  	          	 d.Start_Time < @curEndTime 
*/
if (@FilterNonProductiveTime = 1)
begin
   Insert Into #twProductChanges (ProductName, ProductId, StartTime, EndTime)
      Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @StartTime Then @StartTime Else d.Productive_Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @EndTime Then @EndTime Else coalesce(d.Productive_End_Time, getdate()) End
        From Production_Starts_npt d, Products b
    	  	   Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	   	  	       d.Start_Time = (Select Max(t.Start_Time) From Production_Starts_npt t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	   	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
       Union
        Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @StartTime Then @StartTime Else d.Productive_Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @EndTime Then @EndTime Else coalesce(d.Productive_End_Time, getdate()) End
        From Production_Starts_npt d, Products b
 	  	     Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	           d.Start_Time >= @StartTime and 
 	  	          	 d.Start_Time < @EndTime 
end
else
begin
   Insert Into #twProductChanges (ProductName, ProductId, StartTime, EndTime)
      Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @EndTime Then @EndTime Else coalesce(d.End_Time, getdate()) End
        From Production_Starts d, Products b
    	  	   Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	   	  	       d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @UnitId and t.start_time < @StartTime) and
 	  	   	       ((d.End_Time > @StartTime) or (d.End_Time is Null))
       Union
        Select b.Prod_Code, b.Prod_Id, 
             Case When d.Start_Time < @StartTime Then @StartTime Else d.Start_Time End,
             Case When coalesce(d.End_Time, getdate()) > @EndTime Then @EndTime Else coalesce(d.End_Time, getdate()) End
        From Production_Starts d, Products b
 	  	     Where d.PU_id = @UnitId and d.Prod_Id = b.Prod_Id and 
 	  	           d.Start_Time >= @StartTime and 
 	  	          	 d.Start_Time < @EndTime 
end
/*     GOTO TIMEWEIGHTED_BEGIN_TIME_CURSOR
End
Close TIMEWEIGHTED_TIME_CURSOR
Deallocate TIMEWEIGHTED_TIME_CURSOR
*/
delete from #twProductChanges where starttime is null
delete from #twProductChanges where starttime = endtime
if (not @ProductFilter is NULL)
delete from #twProductChanges where ProductId not in (select Item1 from #Products)
--*****************************************************/
--Define Product Run Cursor
--*****************************************************/
declare @curProductId int, @durationinminutes int
Declare TIMEWEIGHTED_PRODUCT_RUN_CURSOR INSENSITIVE CURSOR
  For (
     Select ProductId, StartTime, EndTime From #twProductChanges
      )
  For Read Only
--*****************************************************/
--Start Product Cursor
--*****************************************************/
Open TIMEWEIGHTED_PRODUCT_RUN_CURSOR
TIMEWEIGHTED_BEGIN_PRODUCT_RUN_CURSOR:
Fetch Next From TIMEWEIGHTED_PRODUCT_RUN_CURSOR Into @curProductId, @curStartTime, @curEndTime
While @@Fetch_Status = 0
Begin    
  select @Cpk = Cpk, @Ppk = Ppk, @Cp = Cp, @Pp = Pp from fnCMN_GetVariableStatistics(@curStartTime, @curEndTime, @Variable, @curProductId, 0)
 	 
 	 select @durationinminutes = datediff(minute, @curStartTime, @curEndTime) 
  insert into #twCpks (DurationInMinutes,Cpk,Cp,Ppk,Pp) values (@durationinminutes, @Cpk, @Cp, @Ppk, @Pp) 
     GOTO TIMEWEIGHTED_BEGIN_PRODUCT_RUN_CURSOR
End
Close TIMEWEIGHTED_PRODUCT_RUN_CURSOR
Deallocate TIMEWEIGHTED_PRODUCT_RUN_CURSOR
--*****************************************************/
--End Product Cursor (above)
--*****************************************************/
declare @TotalTime int
select @Cp = 0, @Cpk = 0, @Pp = 0, @Ppk = 0
declare @curPercent real, @curCpk real, @curPpk real, @curPp real, @curCp real
Declare TIMEWEIGHTED_CPK_CURSOR INSENSITIVE CURSOR
  For (
     Select PercentTotal, Cpk From #twCpks
      )
  For Read Only
Declare TIMEWEIGHTED_CP_CURSOR INSENSITIVE CURSOR
  For (
     Select PercentTotal, Cp From #twCpks
      )
  For Read Only
Declare TIMEWEIGHTED_PPK_CURSOR INSENSITIVE CURSOR
  For (
     Select PercentTotal, Ppk From #twCpks
      )
  For Read Only
Declare TIMEWEIGHTED_PP_CURSOR INSENSITIVE CURSOR
  For (
     Select PercentTotal, Pp From #twCpks
      )
  For Read Only
--*****************************************************/
--Calc Weighted Cpk
--*****************************************************/
select @TotalTime = sum(DurationInMinutes) from #twCpks where not Cpk is null
update #twCpks set PercentTotal = (convert(real, DurationInMinutes) / convert(real, @TotalTime)) where not Cpk is null
update #twCpks set PercentTotal = 0, Cpk = 0 where PercentTotal is null
select @Cpk = 0
Open TIMEWEIGHTED_CPK_CURSOR  
BEGIN_TIMEWEIGHTED_CPK_CURSOR:
Fetch Next From TIMEWEIGHTED_CPK_CURSOR Into @curPercent, @curCpk
While @@Fetch_Status = 0
Begin    
 	 select @Cpk = @Cpk + (@curCpk * @curPercent)
     GOTO BEGIN_TIMEWEIGHTED_CPK_CURSOR
End
Close TIMEWEIGHTED_CPK_CURSOR
Deallocate TIMEWEIGHTED_CPK_CURSOR
update #twCpks set PercentTotal = null
--*****************************************************/
--Calc Weighted Cp
--*****************************************************/
select @TotalTime = sum(DurationInMinutes) from #twCpks where not Cp is null
update #twCpks set PercentTotal = (convert(real, DurationInMinutes) / convert(real, @TotalTime)) where not Cp is null
update #twCpks set PercentTotal = 0, Cp = 0 where PercentTotal is null
select @Cp = 0
Open TIMEWEIGHTED_CP_CURSOR  
BEGIN_TIMEWEIGHTED_CP_CURSOR:
Fetch Next From TIMEWEIGHTED_CP_CURSOR Into @curPercent, @curCp
While @@Fetch_Status = 0
Begin    
 	 select @Cp = @Cp + (@curCp * @curPercent)
     GOTO BEGIN_TIMEWEIGHTED_CP_CURSOR
End
Close TIMEWEIGHTED_CP_CURSOR
Deallocate TIMEWEIGHTED_CP_CURSOR
update #twCpks set PercentTotal = null
--*****************************************************/
--Calc Weighted Ppk
--*****************************************************/
select @TotalTime = sum(DurationInMinutes) from #twCpks where not Ppk is null
update #twCpks set PercentTotal = (convert(real, DurationInMinutes) / convert(real, @TotalTime)) where not Ppk is null
update #twCpks set PercentTotal = 0, Ppk = 0 where PercentTotal is null
select @Ppk = 0
Open TIMEWEIGHTED_PPK_CURSOR  
BEGIN_TIMEWEIGHTED_PPK_CURSOR:
Fetch Next From TIMEWEIGHTED_PPK_CURSOR Into @curPercent, @curPpk
While @@Fetch_Status = 0
Begin    
 	 select @Ppk = @Ppk + (@curPpk * @curPercent)
     GOTO BEGIN_TIMEWEIGHTED_PPK_CURSOR
End
Close TIMEWEIGHTED_PPK_CURSOR
Deallocate TIMEWEIGHTED_PPK_CURSOR
update #twCpks set PercentTotal = null
--*****************************************************/
--Calc Weighted Pp
--*****************************************************/
select @TotalTime = sum(DurationInMinutes) from #twCpks where not Pp is null
update #twCpks set PercentTotal = (convert(real, DurationInMinutes) / convert(real, @TotalTime)) where not Pp is null
update #twCpks set PercentTotal = 0, Pp = 0 where PercentTotal is null
select @Pp = 0
Open TIMEWEIGHTED_PP_CURSOR  
BEGIN_TIMEWEIGHTED_PP_CURSOR:
Fetch Next From TIMEWEIGHTED_PP_CURSOR Into @curPercent, @curPp
While @@Fetch_Status = 0
Begin    
 	 select @Pp = @Pp + (@curPp * @curPercent)
     GOTO BEGIN_TIMEWEIGHTED_PP_CURSOR
End
Close TIMEWEIGHTED_PP_CURSOR
Deallocate TIMEWEIGHTED_PP_CURSOR
update #twCpks set PercentTotal = null
 	 Select @Cp as [Cp], @Cpk as [CpK], @Pp as [Pp], @Ppk as [Ppk]
