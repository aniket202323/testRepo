CREATE PROCEDURE dbo.spRS_GetReportTypeParameters
@ReportTypeId int = Null
 AS
If @ReportTypeId Is Null
  Begin
    Select RP.*, RPT.RPT_Name, 0 'Optional'
    From Report_Parameters RP
    Left Join Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
    Order By RP.RP_Name
  End
Else
  Begin
    -- Output needs to be in this order for COA (per Alex)
    -- RTP_Id, Report_Type_Id, RP_Id, Optional, Default_Value, RP_Name, Description, MultiSelect, spName, RPT_Name
    Select RTP.RTP_Id, RTP.Report_Type_Id, RTP.RP_Id, RTP.Optional, RTP.Default_Value, RP.RP_Name, RP.Description, RP.MultiSelect, RP.spName, RPT.RPT_Name, rp.Is_Default
    From Report_Type_Parameters RTP
    Left Join Report_Parameters RP On RP.RP_Id = RTP.RP_Id
    Left Join Report_Parameter_Types RPT on RP.RPT_Id = RPT.RPT_Id
    Where RTP.Report_Type_Id = @ReportTypeId
    Order By RP.RP_Name
  End
