/* This SP Used By Report Server V2 */
CREATE PROCEDURE dbo.spRS_GetReportTypeDescription
@ReportTypeId int
 AS
Select Description
From Report_Types
Where Report_Type_Id = @ReportTypeId
