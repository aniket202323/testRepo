CREATE PROCEDURE dbo.spRS_GetReportWebPages
@RWP_Id int = Null
 AS
If @RWP_Id Is Null
  Begin
    Select *
    From Report_WebPages
    Where RWP_Id not in (1,2,3,4,5)
 	 --These Id's Are Reserved
  End
Else
  Begin
    Select *
    From Report_WebPages
    Where RWP_Id = @RWP_Id
  End
