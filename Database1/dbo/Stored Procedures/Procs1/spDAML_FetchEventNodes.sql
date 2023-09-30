Create PROCEDURE [dbo].[spDAML_FetchEventNodes] 
@ProductionUnitId INT
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON
SELECT Distinct TreeLevel = '2',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0), 
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = IsNull(ec.ET_Id,0),
 	  	         Param1Name = et.ET_Desc,
 	  	         Param2Id 	 = 0, 
 	  	         Param2Name = '',
 	  	  	  	 Param3Id = 0
 	         FROM Event_Types et 
 	  	  	 INNER JOIN Event_Configuration ec ON ec.ET_Id = et.ET_Id AND ec.PU_Id = @ProductionUnitId
 	  	  	 INNER JOIN Prod_Units pu ON ec.PU_Id = pu.PU_Id 	 
 	  	  	 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id 
 	  	  	 INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	 
Union
  -- The fifth part of the dataset loads production unit production plan starts
  SELECT 	 Distinct TreeLevel = '2',
 	  	  	  	 DepartmentId = IsNull(d.Dept_Id,0),
 	  	         DepartmentName = d.Dept_Desc, 
 	  	         ProductionLineId = IsNull(pl.PL_Id,0), 
 	  	         ProductionLineName = pl.PL_Desc, 
 	  	         ProductionUnitId = IsNull(pu.PU_Id,0), 
 	  	         ProductionUnitName = pu.PU_Desc, 
 	  	         Param1Id = 1111,
 	  	         Param1Name = 'Production Plan Start',
 	  	         Param2Id 	 = 0, 
 	  	         Param2Name = '',
 	  	  	  	 Param3Id = 0
 	         FROM prdexec_path_units ppu 
 	  	  	 INNER JOIN Prod_Units pu ON ppu.PU_Id = pu.PU_Id 
                AND ppu.is_schedule_point = 1 AND ppu.PU_Id = @ProductionUnitId
 	  	  	 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id 
 	  	  	 INNER JOIN Departments d ON pl.Dept_Id = d.Dept_Id 	 
order by Param1Id
END
