CREATE PROCEDURE dbo.spSDK_SubscribeVariable
 	 @LineName 	  	 nvarchar(100),
 	 @UnitName 	  	 nvarchar(100),
 	 @VariableName 	 nvarchar(100),
 	 @UserId 	  	  	 INT,
 	 @VarId 	  	  	 INT OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Line Not Found
-- 3 - Unit Not Found
-- 4 - Variable Not Found
-- 5 - Access Denied
DECLARE 	 @PUId 	  	  	  	 INT,
 	  	  	 @PLId 	  	  	  	 INT,
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @AccessLevel 	 INT
--Lookup Line
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(2)
--Lookup Unit
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE PU_Desc = @UnitName AND 
 	  	  	 PL_id = @PLId
IF @PUId IS NULL RETURN(3)
--Lookup Variable
SELECT 	 @VarId = NULL
SELECT 	 @VarId = Var_Id, 
 	  	  	 @GroupId = Group_Id 
 	 FROM 	 Variables 
 	 WHERE Var_Desc = @VariableName AND 
 	  	  	 PU_Id = @PUId 
IF @VarId IS NULL RETURN(4)
--If There Is No Security Group Attached, Bail With Success
IF @GroupId IS NULL RETURN(0)
--Check Security Group
SELECT 	 @AccessLevel = NULL
SELECT 	 @AccessLevel = MAX(Access_Level) 
 	 FROM 	 User_Security 
 	 WHERE 	 User_id = @UserId AND 
 	  	  	 Group_id = @GroupId
IF @AccessLevel IS NULL RETURN(5)
IF @AccessLevel < 1 RETURN(5)
RETURN(0)
