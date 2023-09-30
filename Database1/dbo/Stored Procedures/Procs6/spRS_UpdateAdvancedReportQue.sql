CREATE PROCEDURE dbo.spRS_UpdateAdvancedReportQue
@Schedule_Id int
 AS
--***************************************************/
Declare @Start_Date_Time datetime 	 -- All Run Times Based Off Of This 
Declare @Last_Run_Time datetime 	  	 -- The Last Time The Report Actually Ran
Declare @Next_Run_Time datetime 	  	 -- The Next Time The Report Is Scheduled To Run
Declare @Prev_Run_Time datetime 	  	 -- The Scheduled Date Of The Previous Run
Declare @Temp_Run_Time datetime 	  	 -- Temporary Storage
Declare @Now datetime 	  	  	  	 -- Current Timestamp
Declare @Next_Weekly_Interval datetime
Declare @TargetDate datetime
Declare @Interval int 	  	  	  	 -- Report_Schedule Interval Field
Declare @Daily varchar(255) 	  	  	 -- Report_Schedule Daily Field
Declare @Weekly varchar(255) 	  	 -- Report_Schedule Weekly Field
Declare @Monthly varchar(255) 	  	 -- Report_Schedule Monthly Field
Declare @StartDate varchar(10) 	  	 -- DatePart of @Start_Date_Time
Declare @StartTime varchar(10) 	  	 -- TimePart of @Start_Date_Time
Declare @Today varchar(3) 	  	  	 -- 3 Letter abbreviation for a day of the week (Sun, Mon...)
Declare @PriorWeekId varchar(10)
Declare @WeekId varchar(10)
Declare @NextWeekId varchar(10)
Declare @FirstDayOfWeek int
Declare @Sunday int 	  	  	  	  	 -- Integer Constant (Sunday = 7)
Declare @Monday int 	  	  	  	  	 -- Integer Constant 	 (Monday = 1)
Declare @PrevDate DateTime,@CurrentDate DateTime,@NextDate DateTime
Declare @A int
Declare @B int
Declare @C int
Declare @D int
Declare @EveryNWeeks int
Declare @PrevDay varchar(3)
Declare @NextDay varchar(3)
Declare @DayStr varchar(28)
Declare @Days varchar(28)
Declare @Temp varchar(28)
Declare @Day varchar(3)
Declare @Desc varchar(255)
-----------------------------------
-- Initialize Days Of The Week
-----------------------------------
Select @Days = 'Mon,Tue,Wed,Thr,Fri,Sat,Sun'
-------------------------------------------------------
-- What Day Of The Week Is Considered The 'First' Day?
-- If DateFirst = 7 Then Sunday Is The First Day
-- Else If DateFirst = 1 Then Monday Is The First Day
-------------------------------------------------------
select @FirstDayOfWeek = DateFirst from master..syslanguages where name = @@language
Select @Sunday = 7
Select @Monday = 1
---------------------------------------
-- Get Current Timestamp
---------------------------------------
Select @Now = dbo.fnServer_CmnGetDate(getutcdate())
--Select @Now = '2007-05-06 7:02 AM'
--Print 'Current Time Is ' + convert(varchar(25), @Now, 120)
---------------------------------------
-- Get Schedule For This Report
---------------------------------------
Select 
 	 @Last_Run_Time = Last_Run_Time,
 	 @Start_Date_Time = Start_Date_Time, 
     	 @Next_Run_Time = IsNull(Next_Run_Time, Start_Date_Time),
 	 @Interval = Interval,
 	 @Daily = Daily,
 	 @Monthly = Monthly
From Report_Schedule 
Where schedule_Id = @Schedule_Id
Select @Prev_Run_Time = @Last_Run_Time
---------------------------------------
-- Separate Start Date From Start Time
-- Monthly could be numeric or text = (First, Second, Third, Fourth, Last)
---------------------------------------
If @Monthly Is Null
 	 Select @StartDate = convert(varchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(varchar(10), DatePart(mm, @Start_Date_Time)) + '-' + convert(varchar(10), DatePart(dd, @Start_Date_Time))
Else
 	 If (ISNUMERIC(@Monthly) = 1) 
 	  	 Select @StartDate = convert(varchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(varchar(10), DatePart(mm, @Start_Date_Time)) + '-' + @Monthly
 	 Else
 	  	 Select @StartDate = convert(varchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(varchar(10), DatePart(mm, @Start_Date_Time)) + '-' + convert(varchar(10), DatePart(dd, @Start_Date_Time))
-- Get the time that the report is scheduled to execute
If (DatePart(mi, @Start_Date_Time)) < 10 
 	 Select @StartTime = convert(varchar(10), DatePart(hh, @Start_Date_Time)) + ':0' + convert(varchar(10), DatePart(mi, @Start_Date_Time)) 
Else
 	 Select @StartTime = convert(varchar(10), DatePart(hh, @Start_Date_Time)) + ':' + convert(varchar(10), DatePart(mi, @Start_Date_Time)) 
-------------------------------------------
-- What day of the week is Start_Date_Time
-------------------------------------------
Create Table #d(id int, 	 name varchar(3))
if @FirstDayOfWeek = @Monday
  Begin
 	 insert into #d(id, name) values(1,'Mon')
 	 insert into #d(id, name) values(2,'Tue')
 	 insert into #d(id, name) values(3,'Wed')
 	 insert into #d(id, name) values(4,'Thr')
 	 insert into #d(id, name) values(5,'Fri')
 	 insert into #d(id, name) values(6,'Sat')
 	 insert into #d(id, name) values(7,'Sun')
  End 
-- Sunday is the first day of the week
Else
  Begin
 	 insert into #d(id, name) values(1,'Sun')
 	 insert into #d(id, name) values(2,'Mon')
 	 insert into #d(id, name) values(3,'Tue')
 	 insert into #d(id, name) values(4,'Wed')
 	 insert into #d(id, name) values(5,'Thr')
 	 insert into #d(id, name) values(6,'Fri')
 	 insert into #d(id, name) values(7,'Sat')
  End 
Select @Today = name from #d where id = DatePart(dw, @Start_Date_Time)
--===============================
-- Minute/Hourly
--===============================
If @Interval Is Not Null
  Begin
 	 If (Convert(int, @Interval) = 1440) 
 	  	 Select @Desc = 'This Is An Interval Report And Will Run Every Day At ' + @StartTime
 	 Else
 	  	 Select @Desc = 'This Is An Interval Report And Will Run Every ' + convert(varchar(5), @Interval) + ' Minutes Beginning At ' + @StartTime
 	 print @Desc
 	 Select @Prev_Run_Time = @Start_Date_Time 	 
 	 Select @Next_Run_Time = Dateadd(minute, @Interval, @Prev_Run_Time)
 	 While @Next_Run_Time < @Now
 	   Begin
 	  	 Select @Prev_Run_Time = @Next_Run_Time        
 	  	 Select @Next_Run_Time = Dateadd(minute, @Interval, @Next_Run_Time)
 	   End
 	 Select @PrevDate = @Prev_Run_Time, @NextDate = @Next_Run_Time
  End
--===============================
-- Monthly Report
--===============================
Else If @Monthly Is Not Null
  Begin
 	 
 	 -- is monthly numeric?
 	 If (ISNUMERIC(@Monthly) = 1) 
 	   Begin
 	  	 exec spRS_SchedulerGetDateByKey @Monthly, @Daily, @Start_Date_Time, @Next_Run_Time output
 	  	 Select @Desc = 'This Is A Monthly Report And Will Run On Day ' + @Monthly + ' Of Every Month At ' + @StartTime --+ ' Beginning ' + @StartDate
 	  	 While @Next_Run_Time < @Now
 	  	  	 Select @Next_Run_Time = Dateadd(m, 1, @Next_Run_Time)
 	  	 
 	  	 Select @Prev_Run_Time = DateAdd(m, -1, @Next_Run_Time)
 	  	 Select @Start_Date_Time = @Prev_Run_Time 	  	 
 	   End
 	 Else
 	   Begin
 	  	 Select @Desc = 'This Is A Monthly Report And Will Run Every ' + @Monthly + ' ' + @Daily + ' At ' + @StartTime
 	  	 Select @Start_Date_Time = DateAdd(M, -1, @Start_Date_Time)
 	  	 -- Get the next occurance
 	  	 exec spRS_SchedulerGetDateByKey @Monthly, @Daily, @Start_Date_Time, @Next_Run_Time output
 	  	 While (@Next_Run_Time < @Now)
 	  	  	 Begin
 	  	  	  	 --print 'in while loop'
 	  	  	  	 Select @Start_Date_Time = @Next_Run_Time
 	  	  	  	 exec spRS_SchedulerGetDateByKey @Monthly, @Daily, @Start_Date_Time, @Next_Run_Time output
 	  	  	  	 Select @Prev_Run_Time = @Start_Date_Time
 	  	  	 End
-- 	  	 Select @Start_Date_Time [Start_Date_Time], @Next_Run_Time [Next_Run_Time]
 	  	 
 	   End
 	 Goto spend
  End
--===============================
-- Weekly
--===============================
Else If @Daily Is Not Null
  Begin
 	 Select @Desc = 'This Is A Daily Report And Will Run Every ' + @Daily + ' At ' + @StartTime -- + ' Beginning ' + @StartDate
 	 Print @Desc
 	 Select @EveryNWeeks = convert(int, @Weekly)
 	 Select @CurrentDate = @Start_Date_Time
 	 Select @DayStr = @Daily
 	 Declare @TempDayStr varchar(255)
 	 Declare @Date1 datetime
 	 Create Table #t(DayName varchar(3), 	 MyDate datetime)
 	 Select @TempDayStr = @DayStr
 	 While (Datalength(LTRIM(RTRIM(@TempDayStr))) > 1) 
 	   Begin
 	  	 Select @Day = SubString(@tempDayStr, 1, 3)
 	  	 if DataLength(@TempDayStr) = 3
 	  	  	 Select @TempDayStr = ''
 	  	 Else
 	  	  	 Select @TempDayStr = SubString(@TempDayStr, 5, DataLength(@TempDayStr) - 4)
 	  	 -- how many days away from this day is today
 	 
 	  	 Select @A = Id From #d Where Name = @Day
 	  	 Select @B = DatePart(dw, @Now)
 	  	 Select @D = (@A - @B)
 	  	 Select @Temp_Run_Time = DateAdd(Day, @D, @Now)
 	  	 Select @Date1 = Convert(varchar(4), DatePart(yyyy, @Temp_Run_Time)) + '-' + Convert(Varchar(2), DatePart(mm, @Temp_Run_Time)) + '-' + convert(varchar(2), DatePart(dd, @Temp_Run_Time)) + ' ' + @StartTime
 	  	 If @Date1 > @Now
 	  	  	 Select @Date1 = DateAdd(week, -1, @Date1)
 	  	 Insert Into #t(DayName, MyDate) Values(@Day, @Date1)
 	 
 	   End
 	 -- Previous Run
 	 Select top 1 @PrevDate = MyDate from #t order by MyDate desc
 	 -- Next Run
 	 Select top 1 @NextDate = MyDate from #t order by MyDate asc
 	 Select @NextDate = DateAdd(week, 1, @NextDate)
 	 Goto Finished
  End
Finished:
 	 Select @Prev_Run_Time = @PrevDate, @Next_Run_Time = @NextDate
 	 goto SPEnd
--===============================
-- Update
--===============================
SPEnd:
Drop Table #d
Delete From Report_Que Where Schedule_Id = @Schedule_Id
--Select @Schedule_Id [Schedule_Id], @Now [Now], @Start_Date_Time [Start_Date_Time], @Prev_Run_Time [Last_Date_Time], @Next_Run_Time [Next_Run_Time], @Desc [Description]
--/*
Update Report_Schedule Set
 	 Last_Run_Time = @Now,
 	 Start_Date_Time = @Prev_Run_Time,
 	 Next_Run_Time = @Next_Run_Time,
 	 Description = @Desc
 	 Where Schedule_Id = @Schedule_Id
--*/
print 'Report_Schedule Update Done.'
