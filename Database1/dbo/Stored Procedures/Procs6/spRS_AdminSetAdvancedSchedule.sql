CREATE PROCEDURE dbo.spRS_AdminSetAdvancedSchedule
@Schedule_Id  	  	 INT = 0,
@Report_Id  	  	  	 INT = 0,
@Start_Date_Time  	 VARCHAR(255),
@Interval  	  	  	 VARCHAR(255) = NULL,
@Daily  	  	  	  	 VARCHAR(255) = NULL, 
@Monthly  	  	  	 VARCHAR(255) = NULL,
@Priority 	  	  	 INT,
@InTimeZone 	  	  	 varchar(200) = ''
AS
-- Am I updating an existing schedule or adding a new row
Declare @New_Schedule_Id int
/*
select * from report_schedule
select * from return_error_codes where group_id = 2
*/
If @Schedule_Id = 0
 	 Begin
 	  	 Insert Into Report_Schedule(Report_Id, Start_Date_Time, Last_Run_Time, Interval, Daily, Monthly)
 	  	 Values(@Report_Id, dbo.fnServer_CmnConvertToDBTime(Convert(datetime, @Start_Date_Time),@InTimeZone), dbo.fnServer_CmnConvertToDBTime(Convert(datetime, @Start_Date_Time),@InTimeZone), @Interval, @Daily, @Monthly)
 	  	 Select @New_Schedule_Id = Scope_Identity()
 	  	 --Update The Definition To Reflect It Is Scheduled
 	  	 Update Report_Definitions Set
 	  	  	 Class = 2, 
 	  	  	 Priority = @Priority
 	  	 Where Report_Id = @Report_Id
 	  	 --Change Any Tree Node Icons Using The Report Def
 	  	 Update Report_Tree_Nodes Set
 	  	  	 Node_Id_Type = 4 	  	 
 	  	 Where Report_Def_Id = @Report_Id
 	 End
Else
 	 Begin
 	  	 Update Report_Definitions Set Priority = @Priority Where Report_Id = (Select Report_Id From Report_Schedule Where Schedule_Id = @Schedule_Id)
 	  	 Select @New_Schedule_Id = @Schedule_Id
 	  	 Update Report_Schedule Set
 	  	  	 Start_Date_Time = dbo.fnServer_CmnConvertToDBTime(Convert(datetime, @Start_Date_Time),@InTimeZone),
 	  	  	 Interval = @Interval,
 	  	  	 Daily = @Daily,
 	  	  	 Monthly = @Monthly
 	  	 Where Schedule_Id = @Schedule_Id
 	 End
Exec spRS_UpdateAdvancedReportQue @New_Schedule_Id
Select * from Report_Schedule Where Schedule_Id = @New_Schedule_Id
