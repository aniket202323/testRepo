Create Procedure dbo.spDBR_Get_Last_Event
@lasttime 	  	 datetime,
@eventtype 	  	 int, 
@eventscope 	  	 int,
@eventtrigger 	 int,
@versioncount 	 int,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
create table #TimeStamps
(
 	 timestamp datetime
)
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @lasttime = dbo.fnServer_CmnConvertToDBTime(@lasttime,@InTimeZone)
 	 
declare @eventtime datetime
declare @sql nvarchar(4000)
if (@eventtype = 1)
begin
 	 if (@eventscope = 1)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' timestamp from events where pu_id = ' +  Convert(varchar(4),@eventtrigger) + ' and timestamp > ' + char(39) +  Convert(varchar(100),@lasttime) + char(39) +' order by timestamp desc'
 	  	 execute sp_executesql @SQL
/* 	  	 set @eventtime = (select max(timestamp) from events where pu_id =  @eventtrigger and timestamp > @lasttime)*/
 	 end
 	 if (@eventscope = 2)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' entry_on from events where pu_id = ' +  Convert(varchar(4),@eventtrigger) + ' and entry_on > ' + char(39) + Convert(varchar(100),@lasttime)  + char(39) +' order by entry_on desc'
 	  	 execute sp_executesql @SQL
 	  	 /*set @eventtime =(select max(entry_on) from events where pu_id =  @eventtrigger and entry_on > @lasttime)*/
 	 end
end
if (@eventtype = 2)
begin
 	 if (@eventscope = 1)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' result_on  from tests where var_id =' + Convert(varchar(4),@eventtrigger) + ' and result_on > ' + char(39) +  Convert(varchar(100),@lasttime) + char(39) + ' order by result_on desc'
 	  	 execute sp_executesql @SQL
 	 /* 	 set @eventtime = (select max(result_on)  from tests where var_id = @eventtrigger and result_on > @lasttime)*/
 	 end
 	 if (@eventscope = 2)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' entry_on  from tests where var_id = ' +  Convert(varchar(4),@eventtrigger) + ' and entry_on > ' + char(39) +  Convert(varchar(100),@lasttime) + char(39) +' order by entry_on desc'
 	  	 execute sp_executesql @SQL
 	  	 /*set @eventtime = (select max(entry_on) from tests where var_id = @eventtrigger and entry_on > @lasttime)*/
 	 end
end
if (@eventtype = 3)
begin
 	 if (@eventscope = 1)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' start_time  from production_starts where pu_id = ' +  Convert(varchar(4),@eventtrigger) + ' and start_time < ' + char(39) + Convert(varchar(100), dbo.fnServer_CmnGetDate(getutcdate())) + char(39)+ ' order by start_time desc'
 	  	 execute sp_executesql @SQL
 	  	  	 /*set @eventtime = (select max(start_time)  from production_starts where pu_id = @eventtrigger and start_time < dbo.fnServer_CmnGetDate(getutcdate()))*/
 	 end
 	 if (@eventscope = 2)
 	 begin
 	  	 set @SQL = 'insert into #TimeStamps select top ' + Convert(varchar(4),@versioncount) + ' start_time  from production_starts where pu_id = ' +  Convert(varchar(4),@eventtrigger) + ' and start_time < ' + char(39) + Convert(varchar(100), dbo.fnServer_CmnGetDate(getutcdate())) + char(39) +' order by start_time desc'
 	  	 execute sp_executesql @SQL
/* 	  	 set @eventtime = (select max(start_time)  from production_starts where pu_id = @eventtrigger and start_time < dbo.fnServer_CmnGetDate(getutcdate()))*/
 	 end
end
declare @count int
set @count = (select count(timestamp) from #TimeStamps)
if (@count > 1)
begin
 	 set @eventtime = (select max(timestamp) from #Timestamps)
 	 set @lasttime = (select min(timestamp) from #TimeStamps)
end
else
begin
 	 set @eventtime = (select max(timestamp) from #Timestamps)
end
if (@eventtime is null)
begin
 	 select Cast(@lasttime as varchar) as timestamp, Cast(@lasttime as varchar) as basetime
end
else
begin
 	 select Cast(@eventtime as varchar) as timestamp, Cast(@lasttime as varchar) as basetime
end
