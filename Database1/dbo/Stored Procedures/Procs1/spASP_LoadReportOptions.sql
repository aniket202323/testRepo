CREATE PROCEDURE [dbo].[spASP_LoadReportOptions]
  @Analysis_Id INT
AS
SELECT Report_Name, [Description], OwnerId Saved_By,
       [TimeStamp], Xml_Version, Xml_Data
FROM Report_Definitions rd
WHERE rd.Report_Id = @Analysis_Id
