-- dbo.spXLA_SearchAlarmUnits fetches production units that are tied to variables configured for alarm
-- ECR #25334: mt/4-2-2003: Current AddIn usage is to get any units associated with variables (with alarms configured)
-- The Master Units Only option may be used in the future.
CREATE PROCEDURE dbo.spXLA_SearchAlarmUnits
 	 @GetMasterUnitsOnly  TinyInt = NULL   -- 1: Yes, get master units only;  0: No, get any units
AS
If @GetMasterUnitsOnly Is NULL SELECT @GetMasterUnitsOnly = 0
If @GetMasterUnitsOnly = 0
  BEGIN
      SELECT DISTINCT p.PU_Id, p.PU_Desc
       FROM Prod_Units p
        JOIN Variables v ON v.PU_Id = p.PU_Id
        JOIN Alarm_Template_Var_Data a ON a.Var_Id = v.Var_Id
    ORDER BY p.PU_Desc
  END
Else
  BEGIN
      SELECT DISTINCT p.PU_Id, p.PU_Desc
       FROM Prod_Units p
        JOIN Variables v ON v.PU_Id = p.PU_Id
        JOIN Alarm_Template_Var_Data a ON a.Var_Id = v.Var_Id
       WHERE p.Master_Unit Is NULL
    ORDER BY p.PU_Desc
  END
--EndIf: @GetMasterUnitsOnly
