CREATE PROCEDURE dbo.spSDK_OutgoingProductionSetup
 	 @PathId 	  	  	  	  	  	   INT,
 	 @PPId 	  	  	  	  	  	  	   INT,
 	 @PPSetupId 	  	  	  	   INT,
 	 @PPStatusId 	  	  	  	  	 INT,
  @ParentPPSetupId    INT,
 	 @PathCode 	  	  	  	  	   nvarchar(50) OUTPUT,
 	 @ProcessOrder 	  	  	  	 nvarchar(50) OUTPUT,
 	 @PatternCode 	  	  	  	 nvarchar(50) OUTPUT,
 	 @PPStatusDesc 	  	  	  	 nvarchar(50) OUTPUT,
 	 @ParentPatternCode 	 nvarchar(50) OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Path Not Found
-- 2 - Process Order Not Found
-- 3 - Sequence Not Found
-- 4 - Sequence Status Not Found
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
--Lookup Sequence
SELECT 	 @PatternCode = NULL
SELECT 	 @PatternCode = Pattern_Code
 	 FROM 	 Production_Setup
 	 WHERE 	 PP_Setup_Id = @PPSetupId
IF @PatternCode IS NULL RETURN(3)
--Lookup Production Plan Status
SELECT 	 @PPStatusDesc = NULL
SELECT 	 @PPStatusDesc = PP_Status_Desc 
 	 FROM 	 Production_Plan_Statuses
 	 WHERE 	 PP_Status_Id = @PPStatusId
IF @PPStatusDesc IS NULL RETURN(4)
--Look Up Parent Sequence
SELECT 	 @ParentPatternCode = NULL
SELECT 	 @ParentPatternCode = Pattern_Code
 	 FROM 	 Production_Setup
 	 WHERE 	 PP_Setup_Id = @PPSetupId
RETURN(0)
