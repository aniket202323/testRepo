create procedure [dbo].[spWALM_getReportParameters]
@ReportTypeId Int
AS
Select *, RP_Name, [Description], Portal_Mapping
From Report_Type_Parameters rtp
Join Report_Parameters rp On rtp.RP_Id = rp.RP_Id
Where rtp.Report_Type_Id = @ReportTypeId
And rp.Portal_Mapping Is Not null
And rp.RP_Name Is Not Null
