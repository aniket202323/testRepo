CREATE PROCEDURE dbo.spSDK_GetVariableSpecificationById
 	 @VariableSpecificationId 	  	  	  	 INT
AS
SELECT 	 DISTINCT SpecificationId = vs.VS_Id,
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
 	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	  	 pu.PU_Id = v.PU_Id
 	 JOIN 	  	  	 Var_Specs vs 	  	  	 ON 	  	 v.var_id = vs.var_id
 	 JOIN 	  	  	 PU_Products pup 	  	  	 ON 	  	 pu.PU_Id = pup.PU_Id 
 	 JOIN 	  	  	 Products p 	  	  	  	 ON 	  	 pup.Prod_Id = p.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_Id = p.Prod_Id
 	 WHERE 	 vs.VS_Id = @VariableSpecificationId
