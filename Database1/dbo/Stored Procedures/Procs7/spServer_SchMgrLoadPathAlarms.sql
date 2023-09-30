CREATE PROCEDURE dbo.spServer_SchMgrLoadPathAlarms     
@PathId int
AS
Select 
  a.PEPAT_Id,
  a.Threshold_Type_Selection,
  a.Threshold_Value,
  a.AP_Id,
  b.PEPAT_Desc
From PrdExec_Path_Alarms a
Join PrdExec_Path_Alarm_Types b on (b.PEPAT_Id = a.PEPAT_Id)
Where a.Path_Id = @PathId
