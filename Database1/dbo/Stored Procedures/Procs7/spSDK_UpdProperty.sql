CREATE PROCEDURE dbo.spSDK_UpdProperty
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @PropDesc 	  	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @PropId 	  	  	  	  	 INT OUTPUT
AS
-- Return Codes
-- 	  	  1: Prop_Id Not Specified on Update/Delete
-- 	  	  2: Property Description Cannot Be Blank.
-- 	  	  3: Property Already Exists
-- 	  	 11: Property Create Failed
-- 	 to 	 19: 
-- 	  	 21: Property Update Failed
-- 	 to 	 29: 
-- 	  	 31: Property Delete Failed
-- to 39:
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @Count 	  	  	  	  	 INT
-- Check to Make Sure Prop_Id was passed on Update Or Delete
IF 	 (@PropId IS NULL) OR (@PropId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Prop_Desc Cannot Be Blank
IF LEN(@PropDesc) = 0
BEGIN
 	 RETURN(2)
END
-- Check for Valid Prop_Desc
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Product_Properties
 	 WHERE 	 Prop_Desc = @PropDesc AND
 	  	  	 Prop_Id <> @PropId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(3)
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEM_CreateProp
 	  	  	  	  	  	  	 @PropDesc,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @PropId OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameProp
 	  	  	  	  	  	  	 @PropId,
 	  	  	  	  	  	  	 @PropDesc,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEM_DropProp
 	  	  	  	  	  	  	 @PropId,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
