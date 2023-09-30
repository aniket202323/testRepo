CREATE PROCEDURE dbo.spSDK_QueryVariableSpecifications
 	 @LineMask 	  	  	 nvarchar(50),
 	 @UnitMask 	  	  	 nvarchar(50),
 	 @VarMask 	  	  	  	 nvarchar(50),
 	 @ProdCodeMask 	  	 nvarchar(50),
 	 @TimeStamp 	  	  	 DATETIME,
 	 @UserId 	  	  	  	 INT 	  	  	  	 = NULL
AS
IF @TimeStamp IS NULL 
BEGIN
 	 SELECT 	 @TimeStamp = dbo.fnServer_CmnGetDate(getUTCdate())
END
SELECT 	 @LineMask =  	  	 REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask =  	  	 REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask =  	  	 REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask =  	  	 REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @VarMask = 	  	  	 REPLACE(COALESCE(@VarMask, '*'), '*', '%')
SELECT 	 @VarMask = 	  	  	 REPLACE(REPLACE(@VarMask, '?', '_'), '[', '[[]')
SELECT 	 @ProdCodeMask = 	 REPLACE(COALESCE(@ProdCodeMask, '*'), '*', '%')
SELECT 	 @ProdCodeMask = 	 REPLACE(REPLACE(@ProdCodeMask, '?', '_'), '[', '[[]')
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
 	  	  	  	  	  	  	  	  	 END,
                        ESignatureLevel = Coalesce(vs.ESignature_Level,0)
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc = @LineMask
 	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc = @UnitMask
 	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	  	 pu.PU_Id = v.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Var_Desc LIKE @VarMask 
 	 JOIN 	  	  	 Var_Specs vs 	  	  	 ON 	  	 v.var_id = vs.var_id
 	 JOIN 	  	  	 PU_Products pup 	  	 ON 	  	 pu.PU_Id = pup.PU_Id 
 	 JOIN 	  	  	 Products p 	  	  	  	 ON 	  	 pup.Prod_Id = p.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 LEFT JOIN 	 User_Security vars 	 ON 	  	 pu.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE 	 p.Prod_Code LIKE @ProdCodeMask
 	 AND 	 vs.Effective_Date <= @TimeStamp
 	 AND 	 ((vs.Expiration_Date > @TimeStamp) OR (vs.Expiration_Date IS NULL))
 	 AND 	 COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2
 	 ORDER BY 	 v.Var_Desc, p.Prod_Code, vs.Effective_Date
