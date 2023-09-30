CREATE PROCEDURE dbo.spSDK_SubscribeEvents
 	 @LineName 	 nvarchar(100),
 	 @UnitName 	 nvarchar(100),
 	 @UserId 	  	 INT,
 	 @PUId 	  	  	 INT OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Line Not Found
-- 3 - Unit Not Found
-- 4 - Access Denied
DECLARE 	 @PLId 	  	  	 INT,
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @AccessLevel 	 INT
--Lookup Line
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
 	 FROM 	 Prod_Lines 
 	 WHERE PL_Desc = @LineName
IF @PLId IS NULL RETURN(2)
--Lookup Unit
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id, 
 	  	  	 @GroupId = Group_Id 
 	 FROM 	 Prod_Units 
 	 WHERE PU_Desc = @UnitName AND 
 	  	  	 PL_Id = @PLId
IF @PUId IS NULL RETURN(3)
--If There Is No Security Group Attached, Bail With Success
IF @GroupId IS NULL RETURN(0)
--Check Security Group
SELECT 	 @AccessLevel = NULL
SELECT 	 @AccessLevel = MAX(Access_Level) 
 	 FROM 	 User_Security 
 	 WHERE User_id = @UserId AND 
 	  	  	 Group_id = @GroupId
IF @AccessLevel IS NULL RETURN(4)
IF @AccessLevel < 1 RETURN(4)
RETURN(0)
