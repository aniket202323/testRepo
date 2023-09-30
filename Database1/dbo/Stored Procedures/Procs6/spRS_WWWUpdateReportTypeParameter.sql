/*
spRS_WWWUpdateReportTypeParameter 171, 'filename', NULL
sprs_GetReportTypeParameters 171
--4986
*/
CREATE PROCEDURE [dbo].[spRS_WWWUpdateReportTypeParameter]
@ReportTypeId int,
@RP_Name varchar(50),
@Default_Value varchar(7000)
 AS
Declare @RTP_Id INT
Select @RTP_id = RTP.RTP_Id
from report_type_parameters RTP
Join Report_Parameters RP on RP.RP_Id = RTP.RP_Id
Where RTP.Report_Type_Id = @ReportTypeId
AND   RP_Name = @RP_Name
If @RTP_Id Is Not Null
 	 Update Report_Type_Parameters Set Default_Value = @Default_Value Where RTP_Id = @RTP_Id
