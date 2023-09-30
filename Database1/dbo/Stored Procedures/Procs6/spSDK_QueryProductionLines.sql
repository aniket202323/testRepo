CREATE PROCEDURE 	 dbo.spSDK_QueryProductionLines
 	 @LineMask 	 nvarchar(50) 	 = NULL,
 	 @UserId 	  	 INT 	  	  	  	 = NULL,
 	 @DeptMask 	 nvarchar(50) 	 = NULL
AS
SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @DeptMask = REPLACE(COALESCE(@DeptMask, '*'), '*', '%')
SELECT 	 @DeptMask = REPLACE(REPLACE(@DeptMask, '?', '_'), '[', '[[]')
SELECT 	 ProductionLineId = pl.PL_Id,
 	  	  	 DeptName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 CommentId = pl.Comment_Id,
 	  	  	 ExtendedInfo = pl.Extended_Info
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	 ON d.Dept_Id = pl.Dept_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 pl.PL_Desc LIKE @LineMask AND
 	  	  	  	  	  	  	  	  	  	  	  	 d.Dept_Desc LIKE @DeptMask AND
 	  	  	  	  	  	  	  	  	  	  	  	 pl.PL_Id > 0
 	 LEFT JOIN 	 User_Security pls 	 ON pl.Group_Id = pls.Group_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	 pls.User_Id = @UserId
 	 WHERE COALESCE(pls.Access_Level, 3) >= 2
 	 ORDER BY d.Dept_Desc, pl.PL_Desc
