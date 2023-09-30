CREATE PROCEDURE [dbo].[spBF_GetPlantModelInfo] 
AS 
BEGIN
SELECT  DepartmentId = IsNull(d.Dept_Id,0),
        DepartmentName = d.Dept_Desc, 
        ProductionLineId = IsNull(pl.PL_Id,0),
        ProductionLineName = pl.PL_Desc, 
        ProductionUnitId = IsNull(pu.PU_Id,0),
        ProductionUnitName = pu.PU_Desc
        FROM Departments d
        LEFT OUTER JOIN Prod_Lines pl ON pl.Dept_Id = d.Dept_Id and pl.PL_Id > 0
        LEFT OUTER JOIN Prod_Units pu ON pu.PL_Id = pl.PL_Id and pu.Pu_Id > 0
        WHERE d.Dept_Id > 0
        ORDER BY d.Dept_Id,pl.PL_Id,pu.Pu_Id 
END
