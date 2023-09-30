CREATE PROCEDURE dbo.spSDK_QueryVariableSpecificationChanges
 	 @LineMask 	  	  	 nvarchar(50),
 	 @UnitMask 	  	  	 nvarchar(50),
 	 @VarMask 	  	  	  	 nvarchar(100),
 	 @ProductMask 	  	 nvarchar(50),
 	 @StartTime 	  	  	 DATETIME,
 	 @EndTime 	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
SELECT 	 @LineMask = 	  	 REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = 	  	 REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = 	  	 REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = 	  	 REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @VarMask = 	  	 REPLACE(COALESCE(@VarMask, '*'), '*', '%')
SELECT 	 @VarMask = 	  	 REPLACE(REPLACE(@VarMask, '?', '_'), '[', '[[]')
SELECT 	 @ProductMask = 	 REPLACE(COALESCE(@ProductMask, '*'), '*', '%')
SELECT 	 @ProductMask = 	 REPLACE(REPLACE(@ProductMask, '?', '_'), '[', '[[]')
IF @EndTime IS NULL
BEGIN
 	 IF @StartTime IS NULL
 	 BEGIN
 	  	 SELECT @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	 END ELSE
 	 BEGIN
 	  	 SELECT @EndTime = DATEADD(DAY, 1, @StartTime)
 	 END
END
IF @StartTime IS NULL
BEGIN
 	 IF @VarMask = '%' AND @ProductMask = '%'
 	 BEGIN
 	  	 SELECT @StartTime = DATEADD(DAY, -1, @EndTime)
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @StartTime = '1970-01-01'
 	 END
END
SELECT 	 SpecificationId = VS_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc,
 	  	  	 VariableName = v.Var_Desc, 
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProductDesc = p.Prod_Desc, 
 	  	  	 CharacteristicName = v.Test_name,
 	  	  	 EffectiveDate = vs.Effective_Date, 
 	  	  	 ExpirationDate = vs.Expiration_Date, 
 	  	  	 CommentId = vs.Comment_Id,
 	  	  	 URL = vs.U_Reject, 
 	  	  	 UWL = vs.U_Warning, 
 	  	  	 UUL = vs.U_User, 
 	  	  	 TGT = vs.Target, 
 	  	  	 LUL = vs.L_User, 
 	  	  	 LWL = vs.L_Warning, 
 	  	  	 LRL = vs.L_Reject,
 	  	  	 LEL = vs.L_Entry, 
 	  	  	 UEL = vs.U_Entry, 
 	  	  	 TestingFrequency = CASE 
 	  	  	  	  	  	  	  	  	  	 WHEN vs.Test_Freq IS NULL THEN v.Sampling_Interval 
 	  	  	  	  	  	  	  	  	  	 ELSE vs.Test_Freq 
 	  	  	  	  	  	  	  	  	 END
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON  	 pu.PL_Id = pl.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	  	 pu.PU_Id = v.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Var_Desc LIKE @VarMask 
 	 JOIN 	  	  	 Var_Specs vs 	  	  	 ON 	  	 v.Var_Id = vs.Var_Id
 	 JOIN 	  	  	 PU_Products pup 	  	 ON 	  	 pup.PU_Id = pu.PU_Id
 	 JOIN 	  	  	 Products p 	  	  	  	 ON 	  	 p.Prod_Id = pup.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 p.Prod_Id = vs.Prod_Id
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 LEFT JOIN 	 User_Security vars 	 ON 	  	 pu.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE 	 (p.Prod_Code LIKE @ProductMask)
 	 AND 	 (vs.Effective_Date BETWEEN @StartTime AND @EndTime)
 	 AND 	 COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2
 	 ORDER BY v.Var_Desc, p.Prod_Code, vs.Effective_Date
