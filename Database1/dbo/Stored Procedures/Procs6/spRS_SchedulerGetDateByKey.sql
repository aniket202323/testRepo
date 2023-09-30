CREATE PROCEDURE dbo.spRS_SchedulerGetDateByKey
@Monthly varchar(10),
@Day 	  varchar(10),
@BaseDate datetime, 
@TargetDate datetime output
 AS
--**************************/
Declare @NextMonthBaseDate datetime
Declare @ThisMonthStart datetime, @ThisMonthEnd datetime, @NextMonthStart datetime, @NextMonthEnd datetime
-- One Month From BaseDate
Select @NextMonthBaseDate = DateAdd(M, 1, @BaseDate)
-------------------------------------------------------
-- Get Start and End days for this month and next month
-------------------------------------------------------
Select @ThisMonthStart = Convert(Varchar(4), DatePart(yyyy, @BaseDate)) + '-' + Convert(Varchar(2), DatePart(mm, @BaseDate)) + '-1' + ' ' + convert(varchar(2), DatePart(hh, @BaseDate)) + ':' + convert(varchar(2), DatePart(n, @BaseDate)) + ':' + convert(varchar(2), DatePart(ss, @BaseDate)) 	  	  	  	 
Select @NextMonthStart = Convert(Varchar(4), DatePart(yyyy, @NextMonthBaseDate)) + '-' + Convert(Varchar(2), DatePart(mm, @NextMonthBaseDate)) + '-1' + ' ' + convert(varchar(2), DatePart(hh, @NextMonthBaseDate)) + ':' + convert(varchar(2), DatePart(n, @NextMonthBaseDate)) + ':' + convert(varchar(2), DatePart(ss, @NextMonthBaseDate)) 	  	  	  	 
Select @ThisMonthEnd = DateAdd(d, -1, @NextMonthStart)
Select @NextMonthEnd = DateAdd(d, -1, DateAdd(M, 1, @NextMonthStart))
-------------------------------------------------------
-- Day can only coorespond with First or Last
-------------------------------------------------------
If @Day = 'Day'
 	 Begin
 	  	 If @Monthly = 'First'
 	  	  	 Begin
 	  	  	  	 If @ThisMonthStart > @BaseDate
 	  	  	  	  	 Select @TargetDate = @ThisMonthStart
 	  	  	  	 Else
 	  	  	  	  	 Select @TargetDate = @NextMonthStart
 	  	  	 End
 	  	 Else --@Monthly = 'Last'
 	  	  	 Begin
 	  	  	  	 If @ThisMonthEnd > @BaseDate
 	  	  	  	  	 Select @TargetDate = @ThisMonthEnd
 	  	  	  	 Else
 	  	  	  	  	 Select @TargetDate = @NextMonthEnd 	  	  	 
 	  	  	 End
 	  	 Goto ProcExit
 	 End
Else If @Day Is Null
 	 Begin 	  	 
 	  	 Select @TargetDate = Convert(Varchar(4), DatePart(yyyy, @BaseDate)) + '-' + Convert(Varchar(2), DatePart(mm, @BaseDate)) + '-' + @Monthly + ' ' + convert(varchar(2), DatePart(hh, @BaseDate)) + ':' + convert(varchar(2), DatePart(n, @BaseDate)) + ':' + convert(varchar(2), DatePart(ss, @BaseDate)) 	  	  	  	 
 	  	 Goto ProcExit
 	 End
/**********************************************
Possible Options can now be:
@Monthly = First, Second, Third, Fourth, Last
AND
@Day = Sun, Mon, Tue, Wed, Thr, Fri, Sat
if Last Then
 	 work backwards from end of month
Else
 	 work forwards from the start of month
**********************************************/
Declare @TargetWeekDay int, @OffSet int, @Multiplier int
Select @Multiplier = Case
 	 When @Monthly = 'First' Then 0
 	 When @Monthly = 'Second' Then 1
 	 When @Monthly = 'Third' Then 2
 	 When @Monthly = 'Fourth' Then 3
 	 When @Monthly = 'Last' Then 4
End
-------------------------------------------------------
-- Determine the SQL first day of the week
-------------------------------------------------------
Declare @DateFirst int, @TargetDay int
Declare @D Table(id int, name varchar(3))
select @DateFirst = datefirst from master..syslanguages where name = @@language
-------------------------------------------------------
-- Monday is the first day of the week
-------------------------------------------------------
if @DateFirst = 1
  Begin
 	 insert into @D(id, name) values(1,'Mon')
 	 insert into @D(id, name) values(2,'Tue')
 	 insert into @D(id, name) values(3,'Wed')
 	 insert into @D(id, name) values(4,'Thr')
 	 insert into @D(id, name) values(5,'Fri')
 	 insert into @D(id, name) values(6,'Sat')
 	 insert into @D(id, name) values(7,'Sun')
  End 
-------------------------------------------------------
-- Sunday is the first day of the week
-------------------------------------------------------
Else
  Begin
 	 insert into @D(id, name) values(1,'Sun')
 	 insert into @D(id, name) values(2,'Mon')
 	 insert into @D(id, name) values(3,'Tue')
 	 insert into @D(id, name) values(4,'Wed')
 	 insert into @D(id, name) values(5,'Thr')
 	 insert into @D(id, name) values(6,'Fri')
 	 insert into @D(id, name) values(7,'Sat')
  End 
-------------------------------------------------------
-- Determine which day should the report run on
-------------------------------------------------------
Select @TargetDay = id from @D where name = @Day
-------------------------------------------------------
-- Determine which direction to calculate FWD or BAK
-------------------------------------------------------
Declare @FirstWeekDay int, @LastWeekDay int
If @Monthly = 'Last'
 	 Begin
 	  	 ------------------------------------------
 	  	 -- Work backwards from end of THIS month
 	  	 ------------------------------------------
 	  	 Select @LastWeekDay = datepart(dw, @ThisMonthEnd)
 	  	 -- Determine Offset for THIS month from the last day backward
 	  	 Select @OffSet = (-1) * Case
 	  	  	 When @TargetDay = @LastWeekDay Then 0
 	  	  	 When @LastWeekDay > @TargetDay Then @LastWeekDay - @TargetDay 
 	  	  	 When @TargetDay > @LastWeekDay Then (@LastWeekDay - @TargetDay) + 7
 	  	 End
 	  	 Select @TargetDate = DateAdd(d, @Offset, @ThisMonthEnd)
 	  	 If @TargetDate > @BaseDate Goto ProcExit
 	  	 ------------------------------------------
 	  	 -- Work backwards from end of NEXT month
 	  	 ------------------------------------------
 	  	 Select @LastWeekDay = datepart(dw, @NextMonthEnd)
 	  	 -- Determine Offset for Next month from the last day backward
 	  	 Select @OffSet = (-1) * Case
 	  	  	 When @TargetDay = @LastWeekDay Then 0
 	  	  	 When @LastWeekDay > @TargetDay Then @LastWeekDay - @TargetDay 
 	  	  	 When @TargetDay > @LastWeekDay Then (@LastWeekDay - @TargetDay) + 7
 	  	 End
 	  	 Select @TargetDate = DateAdd(d, @Offset, @NextMonthEnd)
 	  	 Goto ProcExit
 	 End
Else
 	 Begin
 	  	 --------------------------------------------
 	  	 -- Work forward from start of THIS month
 	  	 --------------------------------------------
 	  	 Select @FirstWeekDay = datepart(dw, @ThisMonthStart)
 	  	 Select @Offset = Case
 	  	  	 When @TargetDay = @FirstWeekDay Then 0
 	  	  	 When @FirstWeekDay < @TargetDay Then @TargetDay - @FirstWeekDay
 	  	  	 When @TargetDay < @FirstWeekDay Then (7 - @FirstWeekDay) + @TargetDay
 	  	 End
 	  	 -- Recalculate the new Target Date with Offset
 	  	 Select @TargetDate = DateAdd(d, @Offset, @ThisMonthStart)
 	  	 -- Recalculate the new target date with Multiplier
 	  	 Select @TargetDate = DateAdd(d, @Multiplier * 7, @TargetDate)
 	  	 If @TargetDate > @BaseDate Goto ProcExit
 	  	 --------------------------------------------
 	  	 -- Work forward from start of NEXT month
 	  	 --------------------------------------------
 	  	 Select @FirstWeekDay = datepart(dw, @NextMonthStart)
 	  	 Select @Offset = Case
 	  	  	 When @TargetDay = @FirstWeekDay Then 0
 	  	  	 When @FirstWeekDay < @TargetDay Then @TargetDay - @FirstWeekDay
 	  	  	 When @TargetDay < @FirstWeekDay Then (7 - @FirstWeekDay) + @TargetDay
 	  	 End
 	  	 -- Recalculate the new Target Date with Offset
 	  	 Select @TargetDate = DateAdd(d, @Offset, @NextMonthStart)
 	  	 -- Recalculate the new target date with Multiplier
 	  	 Select @TargetDate = DateAdd(d, @Multiplier * 7, @TargetDate)
 	 End
ProcExit:
SELECT @TargetDate [New_Target_Date]
