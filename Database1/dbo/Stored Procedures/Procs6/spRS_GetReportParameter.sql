CREATE PROCEDURE dbo.spRS_GetReportParameter
@ParamId int = Null
 AS
If @ParamId Is Null
  Begin
    Select RP.*, RPT.RPT_Name, RPG.Group_Name
    From Report_Parameters RP
    Left Join Report_Parameter_Types RPT on RPT.RPT_Id = RP.RPT_Id
    Left Join Report_Parameter_Groups RPG on RPG.Group_Id = RP.RPG_Id
    Order By RP.RP_Name
  End
Else
  Begin
    Select RP.*, RPT.RPT_Name, RPG.Group_Name
    From Report_Parameters RP
    Left Join Report_Parameter_Types RPT on RPT.RPT_Id = RP.RPT_Id
    Left Join Report_Parameter_Groups RPG on RPG.Group_Id = RP.RPG_Id
    Where RP.RP_Id = @ParamId
    Order By RP.RP_Name
  End
