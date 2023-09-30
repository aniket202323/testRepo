CREATE PROCEDURE dbo.spSDK_OutgoingProductionPlanStart
@PPStartId 	  	 int,
@PUId 	  	  	 int,
@PPId 	  	  	 int,
@PPSetupId 	  	 int,
@PathCode 	  	  	 nvarchar(50) OUTPUT,
@ProcessOrder 	  	 nvarchar(50) OUTPUT,
@DeptDesc 	  	  	 nvarchar(50) OUTPUT,
@PLDesc 	  	  	 nvarchar(50) OUTPUT,
@PUDesc 	  	  	 nvarchar(50) OUTPUT,
@PatternCode 	  	 nvarchar(50) OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Process Order Not Found
-- 2 - Path Not Found
-- 3 - PUDesc Not Found
DECLARE 	 @PLId 	 int,
 	  	 @DeptId 	 int,
 	  	 @PathId 	 int
--Lookup Process Order
SELECT 	 @ProcessOrder 	 = NULL
SELECT 	 @ProcessOrder 	 = Process_Order,
 	  	 @PathId 	  	 = Path_Id
FROM 	 Production_Plan 
WHERE 	 PP_Id = @PPId
IF @ProcessOrder IS NULL RETURN(1)
--Lookup Path
SELECT 	 @PathCode 	  	 = NULL
SELECT 	 @PathCode 	  	 = Path_Code
FROM 	 PrdExec_Paths
WHERE 	 Path_Id = @PathId
IF @PathCode IS NULL RETURN(2)
--Look Up Unit
SELECT 	 @PUDesc 	 = NULL
SELECT 	 @PUDesc 	 = PU_Desc,
 	  	 @PLId 	 = PL_Id
FROM 	 Prod_Units
WHERE 	 PU_Id = @PUId
IF @PUDesc IS NULL RETURN(3)
--Look Up Line
SELECT 	 @PLDesc 	 = NULL
SELECT 	 @PLDesc 	 = PL_Desc,
 	  	 @DeptId 	 = Dept_Id
FROM 	 Prod_Lines
WHERE 	 PL_Id = @PLId
--Look Up Department
SELECT 	 @DeptDesc 	 = NULL
SELECT 	 @DeptDesc 	 = Dept_Desc 
FROM 	 Departments
WHERE 	 Dept_Id = @DeptId
--Look Up Pattern
SELECT 	 @PatternCode = Pattern_Code
FROM 	 Production_Setup
WHERE 	 PP_Setup_Id = @PPSetupId
RETURN(0)
