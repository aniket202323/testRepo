/*
Work In Progress
July 25, 2002
Yet to be done:
Weekly Based Reports
  1) Add number of weeks to start date
  2) Parse the days portion of the ScheduleStr and put the days into a temp table
     MON,WED,FRI...
  3) Find the next day in teh day temp table AFTER Start_Date + NumberOfWeeks
     This will be the Next_Run_Time
Monthly Based Reports
One Time Only Reports
Verify that the appropriate Report_Definition Icon is being updated
Take Account for Ad-Hoc reports v.s. permanently scheduled reports.
*/
CREATE PROCEDURE dbo.spRS_AdvancedReportSchedule
@Report_Id int,
@ScheduleStr varchar(255) = Null,
@Class int = Null
AS
---------------------------------------
-- LOCAL VARS
---------------------------------------
Declare @RdId int
Declare @Schedule_Id int
Declare @Start_Date_Time DateTime
Declare @Next_Run_Time DateTime
Declare @Last_Run_Time DateTime
Declare @Status int
Declare @Last_Result int
Declare @Run_Attempts int
Declare @Error_Code int
Declare @Error_String varchar(255)
Declare @Advanced varchar(255)
Declare @Interval int
Declare @OptionCode varchar(2)
Declare @OptionInterval int
Declare @Start int
Declare @WeekDay varchar(3) --Abbreviation for day of week
---------------------------------------
-- Is this a valid report definition?
---------------------------------------
Select @RdId = Report_Id from report_definitions where Report_Id = @Report_Id
If @@RowCount = 0
  Begin
    print 'no such report definition'
    return(0)
  End
---------------------------------------
-- Is This Report_Id already scheduled?
---------------------------------------
Select @Schedule_Id = Schedule_Id From Report_Schedule Where Report_Id = @Report_Id
If @Schedule_Id Is Null
  print 'This report is NOT scheduled'
Else
  print 'This report IS scheduled'
---------------------------------------
-- Is The Input ScheduleStr Null?
---------------------------------------
If @Schedule_Id Is Null AND @ScheduleStr Is Null
  Begin
    print 'not in schedule and no schedule string was passed in'
    return(0)
  End
Else
  Begin
    --Parse out the ScheduleStr
 	 Select @OptionCode = Substring(@ScheduleStr, 1, 2)
 	 Select @Start = CharIndex('/s', @ScheduleStr) --Find the beginning of StartTime flag
 	 Select @Start_Date_Time = Convert(datetime, SubString(@ScheduleStr, @Start + 2, DataLength(@ScheduleStr) - @Start))
        Select @Last_Run_Time = @Start_Date_Time
 	 Select @WeekDay = SubString(DateName(dw, getdate()), 1, 3)
 	 
 	 print 'ScheduleStr: ' + @ScheduleStr
 	 
 	 -----------------------------
 	 -- When is Next_Run_Time?
 	 -----------------------------
 	 
 	 -- HOURLY
 	 If @OptionCode = '/h'
 	   Begin
 	     Print 'Report Will Run Minutely - Hourly'
 	     Select @Interval = Convert(int, SubString(@ScheduleStr, 3, @Start - 3))
 	     Select @Next_Run_Time = dateadd(minute, @Interval, @Start_Date_Time)
 	     Select @OptionCode 'OptionCode', 
 	  	    @Interval 'Interval',
 	  	    @Start_Date_Time 'Start_Date_Time', 
 	  	    @Next_Run_Time 'Next_Run_Time', 
 	  	    @Last_Run_Time 'Last_Run_Time',
 	  	    @WeekDay 'WeekDay', 
 	  	    @Start 'Start'
 	   End
 	 
 	  	 
 	 -- DAILY
 	 If @OptionCode = '/d'
 	   Begin
 	     Print 'Report Will Run Daily'
            Set datefirst 1 -- Set First Day of week
 	     Select @OptionInterval = SubString(@ScheduleStr, 3, 1)
            If @OptionInterval = 0 -- Every Day
              Select @Interval = 1440
 	       --Select @Next_Run_Time = dateadd(day, 1, @Start_Date_Time)
 	     If @OptionInterval = 1 -- Weekdays
              Begin
 	  	 -- Get the day of the week for @Start_Date_Time
 	  	 Select @OptionInterval = datepart(weekday, @Start_Date_Time)
 	  	 --print 'Today is the ' + convert(varchar(2), @OptionInterval) + 'th day of the week'
 	  	 Select @Interval = 1440 -- One Day by default
 	  	 If @OptionInterval = 5 --Friday
         	   Select @Interval = 4320 -- 3 days to Monday
 	  	 If @OptionInterval = 6 --Saturday
 	  	   Select @Interval = 2880 -- 2 days to Monday
 	       End
 	     If @OptionInterval = 2 -- Every (n) Days
              Begin
 	  	 Select @OptionInterval = SubString(@ScheduleStr, 5, 1)
                Select @Interval = DateDiff(minute, @Start_Date_Time, DateAdd(day, @OptionInterval, @Start_Date_Time))
 	       End
            Select @Next_Run_Time = dateadd(minute, @Interval, @Start_Date_Time)
 	     
 	   End
 	 
 	 -- WEEKLY
 	 If @OptionCode = '/w'
 	   Begin
 	     --read next 2 char to get number
 	     Print 'Weekly Based Report'
 	     Select @OptionInterval = Substring(@ScheduleStr, 3, 2)
 	     Select @OptionInterval 'OptionInterval'
 	     --Add number of weeks to @Start_Date_Time
 	     Select @Next_Run_Time = DateAdd(wk, @OptionInterval, @Start_Date_Time)
 	     -- Now get the first mon,wed or friday after this date
 	     Select @Next_Run_Time 'Next_Run_Time'
 	     If CharIndex(@WeekDay, @ScheduleStr) = 0
 	       Select 'Will not run today'
 	     Else
 	       Select 'Runs Today'
 	 
 	 
 	   End
 	 
 	 -- MONTHLY
 	 If @OptionCode = '/m'
 	   Begin
 	     Select 'every (n) minutes'
 	   End
 	 
 	 -- ONE TIME ONLY
 	 If @OptionCode = '/o'
 	   Begin
 	     Select 'One Time only'
 	   End
  End
If @Schedule_Id Is Null AND @ScheduleStr Is Not Null
  Begin
    --Insert into table
    print 'inserting new row'
    Insert Into Report_Schedule(
      Report_Id,
      Start_Date_Time,
      Interval,
      Next_Run_Time,
      Last_Run_Time,
      Status,
      Last_Result,
      Run_Attempts)
    Values(
      @Report_Id,
      @Start_Date_Time,
      @Interval,
      @Next_Run_Time,
      @Last_Run_Time,
      1,
      0,
      0)
  End
If @Schedule_Id Is Not Null AND @ScheduleStr Is Not Null
  Begin
    -- Update Table
    print 'updating row'
    Update Report_Schedule
      Set Start_Date_Time = @Start_Date_Time,
          Next_Run_Time = @Next_Run_Time,
          Last_Run_Time = @Last_Run_Time,
          Interval = @Interval,
          Status = 0,
          Last_Result = 0,
          Run_Attempts = 0
-- Took out for now DH --          Advanced = @ScheduleStr
      Where Report_Id = @Report_Id
  End
/*
If @Schedule_Id Is Not Null AND @ScheduleStr Is Null
  Begin
    -- Select from table
    print 'selecting existing row'
    Select * from report_schedule where report_Id = @report_Id
  End
*/
-- Return the Report Schedule
    Select * from report_schedule where report_Id = @report_Id
