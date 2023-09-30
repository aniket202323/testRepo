CREATE PROCEDURE [dbo].[spRS_UpdateReportData]
@Report_Id int
 AS
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Set NoCount On
Update Report_Definitions Set TimeStamp = @Now Where Report_Id = @Report_Id
Select * from Report_Definition_Data Where Report_Id = @Report_Id
return (0)
