CREATE Procedure dbo.spSDK_QueryVariableResults
 	 @LineMask 	  	 nvarchar(50) 	  	 = NULL,
 	 @UnitMask 	  	 nvarchar(50) 	  	 = NULL,
 	 @VarMask 	  	  	 nvarchar(100) 	 = NULL,
 	 @StartTime 	  	 DATETIME  	  	 = NULL,
 	 @EndTime  	  	 DATETIME 	  	  	 = NULL,
    @ExcludeCanceled bit = 0,
 	 @UserId 	  	  	 INT 	  	  	  	 = NULL
AS
SELECT 	 @LineMask = 	 REPLACE(COALESCE(@LineMask, '*'), '*', '%')
SELECT 	 @LineMask = 	 REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
SELECT 	 @UnitMask = 	 REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
SELECT 	 @UnitMask = 	 REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
SELECT 	 @VarMask = 	 REPLACE(COALESCE(@VarMask, '*'), '*', '%')
SELECT 	 @VarMask = 	 REPLACE(REPLACE(@VarMask, '?', '_'), '[', '[[]')
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
 	 SELECT @StartTime = DATEADD(DAY, -1, @EndTime)
END
CREATE TABLE #ProductChanges (
  PU_Id int,
  Prod_Id int,
  Start_Time DATETIME,
  End_Time DATETIME null
)
CREATE INDEX ProdChange ON #ProductChanges (PU_Id, Start_Time)
CREATE TABLE #ProcessOrders (
  PU_Id 	  	  	 INT,
  ProcessOrder 	 nvarchar(50),
  Start_Time 	 DATETIME,
  End_Time 	  	 DATETIME null
)
CREATE INDEX ProcOrder ON #ProcessOrders (PU_Id, Start_Time)
-- Get Product Changes Between Time Range
INSERT INTO 	 #ProductChanges (PU_Id, Prod_id, Start_Time, End_Time)
 	 SELECT 	 pu.PU_Id, ps.Prod_id, ps.Start_Time, ps.End_Time
 	  	 FROM 	 Prod_Lines pl 	  	  	  	  	 
 	  	 JOIN 	 Prod_Units pu 	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	  	 JOIN 	 Production_Starts ps 	  	  	 ON pu.PU_Id = ps.PU_Id
 	  	 WHERE 	 ps.Start_Time <= @EndTime
 	  	 AND 	 (End_Time >= @StartTime OR End_Time IS NULL)
-- Get Process Orders Between Time Range
INSERT INTO #ProcessOrders (PU_Id, ProcessOrder, Start_Time, End_Time)
 	 SELECT 	 pu.PU_Id, pp.Process_Order, pps.Start_Time, pps.End_Time
 	  	 FROM 	  	 Prod_Lines pl
 	  	 JOIN 	 Prod_Units pu 	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
    JOIN  PrdExec_Path_Units pepu ON    pepu.PU_Id = pu.PU_Id
 	  	 JOIN 	 Production_Plan pp 	  	  	 ON 	  	 pp.Path_Id = pepu.Path_Id
 	  	 JOIN 	 Production_Plan_Starts pps 	 ON 	  	 pps.PP_Id = pp.PP_Id AND pps.pu_id = pu.pu_id
 	  	 WHERE 	 pps.Start_Time <= @EndTime
 	  	 AND 	 (pps.End_Time >= @StartTime OR pps.End_Time IS NULL)
if @ExcludeCanceled = 0
BEGIN
 	 SELECT 	 VariableResultId = t.Test_Id,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 VariableName = v.Var_Desc, 
 	  	  	 TestName = v.Test_name, 
 	  	  	 TimeStamp = t.Result_On,
 	  	  	 Value = t.Result, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 ProcessOrder = po.ProcessOrder,
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
 	 FROM 	  	  	  	 Departments d
 	  	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0
 	  	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	  	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	  	 pu.PU_Id = v.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Var_Desc LIKE @VarMask
 	  	 JOIN 	  	  	 Tests t 	  	  	  	  	 ON 	  	 v.Var_Id = t.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.Result_On >= @StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.Result_On <= @EndTime
 	  	 LEFT JOIN 	 #ProductChanges ps 	 ON 	  	 ps.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ps.Start_Time <= t.Result_On
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (ps.End_Time > t.Result_On OR ps.End_Time IS NULL)
 	  	 LEFT JOIN 	 #ProcessOrders po 	  	 ON 	  	 po.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND  	 po.Start_Time <= t.Result_On 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (po.End_Time > t.Result_On OR po.End_Time IS NULL)
 	  	 LEFT JOIN 	 Events e 	  	  	  	  	 ON 	  	 e.PU_Id = v.PU_Id 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.TimeStamp = t.Result_On
 	  	 LEFT JOIN 	 Var_Specs vs 	  	  	 ON 	  	 vs.Var_id = t.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Effective_Date <= t.Result_On 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (vs.Expiration_date > t.Result_On OR vs.Expiration_date IS NULL)
 	  	 LEFT JOIN 	 Products p 	  	  	  	 ON 	  	 p.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	  	 LEFT JOIN 	 User_Security vars 	 ON  	 v.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2
END ELSE
BEGIN
 	 SELECT 	 VariableResultId = t.Test_Id,
 	  	  	 LineName = pl.PL_Desc,
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 VariableName = v.Var_Desc, 
 	  	  	 TestName = v.Test_name, 
 	  	  	 TimeStamp = t.Result_On,
 	  	  	 Value = t.Result, 
 	  	  	 EventName = e.Event_Num, 
 	  	  	 ProcessOrder = po.ProcessOrder,
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
 	 FROM 	  	  	  	 Departments d
 	  	 JOIN 	  	  	 Prod_Lines pl 	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Desc LIKE @LineMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pl.PL_Id > 0
 	  	 JOIN 	  	  	 Prod_Units pu 	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Desc LIKE @UnitMask
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pu.PU_Id > 0
 	  	 JOIN 	  	  	 Variables v 	  	  	  	 ON 	  	 pu.PU_Id = v.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 v.Var_Desc LIKE @VarMask
 	  	 JOIN 	  	  	 Tests t 	  	  	  	  	 ON 	  	 v.Var_Id = t.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.Result_On >= @StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 t.Result_On <= @EndTime
 	  	 LEFT JOIN 	 #ProductChanges ps 	 ON 	  	 ps.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ps.Start_Time <= t.Result_On
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (ps.End_Time > t.Result_On OR ps.End_Time IS NULL)
 	  	 LEFT JOIN 	 #ProcessOrders po 	  	 ON 	  	 po.PU_Id = pu.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND  	 po.Start_Time <= t.Result_On 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (po.End_Time > t.Result_On OR po.End_Time IS NULL)
 	  	 LEFT JOIN 	 Events e 	  	  	  	  	 ON 	  	 e.PU_Id = v.PU_Id 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 e.TimeStamp = t.Result_On
 	  	 LEFT JOIN 	 Var_Specs vs 	  	  	 ON 	  	 vs.Var_id = t.Var_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vs.Effective_Date <= t.Result_On 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (vs.Expiration_date > t.Result_On OR vs.Expiration_date IS NULL)
 	  	 LEFT JOIN 	 Products p 	  	  	  	 ON 	  	 p.Prod_id = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHEN e.Applied_Product IS NULL THEN ps.Prod_id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Applied_product 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	 LEFT JOIN 	 User_Security pls 	  	 ON 	  	 pl.Group_Id = pls.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	  	 LEFT JOIN 	 User_Security pus 	  	 ON 	  	 pu.Group_Id = pus.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId 	 
 	  	 LEFT JOIN 	 User_Security vars 	 ON  	 v.Group_Id = vars.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 vars.User_Id = @UserId 	 
 	 WHERE COALESCE(vars.Access_Level, COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3))) >= 2 AND t.Canceled = 0
END
DROP TABLE #ProductChanges
DROP TABLE #ProcessOrders
