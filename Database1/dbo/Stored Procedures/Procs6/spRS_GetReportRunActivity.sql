CREATE PROCEDURE dbo.spRS_GetReportRunActivity
@Run_Id int = Null,
@Report_Id int = Null
AS
If @Run_Id Is Null 
 	 Begin
 	  	 If @Report_Id Is Null
 	  	  	 Begin
 	  	  	  	 -- I Cannot Figure Out What The Run_Id Is
 	  	  	  	 Select 'SP Cannot Locate Run Activity With Out Either The Run_Id Or Report_Id'
 	  	  	  	 Return (0)
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 -- Get The Last Known Run_Id
 	  	  	  	 Select @Run_Id = MAX(Run_Id) from report_runs where report_Id = @Report_Id
 	  	  	 End
 	 End
Select Time, Message From Report_Engine_Activity
Where Run_Id = @Run_Id
And ErrorLevel In (2,3)
