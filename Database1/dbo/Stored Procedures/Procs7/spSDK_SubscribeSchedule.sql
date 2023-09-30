CREATE PROCEDURE dbo.spSDK_SubscribeSchedule
 	 @PathCode 	 nvarchar(50),
 	 @UserId 	  	 INT,
 	 @PathId 	  	 INT OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Path Code Not Found
-- 3 - Access Denied
DECLARE 	 @PUId     INT,
   	  	  	 @GroupId 	  	  	 INT,
 	    	  	 @AccessLevel 	 INT
--Lookup Path Code
SELECT 	 @PathId = NULL
SELECT 	 @PathId = Path_Id 
 	 FROM 	 PrdExec_Paths
 	 WHERE Path_Code = @PathCode
IF @PathId IS NULL RETURN(2)
--Lookup Unit
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id
 	 FROM 	 PrdExec_Path_Units 
 	 WHERE Path_Id = @PathId AND 
 	  	  	   Is_Schedule_Point = 1
-- Removed by AJ - 01-Dec-2004. A Path can not have Production Units associated with it.
--IF @PUId IS NULL RETURN(3)
--Lookup Group
SELECT 	 @GroupId = Group_Id 
 	 FROM 	 Prod_Units 
 	 WHERE PU_Id = @PUId
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
