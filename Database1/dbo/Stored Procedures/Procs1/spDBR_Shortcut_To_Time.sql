Create Procedure dbo.spDBR_Shortcut_To_Time
@timeformula varchar(50) = null,
@relativetime datetime = null,
@InTimeZone varchar(200) = ''
AS
declare @elocation int
declare @newstr varchar(50)
declare @myshortcutstring varchar(50)
declare @mytime datetime
declare @tempmytime datetime
declare @firstoperator varchar(1)
declare @startlocation int
declare @endlocation int
declare @myshortcutitem varchar(50)
declare @minus int
declare @plus int
declare @delta int
declare @sitehr int
declare @sitemi int
declare @dbtimezone varchar(200)
Select @sitehr = value from Site_Parameters where Parm_Id = 14
Select @sitemi = value from Site_Parameters where Parm_Id = 15
Select @dbtimezone = value from site_parameters where parm_id=192
if IsDate(@timeformula) = 1
begin
 	 select @timeformula as [Time]
end
else
begin
 	 create table #TimeTable
 	 (
 	  	 value datetime
 	 )
 	 select @myshortcutstring = lower(@timeformula)
 	 if (@relativetime is null)
 	 begin 	 
 	  	 select @mytime = dbo.fnServer_CmnGetDate(getutcdate())
 	 end
 	 else
 	 begin
 	  	 select @mytime = @relativetime
 	 end
 	 select @mytime = dbo.fnserver_cmnConvertTime(@mytime,@dbtimezone,@InTimeZone)
 	 
 	 
 	 if (substring(@myshortcutstring, 1, 1) = '+' or substring(@myshortcutstring, 1, 1) = '-')
 	 begin
 	  	 select @firstoperator = substring(@myshortcutstring, 1, 1)
 	  	 select @startlocation = 1
 	 end
 	 else
 	 begin
 	  	 select @firstoperator = '-'
 	  	 select @startlocation = 0
 	 end
 	 
 	 while (@startlocation < len(@myshortcutstring))
 	 begin
 	  	 select @minus = charindex('-', @myshortcutstring, @startlocation+1)
 	  	 select @plus = charindex('+', @myshortcutstring, @startlocation + 1)
 	 
 	        If @minus < @plus And not @minus =0
 	  	 begin
 	             select @endlocation = @minus - 1
 	  	 end
 	  	 else if @plus < @minus and not @plus =0
 	  	 begin 
 	             select @endlocation = @plus - 1
 	  	 end
 	  	 else if  @minus > 1
 	  	 begin
 	             select @endlocation = @minus - 1
 	  	 end
 	  	 else if @plus > 1
 	  	 begin
 	             select @endlocation = @plus - 1
 	  	 end
 	         Else
 	  	 begin
 	             select @endlocation = Len(@myshortcutstring)
 	         end
 	 
 	         if @startlocation = 0
 	  	 begin
 	  	  	 select @myshortcutitem = substring(@MyShortcutString, 1, @EndLocation)
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select @myshortcutitem = substring(@MyShortcutString, @StartLocation, @EndLocation + 1)
 	  	 end
 	         
 	               
 	         If @StartLocation = 0
 	  	 begin
 	             If not substring(@MyShortcutItem, 1, 1) = '+' And not substring(@MyShortcutItem, 1, 1) = '-'
 	  	     begin
 	                 select @MyShortcutItem = @FirstOperator + @MyShortcutItem
 	             End
 	         End
 	 
 	 
 	         If charindex('EOY', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @MyTime = Convert(datetime, '12/31/' + convert(varchar(4),DatePart(yyyy,dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))))
 	  	 end 	 
 	  	 else if charindex('BOY', @myshortcutitem, 0) > 0
 	  	 begin
 	          	 select @MyTime = Convert(datetime, '1/1/' + convert(varchar(4),DatePart(yyyy,dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))))
 	  	 end
 	         Else If charindex('BOM', @myshortcutitem, 0) > 0
 	  	 begin
 	          	 select @MyTime = Convert(datetime, convert(varchar(2),DatePart(month, dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))) + '/1/' + convert(varchar(4),DatePart(yyyy,dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))))
 	  	 end
 	         Else If charindex ('EOM', @myshortcutitem, 0) > 0
 	  	 begin
 	          	 select @MyTime = DateAdd(day, -1, DateAdd(month, 1, Convert(datetime, convert(varchar(2),DatePart(month, dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))) + '/1/' + convert(varchar(4),DatePart(yyyy,dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone))))))
 	  	 end
 	         Else If charindex('SU', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) -1
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('SA', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) - 7
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('F', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) - 6
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('TH', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) -5
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('WED', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) -4
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('TU', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) -3
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('MON', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @delta = DatePart(weekday, @MyTime) -2
 	  	  	 select @delta = @delta * - 1
 	  	  	 if (@delta > 0)
 	  	  	 begin
 	  	  	  	 select @delta = (@delta - 7)
 	  	  	 end
 	  	         select @MyTime = DateAdd(day, @delta, @MyTime)
 	  	 end
 	         Else If charindex('TO', @myshortcutitem, 0) > 0
 	  	 begin 	          	 
 	          	 SELECT @tempmytime = dateadd(HOUR, @sitehr, dateadd(MINUTE, @sitemi, dateadd(dd,0, datediff(dd,0, dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone)))))
 	          	 IF @tempmytime > @mytime
 	          	   BEGIN
 	          	  	 select @mytime = dateadd(dd,-1, @tempmytime)
 	          	   END
 	          	 ELSE
 	          	   BEGIN
 	          	  	 select @mytime = @tempmytime
 	          	   END 	          	 
 	  	 end
 	         Else If charindex('YE', @myshortcutitem, 0) > 0
 	  	 begin
 	          	 select @tempmytime = dateadd(HOUR, @sitehr, dateadd(MINUTE, @sitemi, dateadd(dd,-1, datediff(dd,0, dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone)))))
 	          	 IF @tempmytime > dateadd(dd,-1, @MyTime)
 	          	   BEGIN
 	          	  	 select @MyTime = dateadd(dd,-1, @tempmytime)
 	          	   END
 	          	 ELSE
 	          	   BEGIN
 	          	  	 select @MyTime = @tempmytime
 	          	   END 	          	 
 	  	 end
 	         Else If charindex('N', @MyShortcutItem, 0) > 0
 	  	 begin
 	  	  	 if (@relativetime is null)
 	  	  	 begin 	 
 	  	  	  	 select @MyTime = dbo.fnserver_cmnConvertTime(dbo.fnServer_CmnGetDate(getutcdate()),@dbtimezone,@InTimezone)
 	  	  	 end
 	  	  	 else
 	  	  	 begin
 	  	  	  	 select @mytime = @relativetime
 	  	  	 end
 	  	 end
 	  	 Else If charindex('SEC', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @elocation = charindex('S', @myshortcutitem, 2) - 2
 	  	  	 select @newstr = ltrim(rtrim(substring(@myshortcutitem, 2, @elocation)))
 	 
 	  	  	 if substring(@MyShortcutItem, 1, 1) = '-'
 	  	  	 begin
 	  	  	      	 select @NewStr = '-' + @NewStr
 	  	  	 end
 	  	  	 select @mytime = dateadd(second, convert(int,@newstr), @mytime) 
 	  	 end
 	         Else If charindex('M', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @elocation = charindex('M', @myshortcutitem, 2) - 2
 	  	  	 select @newstr = ltrim(rtrim(substring(@myshortcutitem, 2, @elocation)))
 	 
 	  	  	 if substring(@MyShortcutItem, 1, 1) = '-'
 	  	  	 begin
 	  	  	      	 select @NewStr = '-' + @NewStr
 	  	  	 end
 	  	  	 select @mytime = dateadd(minute, convert(int,@newstr), @mytime) 
 	  	 end
 	         Else If charindex('H', @myshortcutitem, 0) > 0
 	  	 begin
 	  	  	 select @elocation = charindex('H', @myshortcutitem, 2) - 2
 	  	  	 select @newstr = ltrim(rtrim(substring(@myshortcutitem, 2, @elocation)))
 	 
 	  	  	 if substring(@MyShortcutItem, 1, 1) = '-'
 	  	  	 begin
 	  	  	      	 select @NewStr = '-' + @NewStr
 	  	  	 end
 	  	  	 select @mytime = dateadd(hour, convert(int,@newstr), @mytime) 
 	  	 end
 	         Else If charindex('D', @MyShortcutItem, 0) > 0 
 	  	 begin
 	  	  	 select @elocation = charindex('D', @myshortcutitem, 2) - 2
 	  	  	 select @newstr = ltrim(rtrim(substring(@myshortcutitem, 2, @elocation)))
 	 
 	  	  	 if substring(@MyShortcutItem, 1, 1) = '-'
 	  	  	 begin
 	  	  	      	 select @NewStr = '-' + @NewStr
 	  	  	 end
 	  	  	 select @mytime = dateadd(day, convert(int,@newstr), @mytime) 
 	  	 end
 	         Else If charindex('W', @MyShortcutItem, 0) > 0
 	  	 begin
 	  	  	 select @elocation = charindex('W', @myshortcutitem, 2) - 2
 	  	  	 select @newstr = ltrim(rtrim(substring(@myshortcutitem, 2, @elocation)))
 	 
 	  	  	 if substring(@MyShortcutItem, 1, 1) = '-'
 	  	  	 begin
 	  	  	      	 select @NewStr = '-' + @NewStr
 	  	  	 end
 	  	  	 select @mytime = dateadd(week, convert(int,@newstr), @mytime) 
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 select @mytime = @timeformula
 	  	 end
 	 
 	  	 select @startlocation = @startlocation + @endlocation + 1
 	 end
 	 select @MyTime as [Time]
end
