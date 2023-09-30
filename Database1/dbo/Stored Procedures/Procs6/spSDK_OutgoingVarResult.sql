CREATE PROCEDURE dbo.spSDK_OutgoingVarResult
 	 @VarId 	  	  	  	  	 INT,
 	 @EventId 	  	  	  	  	 INT,
 	 @ResultOn 	  	  	  	 DATETIME,
 	 @ArrayId 	  	  	  	  	 INT,
 	 @LineName 	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @UnitName 	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @VariableName 	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @EventName 	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @TestName 	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @ProcessOrder 	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @ProductCode 	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @LEL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @LRL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @LWL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @LUL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @TGT 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @UUL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @UWL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @URL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 @UEL 	  	  	  	  	  	 nvarchar(50)  	  	  	  	 OUTPUT,
 	 -- 4.0 Additions
 	 @DepartmentName 	  	 nvarchar(50) 	 = NULL 	 OUTPUT
AS
-- Return Values
-- 0 - Success
DECLARE 	 @ETId 	  	  	  	 INT,
 	  	  	 @PUId 	  	  	  	 INT,
 	  	  	 @MasterUnit 	  	 INT,
 	  	  	 @ProdId 	  	  	 INT,
 	  	  	 @PPId 	  	  	  	 INT,
 	  	  	 @AppliedProd 	 INT
--Lookup Variable
SELECT 	 @DepartmentName = NULL,
 	  	  	 @LineName = NULL,
 	  	  	 @UnitName = NULL,
 	  	  	 @VariableName = NULL
SELECT 	 @VariableName = v.Var_Desc, 
 	  	  	 @TestName = v.Test_Name,
 	  	  	 @DepartmentName = d.Dept_Desc,
 	  	  	 @LineName = pl.PL_Desc,
 	  	  	 @UnitName = pu.PU_Desc,
 	  	  	 @ETId = v.Event_Type,
 	  	  	 @PUId = v.PU_Id
 	 FROM 	 Variables v
 	 JOIN 	 Prod_Units pu 	 ON 	 v.PU_Id = pu.PU_Id
 	 JOIN 	 Prod_Lines pl 	 ON 	 pu.PL_Id = pl.PL_Id
 	 JOIN 	 Departments d 	 ON 	 pl.Dept_Id = d.Dept_Id
 	 WHERE 	 Var_Id = @VarId
SELECT 	 @MasterUnit = COALESCE(Master_Unit, PU_Id)
 	 FROM 	 Prod_Units
 	 WHERE 	 PU_Id = @PUId
SELECT 	 @ProdId = NULL
SELECT 	 @ProdId = Prod_Id
 	 FROM 	 Production_Starts
 	 WHERE 	 PU_Id = @MasterUnit AND
 	  	  	 Start_Time <= @ResultOn AND
 	  	  	 (End_Time > @ResultOn OR End_Time IS NULL)
SELECT 	 @ProductCode = Prod_Code
 	 FROM 	 Products
 	 WHERE 	 Prod_Id = @ProdId
SELECT 	 @PPId = NULL
SELECT 	 @PPId = PP_Id
 	 FROM 	 Production_Plan_Starts
 	 WHERE 	 Start_Time <= @ResultOn
 	 AND 	 (End_Time >= @ResultOn OR End_Time IS NULL)
 	 AND 	 PU_Id = @MasterUnit
SELECT 	 @ProcessOrder = Process_Order
 	 FROM 	 Production_Plan
 	 WHERE 	 PP_Id = @PPId
SELECT 	 @LEL = L_Entry,
 	  	  	 @LRL = L_Reject,
 	  	  	 @LWL = L_Warning,
 	  	  	 @LUL = L_User,
 	  	  	 @TGT = Target,
 	  	  	 @UUL = U_User,
 	  	  	 @UWL = U_Warning,
 	  	  	 @URL = U_Reject,
 	  	  	 @UEL = U_Entry
 	 FROM 	 Var_Specs
 	 WHERE 	 Var_Id = @VarId
-- Get Event Name
IF @ETId = 1
BEGIN
 	 SELECT 	 @Eventname = NULL,
 	  	  	  	 @AppliedProd = NULL
 	 SELECT 	 @EventName = Event_Num,
 	  	  	  	 @AppliedProd = Applied_Product
 	  	 FROM 	 Events 
      WHERE PU_Id = @MasterUnit 
 	  	 AND 	 TimeStamp = @ResultOn
 	 IF @AppliedProd IS NOT NULL
 	 BEGIN
 	  	 SELECT 	 @ProductCode = Prod_Code
 	  	  	 FROM 	 Products
 	  	  	 WHERE 	 Prod_Id = @AppliedProd
 	 END
END
RETURN(0)
