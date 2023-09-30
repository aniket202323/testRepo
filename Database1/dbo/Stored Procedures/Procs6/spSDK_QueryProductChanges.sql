Create Procedure dbo.spSDK_QueryProductChanges
 	 @LineMask 	  	 nvarchar(50) = NULL,
 	 @UnitMask 	  	 nvarchar(50) = NULL,
 	 @StartTime 	  	 DATETIME  	 = NULL,
 	 @EndTime 	  	  	 DATETIME  	 = NULL,
 	 @UserId 	  	  	 DATETIME  	 = NULL
AS
SET 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SET 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SET 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SET 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
IF @EndTime IS NULL
BEGIN
 	 SELECT @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
END
IF @StartTime IS NULL
BEGIN
 	 SELECT @StartTime = DATEADD(DAY, -1, @EndTime)
END
-- Mask For Name Has Not Been Specified
SELECT 	 ProductChangeId = Start_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 StartTime = ps.Start_Time, 
 	  	  	 EndTime = ps.End_Time, 
 	  	  	 Confirmed = ps.Confirmed, 
 	  	  	 p.Prod_Code, 
 	  	  	 CommentId = ps.Comment_Id,
                        SignatureId = ps.Signature_Id
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	 JOIN 	  	  	 Production_Starts ps 	 ON  	 ps.PU_Id = pu.PU_Id
 	 JOIN 	  	  	 Products p  	  	  	  	 ON  	 ps.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 WHERE 	 ps.Start_Time <= @EndTime
 	 AND 	 (ps.End_Time > @StartTime OR ps.End_Time IS NULL)
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
