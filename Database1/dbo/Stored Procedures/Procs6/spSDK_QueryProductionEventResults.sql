CREATE PROCEDURE dbo.spSDK_QueryProductionEventResults
 	 @LineName 	  	 nvarchar(50),
 	 @UnitName 	  	 nvarchar(50),
 	 @EventName 	  	 nvarchar(50),
 	 @VariableMask 	 nvarchar(100) 	 = NULL,
 	 @UserId 	  	  	 INT 	  	  	  	 = NULL
AS
SELECT 	 @VariableMask = REPLACE(COALESCE(@VariableMask, '*'), '*', '%')
SELECT 	 @VariableMask = REPLACE(REPLACE(@VariableMask, '?', '_'), '[', '[[]')
SELECT 	 VariableResultId = t.Test_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = COALESCE(spu.PU_Desc, pu.PU_Desc), 
 	  	  	 VariableName = v.Var_Desc, 
 	  	  	 TestName = v.Test_name, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 TimeStamp = e.Timestamp,
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ProcessOrder = pp.Process_Order,
 	  	  	 Value = t.Result,
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
 	 FROM 	  	  	 Departments d
 	 JOIN 	  	  	 Prod_Lines pl 	  	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc = @LineName
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0
 	 JOIN 	  	  	 Prod_Units pu 	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc = @UnitName
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	 LEFT JOIN 	 Prod_Units spu 	  	  	  	  	 ON  	 pu.PU_Id = spu.Master_Unit
 	 JOIN 	  	  	 Events e 	  	  	  	  	  	  	 ON  	 pu.PU_Id = e.PU_Id 
 	 JOIN 	  	  	 Variables v 	  	  	  	  	  	 ON 	  	 v.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Event_Type = 1
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Var_Desc LIKE @VariableMask
 	 JOIN 	  	  	 Tests t 	  	  	  	  	  	  	 ON 	  	 v.Var_Id = t.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.Timestamp = t.Result_On 
 	 JOIN 	  	  	 Production_Starts ps 	  	  	 ON 	  	 pu.PU_Id = ps.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.Timestamp >= ps.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (e.Timestamp < ps.End_Time OR ps.End_Time IS NULL)
 	 LEFT JOIN 	 Products p 	  	  	  	  	  	 ON 	  	 ps.Prod_Id = p.Prod_Id
 	 LEFT JOIN 	 Var_Specs vs 	  	  	  	  	 ON 	  	 vs.Var_id = v.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_id = p.Prod_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Effective_date <= e.Timestamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (vs.Expiration_date > e.Timestamp OR vs.Expiration_Date IS NULL)
 	 LEFT JOIN 	 Production_Plan_Starts pps 	 ON 	  	 e.PU_Id = pps.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.Timestamp >= pps.Start_Time 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (e.Timestamp < pps.End_Time OR pps.End_Time IS NULL) 
 	 LEFT JOIN 	 Production_Plan pp 	  	  	 ON pps.PP_Id = pp.PP_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	  	 ON 	  	 pl.Group_Id = pl.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	 LEFT JOIN 	 User_Security vars 	  	  	 ON  	 v.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE 	 e.Event_Num = @EventName
 	 AND 	 COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2
 	 ORDER BY pu.PU_Order, v.PUG_Order
