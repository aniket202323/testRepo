CREATE Procedure dbo.spSDK_GetVarResultById
 	 @TestId 	  	  	 BigInt
AS
SELECT 	 VariableResultId = t.Test_Id,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 VariableName = v.Var_Desc, 
 	  	  	 TestName = v.Test_name, 
 	  	  	 TimeStamp = t.Result_On,
 	  	  	 Value = t.Result, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 ProcessOrder = pp.Process_Order,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 URL = vs.U_Reject, 
 	  	  	 UWL = vs.U_Warning, 
 	  	  	 UUL = vs.U_User, 
 	  	  	 TGT = vs.Target, 
 	  	  	 LUL = vs.L_User, 
 	  	  	 LWL = vs.L_Warning, 
 	  	  	 LRL = vs.L_Reject,
 	  	  	 LEL = vs.L_Entry, 
 	  	  	 UEL = vs.U_Entry,
 	  	  	 CommentId = t.Comment_Id,
                        SignatureId = t.Signature_Id
    FROM Tests t 	  	  	  	  	  	  	 JOIN
 	  	  	 Variables v 	  	  	  	  	  	 ON v.Var_Id = t.Var_Id LEFT JOIN 
 	  	  	 Events e 	  	  	  	  	  	  	 ON e.PU_Id = v.PU_Id AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 e.Timestamp = t.Result_ON JOIN 
 	  	  	 Prod_Units pu 	  	  	  	  	 ON v.PU_Id = pu.PU_Id JOIN
 	  	  	 Prod_Lines pl 	  	  	  	  	 ON pu.PL_Id = pl.PL_Id JOIN
 	  	  	 Production_Starts ps 	  	  	 ON ps.pu_id = v.PU_Id AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 ps.Start_Time <= t.Result_On AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 ((ps.End_Time > t.Result_On) OR (ps.End_Time IS NULL)) JOIN 
 	  	  	 Products p 	  	  	  	  	  	 ON 	 p.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END LEFT JOIN 
 	  	  	 Var_Specs vs  	  	  	  	  	 ON 	 vs.Var_id = t.Var_Id AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 vs.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 vs.Effective_date <= t.Result_On AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 ((vs.Expiration_date > t.Result_On) OR (vs.Expiration_date IS NULL)) LEFT JOIN 
 	  	  	 Production_Plan_Starts po 	 ON po.PU_Id = v.PU_Id AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 po.Start_Time <= t.Result_On AND 
 	  	  	  	  	  	  	  	  	  	  	  	  	 ((po.End_Time > t.Result_On) OR (po.End_Time IS NULL)) LEFT JOIN
 	  	  	 Production_Plan pp 	  	  	 ON po.PP_Id = pp.PP_Id
 	 WHERE 	 t.Test_Id = @TestId
