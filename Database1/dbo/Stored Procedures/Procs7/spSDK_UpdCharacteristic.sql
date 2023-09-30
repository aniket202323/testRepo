CREATE PROCEDURE dbo.spSDK_UpdCharacteristic
 	 -- Input Parameters
 	 @TransType 	  	  	  	 INT,
 	 @PropDesc 	  	  	  	 nvarchar(50),
 	 @CharDesc 	  	  	  	 nvarchar(50),
 	 @ParentChar 	  	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @CharId 	  	  	  	  	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: Char_Id Not Specified on Update/Delete
-- 	  	  2: Property Not Found
-- 	  	  3: Char_Desc Cannot Be Blank
-- 	  	  4: Char_Desc Already Exists
-- 	  	 11: Characteristic Create Failed
-- 	 to 	 19: 
-- 	  	 21: Characteristic Update Failed
-- 	 to 	 29: 
-- 	  	 31: Characteristic Delete Failed
-- to 39:
DECLARE 	 @PropId 	  	  	 INT,
 	  	  	 @ParentCharId 	 INT,
 	  	  	 @RC 	  	  	  	 INT,
 	  	  	 @Count 	  	  	 INT
-- Check to Make Sure Char_Id was passed on Update Or Delete
IF 	 (@CharId IS NULL OR @CharId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
-- Check For Valid Product Family
SELECT 	 @PropId = NULL
SELECT 	 @PropId = Prop_Id
 	 FROM 	 Product_Properties
 	 WHERE 	 Prop_Desc = @PropDesc
-- Endure its a valid Property
IF @PropId IS NULL AND @TransType IN (1,2)
BEGIN
 	 RETURN(2)
END
-- Char_Desc Cannot Be Blank
IF LEN(@CharDesc) = 0
BEGIN
 	 RETURN(3)
END
-- Check for Valid Char_Desc
SELECT 	 @Count = COUNT(*)
 	 FROM 	 Characteristics
 	 WHERE 	 Prop_Id = @PropId AND
 	  	  	 Char_Desc = @CharDesc AND
 	  	  	 Char_Id <> @CharId
IF @Count > 0 AND @TransType IN (1,2)
BEGIN
 	 RETURN(4)
END
IF 	 LEN(@ParentChar) = 0
BEGIN
 	 SELECT 	 @ParentCharId = NULL
END ELSE
BEGIN
 	 SELECT 	 @ParentCharId = NULL
 	 SELECT 	 @ParentCharId = Char_Id
 	  	 FROM 	 Characteristics
 	  	 WHERE 	 Char_Desc = @ParentChar
END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spEM_CreateChar
 	  	  	  	  	  	  	 @CharDesc,
 	  	  	  	  	  	  	 @PropId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @CharId OUTPUT
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+10)
 	 END
END ELSE
IF @TransType = 2
BEGIN
 	 EXECUTE 	 @RC = spEM_RenameChar
 	  	  	  	  	  	  	 @CharId,
 	  	  	  	  	  	  	 @CharDesc,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spEM_DropChar
 	  	  	  	  	  	  	 @CharId,
 	  	  	  	  	  	  	 @UserId
 	 IF @RC > 0
 	 BEGIN
 	  	 RETURN(@RC+30)
 	 END
END
RETURN(0)
