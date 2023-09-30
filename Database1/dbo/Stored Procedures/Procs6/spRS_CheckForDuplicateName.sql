/* This SP Used by Report Server V2 */
/*
No duplicates of the same base report type
*/
CREATE PROCEDURE dbo.spRS_CheckForDuplicateName
@NewName varchar(255),
@ReportTypeId int
 AS
Declare @Report_Name varchar(255)
Select @Report_Name = Report_Name
from Report_Definitions
where Report_Name = @NewName
and Report_Type_Id = @ReportTypeId
If @@Rowcount > 0
  Begin
 	 Select 1
 	 Return (1)
  End
Else
  Begin
 	 Select 0
 	 Return(0)
  End
