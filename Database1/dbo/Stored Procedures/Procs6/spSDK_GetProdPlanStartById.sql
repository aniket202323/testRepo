CREATE PROCEDURE dbo.spSDK_GetProdPlanStartById
@PPStartId 	 int
AS
SELECT 	 PPStartId  	  	 = pps.PP_Start_Id,
 	  	 DepartmentName 	  	 = d.Dept_Desc,
 	  	 PathCode 	  	  	 = pep.Path_Code,
 	  	 UnitName 	  	  	 = pu.PU_Desc,
 	  	 LineName 	  	  	 = pl.PL_Desc, 
 	  	 ProcessOrder 	  	 = pp.Process_Order, 
 	  	 StartTime 	  	  	 = pps.Start_Time, 
 	  	 EndTime 	  	  	 = pps.End_Time,
        CommentId 	  	 = pps.Comment_Id,
 	  	 PatternCode 	  	 = ppt.Pattern_Code
FROM Production_Plan_Starts pps
 	 INNER JOIN Production_Plan pp ON pps.PP_Id = pp.PP_Id
 	 LEFT JOIN PrdExec_Paths pep ON pep.Path_Id = pp.Path_Id
 	 INNER JOIN Prod_Units pu ON pu.pu_id = pps.pu_id
 	 INNER JOIN Prod_Lines pl ON pl.pl_id = pu.pl_id
 	 INNER JOIN Departments d 	 ON d.Dept_Id = pl.Dept_Id
 	 Left JOIN Production_Setup ppt ON pps.PP_Setup_Id = ppt.PP_Setup_Id
WHERE pps.PP_Start_Id = @PPStartId
