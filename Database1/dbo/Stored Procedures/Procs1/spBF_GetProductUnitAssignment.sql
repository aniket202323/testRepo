CREATE PROCEDURE [dbo].[spBF_GetProductUnitAssignment]
  @ProdId Int,
  @Assigned Int = 1
  AS
DECLARE @DeptID int
IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @ProdId)
BEGIN
 SELECT Error = 'Error: Not a valid product Id'
 Return
END
SELECT @DeptID = dept_id From Departments d
Join Product_Family f 	 on f.Product_Family_Desc = d.Dept_Desc
Join Products p 	  	  	 on p.Product_Family_Id = f.Product_Family_Id
WHERE
p.Prod_Id = @ProdId
If @DeptID is NULL
BEGIN
 	 SELECT Error = 'Could not find Plantcode for Product'
 	 RETURN
END
IF @Assigned = 1
  	  Select UnitId = b.PU_Id
  	  ,UnitDescription = b.PU_Desc
  	  FROM PU_Products a
  	  JOIN Prod_Units b on a.PU_Id = b.PU_Id
  	  WHERE a.Prod_Id = @ProdId and b.pu_id > 0 and (b.Master_Unit is null or b.Master_Unit = b.PU_Id)
  	  ORDER BY b.Pl_Id,b.PU_Order,b.PU_Desc
ELSE
  	  Select UnitId = a.PU_Id
  	  ,UnitDescription =  a.PU_Desc
  	  FROM Prod_Units a
  	  LEFT JOIN PU_Products b  on a.PU_Id = b.PU_Id and b.Prod_Id = @ProdId
 	  JOIN Prod_Lines c on a.PL_Id = c.PL_Id
  	  WHERE   b.Prod_Id Is Null and a.pu_id > 0 
 	  and (a.Master_Unit is null or a.Master_Unit = b.PU_Id)
 	  and c.Dept_Id = @DeptID
  	  ORDER BY a.Pl_Id,a.PU_Order,a.PU_Desc
