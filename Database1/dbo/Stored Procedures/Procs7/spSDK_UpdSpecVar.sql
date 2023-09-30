CREATE PROCEDURE dbo.spSDK_UpdSpecVar
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @PropDesc 	  	  	  	 nvarchar(50),
 	 @SpecDesc 	  	  	  	 nvarchar(50),
 	 @DataType 	  	  	  	 nvarchar(50),
 	 @SpecPrecision 	  	  	 INT,
 	 @EngUnits 	  	  	  	 nvarchar(50),
 	 @TagInfo 	  	  	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @SpecId 	  	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: Spec_Id Not Specified on Update/Delete
-- 	  	  2: Property Not Found
-- 	  	  3: Spec_Desc Cannot Be Blank
-- 	  	  4: Spec_Desc Already Exists
-- 	  	  5: Data Type Not Found
-- 	  	 11: Spec Create Failed
-- 	 to 	 19: 
-- 	  	 21: Spec Update Failed
-- 	 to 	 29: 
-- 	  	 31: Spec Delete Failed
-- to 39:
DECLARE 	 @PropId 	  	  	  	  	 INT,
 	  	  	 @DataTypeId 	  	  	  	 INT,
 	  	  	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT,
 	  	  	 @SpecOrder 	  	  	  	 INT
-- Check to Make Sure Prod_Id was passed on Update Or Delete
IF 	 (@SpecId IS NULL OR @SpecId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Product Family
SELECT 	 @PropId = NULL
SELECT 	 @PropId = Prop_Id
 	 FROM 	 Product_Properties
 	 WHERE 	 Prop_Desc = @PropDesc
-- If this is an Add or Update and Property
-- not found error out.
IF @PropId IS NULL AND @TransType IN (1,2)
BEGIN
 	 RETURN(2)
END
-- SpecDesc Cannot Be Blank
IF LEN(@SpecDesc) = 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(3)
END
-- Check for Valid SpecDesc
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Specifications
 	 WHERE 	 Prop_Id = @PropId AND
 	  	  	 Spec_Desc = @SpecDesc AND
 	  	  	 Spec_Id <> @SpecId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(4)
END
SELECT 	 @DataTypeId = NULL
SELECT 	 @DataTypeId = Data_Type_Id
 	 FROM 	 Data_Type
 	 WHERE 	 Data_Type_Desc = @DataType
IF @DataTypeId IS NULL
BEGIN
 	 RETURN(5)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEM_CreateSpec
 	  	  	  	  	  	  	 @SpecDesc,
 	  	  	  	  	  	  	 @PropId,
 	  	  	  	  	  	  	 @DataTypeId,
 	  	  	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @SpecId 	  	 OUTPUT,
 	  	  	  	  	  	  	 @SpecOrder 	 OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
 	 EXECUTE 	 @RC = spEM_PutSpecData
 	  	  	  	  	  	  	 @SpecId,
 	  	  	  	  	  	  	 @DataTypeId,
 	  	  	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	  	  	 @TagInfo,
 	  	  	  	  	  	  	 @EngUnits,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+14)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameSpec
 	  	  	  	  	  	  	 @SpecId,
 	  	  	  	  	  	  	 @SpecDesc,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
 	 EXECUTE 	 @RC = spEM_PutSpecData
 	  	  	  	  	  	  	 @SpecId,
 	  	  	  	  	  	  	 @DataTypeId,
 	  	  	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	  	  	 @TagInfo,
 	  	  	  	  	  	  	 @EngUnits,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+24)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEM_DropSpec
 	  	  	  	  	  	  	 @SpecId,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
