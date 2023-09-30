CREATE PROCEDURE dbo.spRS_GetDeadReports
AS
Declare @FileName varchar(255)
Declare @ServerFileLocation varchar(255)
Declare @MyId int
Declare @Ok int
CREATE TABLE #Temp_Table(
    Report_Id int,
    FileName varchar(512))
Declare MyCursor INSENSITIVE CURSOR
  For (
 	 Select Report_Id From Report_Definitions where (class = 0 or Class = 1 or Class Is Null)
      )
  For Read Only
  Open MyCursor  
 	  	 Select @Ok = 0
-- Go through the Result set and find a report for this engine to run
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      -- Check for any constraints on the current record
      exec spRS_GetReportParamValue 'FileName', @MyId, @FileName output
      exec spRS_GetReportParamValue 'ServerFileLocation', @MyId, @ServerFileLocation output
      Insert Into #Temp_Table(Report_Id, FileName) 
        Select @MyId, @ServerFileLocation + @FileName
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
Select * from #Temp_Table
Drop Table #Temp_Table
-- Old Stored Proc
/*
Select Report_Id, Value 
From Report_Definition_Parameters
Where Rtp_Id in (
 	 Select RTP_Id from Report_Type_Parameters
 	 Where RP_Id in (13, 43))
and Report_Id in (
 	 Select Report_Id
 	 From Report_Definitions
 	 Where Class = 0
 	 or Class Is Null)
order by report_Id
*/
