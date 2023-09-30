
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_UseAggTableOrNot] 

AS 

BEGIN
  SELECT COALESCE(Value, 0) FROM Site_parameters where parm_Id = 607 --416--607
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_UseAggTableOrNot] TO [ComXClient]
