CREATE PROCEDURE 	 dbo.spSDK_GetProductionLineById
 	 @PLId 	  	  	  	 INT
AS
SELECT 	 ProductionLineId 	 = pl.PL_Id,
 	  	  	 DeptName  	  	  	 = d.Dept_Desc,
 	  	  	 LineName 	  	  	  	 = pl.PL_Desc,
 	  	  	 CommentId 	  	  	 = pl.Comment_Id,
 	  	  	 ExtendedInfo 	  	 = pl.Extended_Info
 	 FROM 	  	  	 Departments d
 	 INNER JOIN 	 Prod_Lines pl 	 ON pl.Dept_Id = d.Dept_Id
 	 WHERE PL_Id = @PLId
 	 ORDER BY PL_Desc
