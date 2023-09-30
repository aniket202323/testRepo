CREATE PROCEDURE dbo.spRS_AdminIncrementSimilarReportNames
@Report_Id int
 AS
/*
spRS_AdminIncrementSimilarReportNames 38000
------------------------------
declare @Report_Id int
Select @report_id = 38000
------------------------------
*/
declare @Report_Name varchar(50)
declare @Report_Type_Id int
Create Table #Reports(Report_Id int, Report_Name varchar(50))
-- Get the name and type of the definition I'm working with
select @Report_Type_Id = Report_Type_Id, @Report_Name = report_Name from report_definitions where report_Id = @Report_Id
-- Get all the other definitions of this type with a similar name
insert into #Reports(Report_Id, Report_Name)
select Report_Id, Report_Name from report_definitions where report_name like @Report_Name + '%' order by report_id
------------------------------------------
-- Looping Example
------------------------------------------
select * from #Reports
Declare @MyId int
Declare @Count int
Declare @NewReportName varchar(50)
select @Count = 0
Declare MyCursor INSENSITIVE CURSOR
  For (Select Report_Id From #Reports)
  For Read Only
  Open MyCursor  
-- Go through the Result set and find a report for this engine to run
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
 	  	 Select @Count = @Count + 1
 	  	 Select @NewReportName = @Report_Name + ' (' + convert(varchar(3), @Count) + ')'
 	  	 update Report_Definitions Set Report_Name = @NewReportName where Report_Id = @MyId
 	  	 -- also do report_definition_parameters
 	  	 Exec sprs_AddReportDefParam @MyId, 'ReportName', @NewReportName
       Goto MyLoop1
    End -- End Loop Here
myEnd:
Close MyCursor
Deallocate MyCursor
select * from #Reports
Drop Table #Reports
