CREATE PROCEDURE dbo.spSDK_OutgoingProductionPlan
 	 @PathId 	  	  	  	  	  	   INT,
 	 @PPId 	  	  	  	  	  	  	   INT,
 	 @ProdId 	  	  	  	  	  	   INT,
 	 @PPStatusId 	  	  	  	  	 INT,
  @PPTypeId           INT,
  @SourcePPId         INT,
  @ParentPPId         INT,
  @ControlTypeId      TINYINT,
 	 @PathCode 	  	  	  	  	   nvarchar(50) OUTPUT,
 	 @ProcessOrder 	  	  	  	 nvarchar(50) OUTPUT,
 	 @ProductCode 	  	  	  	 nvarchar(50) OUTPUT,
 	 @PPStatusDesc 	  	  	  	 nvarchar(50) OUTPUT,
  @PPTypeName         nvarchar(25) OUTPUT,
 	 @SourceProcessOrder nvarchar(50) OUTPUT,
 	 @ParentProcessOrder 	 nvarchar(50) OUTPUT,
  @ControlTypeDesc    nvarchar(25) OUTPUT,
  @DeptDesc           nvarchar(50) OUTPUT,
  @PLDesc             nvarchar(50) OUTPUT,
  @PUDesc             nvarchar(50) OUTPUT,
  @SourcePathCode     nvarchar(50) OUTPUT,
  @ParentPathCode     nvarchar(50) OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Path Not Found
-- 2 - Process Order Not Found
-- 3 - Product Not Found
-- 4 - Production Plan Status Not Found
-- 5 - Production Plan Type Not Found
Declare @PLId int,
        @DeptId int
--Lookup Path
SELECT 	 @PathCode = NULL
SELECT 	 @PathCode = Path_Code
 	 FROM 	 PrdExec_Paths
 	 WHERE 	 Path_Id = @PathId
IF @PathCode IS NULL RETURN(1)
--Lookup Process Order
SELECT 	 @ProcessOrder = NULL
SELECT 	 @ProcessOrder = Process_Order 
 	 FROM 	 Production_Plan 
 	 WHERE 	 PP_Id = @PPId
IF @ProcessOrder IS NULL RETURN(2)
--Lookup Product
SELECT 	 @ProductCode = NULL
SELECT 	 @ProductCode = Prod_Code
 	 FROM 	 Products
 	 WHERE 	 Prod_Id = @ProdId
IF @ProductCode IS NULL RETURN(3)
--Lookup Production Plan Status
SELECT 	 @PPStatusDesc = NULL
SELECT 	 @PPStatusDesc = PP_Status_Desc 
 	 FROM 	 Production_Plan_Statuses
 	 WHERE 	 PP_Status_Id = @PPStatusId
IF @PPStatusDesc IS NULL RETURN(4)
--Lookup Production Plan Type
SELECT 	 @PPTypeName = NULL
SELECT 	 @PPTypeName = PP_Type_Name 
 	 FROM 	 Production_Plan_Types
 	 WHERE 	 PP_Type_Id = @PPTypeId
IF @PPTypeName IS NULL RETURN(5)
--Look Up Source Process Order
SELECT 	 @SourceProcessOrder = NULL, @SourcePathCode = NULL
SELECT 	 @SourceProcessOrder = pp.Process_Order, @SourcePathCode = pep.Path_Code
 	 FROM 	 Production_Plan pp
  JOIN  PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
 	 WHERE 	 pp.PP_Id = @SourcePPId
--Look Up Parent Process Order
SELECT 	 @ParentProcessOrder = NULL, @ParentPathCode = NULL
SELECT 	 @ParentProcessOrder = pp.Process_Order, @ParentPathCode = pep.Path_Code
 	 FROM 	 Production_Plan pp
  JOIN  PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
 	 WHERE 	 pp.PP_Id = @ParentPPId
--Look Up Control Type
SELECT 	 @ControlTypeDesc = NULL
SELECT 	 @ControlTypeDesc = Control_Type_Desc 
 	 FROM 	 Control_Type
 	 WHERE 	 Control_Type_Id = @ControlTypeId
--Look Up Line
SELECT 	 @PLDesc = NULL
SELECT 	 @PLDesc = pl.PL_Desc, @PLId = pl.PL_Id, @DeptId = pl.Dept_Id
 	 FROM 	 Prod_Lines pl
  JOIN  PrdExec_Paths pep ON pep.PL_Id = pl.PL_Id
 	 WHERE 	 pep.Path_Id = @PathId
--Look Up Department
SELECT 	 @DeptDesc = NULL
SELECT 	 @DeptDesc = Dept_Desc 
 	 FROM 	 Departments
 	 WHERE 	 Dept_Id = @DeptId
--Look Up Control Type
SELECT 	 @PUDesc = NULL
SELECT 	 @PUDesc = PU_Desc 
 	 FROM 	 Prod_Units pu
  JOIN  PrdExec_Path_Units pepu ON pepu.PU_Id = pu.PU_Id and pepu.Is_Schedule_Point = 1
  JOIN  PrdExec_Paths pep ON pep.Path_Id = pepu.Path_Id
 	 WHERE 	 pep.Path_Id = @PathId
RETURN(0)
