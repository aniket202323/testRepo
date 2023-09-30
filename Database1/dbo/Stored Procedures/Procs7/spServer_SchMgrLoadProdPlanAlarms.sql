CREATE PROCEDURE dbo.spServer_SchMgrLoadProdPlanAlarms     
@PPId int
AS
Select 
  a.PEPAT_Id,
  a.Threshold_Type_Selection,
  a.Threshold_Value,
  a.AP_Id,
  b.PEPAT_Desc
From Production_Plan_Alarms a
Join PrdExec_Path_Alarm_Types b on (b.PEPAT_Id = a.PEPAT_Id)
Where a.PP_Id = @PPId
