CREATE PROCEDURE [dbo].[spASP_CheckReportExists]
  @SourceType Int,
  @ReportName nvarchar(50)
AS
DECLARE @ResultCount BIT
SELECT @ResultCount = COUNT(*)
FROM Report_Definitions
WHERE Report_Name = @ReportName
AND Report_Type_Id = @SourceType
IF @ResultCount > 0
  RETURN 1
ELSE
  RETURN 0
