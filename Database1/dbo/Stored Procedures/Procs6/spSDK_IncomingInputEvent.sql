Create Procedure dbo.spSDK_IncomingInputEvent
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @TransactionType 	  	 INT,
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @InputName 	  	  	  	 nvarchar(50),
 	 @Position 	  	  	  	 nvarchar(50),
 	 @SrcLineName 	  	  	 nvarchar(50),
 	 @SrcUnitName 	  	  	 nvarchar(50),
 	 @SrcEventName 	  	  	 nvarchar(50),
 	 @Timestamp 	  	  	  	 DATETIME,
 	 @DimensionX 	  	  	  	 FLOAT,
 	 @DimensionY 	  	  	  	 FLOAT,
 	 @DimensionZ 	  	  	  	 FLOAT,
 	 @DimensionA 	  	  	  	 FLOAT,
 	 @UserId 	  	  	  	  	 INT,
        -- Input/Output Parameters
        @ESignatureId                           INT OUTPUT,
 	 -- Output Parameters
 	 @PEIId 	  	  	  	  	 INT OUTPUT,
 	 @PEIPId 	  	  	  	  	 INT OUTPUT,
 	 @EventId 	  	  	  	  	 INT OUTPUT,
 	 @Unloaded 	  	  	  	 INT OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 = Line Specified Not Found
-- 2 = Unit Specified Not Found
-- 3 = Input Specified Not Found
-- 4 = Position Specified Not Found
-- 5 = Source Event Line Specified Not Found
-- 6 = Source Event Unit Specified Not Found
-- 7 = Source EventName Specified Not Found
DECLARE 	 @PLId 	  	  	  	 INT,
 	  	  	 @PUId 	  	  	  	 INT,
 	  	  	 @SrcPLId 	  	  	 INT,
 	  	  	 @SrcPUId 	  	  	 INT,
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @AccessLevel 	 INT,
 	  	  	 @RC 	  	  	  	 INT,
 	  	  	 @EntryOn 	  	  	 DATETIME,
 	  	  	 @CommentId 	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(1)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @UnitName
 	  	  	 
IF @PUId IS NULL RETURN(2)
SELECT 	 @PEIId = NULL
SELECT 	 @PEIId = PEI_Id
 	 FROM 	 PrdExec_Inputs
 	 WHERE 	 PU_Id = @PUId AND
 	  	  	 Input_Name = @InputName
IF @PEIId IS NULL RETURN(3)
SELECT 	 @PEIPId = NULL
SELECT 	 @PEIPId = PEIP_Id
 	 FROM 	 PrdExec_Input_Positions
 	 WHERE 	 PEIP_Desc = @Position
IF @PEIPId IS NULL RETURN(4)
SELECT 	 @SrcPLId = NULL
SELECT 	 @SrcPLId = PL_Id
 	 FROM 	 Prod_Lines
 	 WHERE 	 PL_Desc = @SrcLineName
IF @SrcPLId IS NULL RETURN(5)
SELECT 	 @SrcPUId = NULL
SELECT 	 @SrcPUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @SrcPLId AND
 	  	  	 PU_Desc = @SrcUnitName
 	  	  	 
IF @SrcPLId IS NULL RETURN(6)
SELECT 	 @EventId = NULL
SELECT 	 @EventId = Event_Id
 	 FROM 	 Events
 	 WHERE 	 PU_Id = @SrcPUId AND
 	  	  	 Event_Num = @SrcEventName
IF @EventId IS NULL AND @TransactionType = 3 RETURN(7)
--If There Is No Security Group Attached, Bail With Success
IF @GroupId IS NOT NULL 
BEGIN
 	 --Check Security Group
 	 SELECT 	 @AccessLevel = NULL
 	 SELECT 	 @AccessLevel = MAX(Access_Level)
 	  	 FROM 	 User_Security 
 	  	 WHERE User_id = @UserId AND 
 	  	  	  	 Group_id = @GroupId
 	 
 	 IF @AccessLevel IS NULL RETURN(8)
 	 
 	 IF @AccessLevel < 3 RETURN(8)
END
SELECT 	 @Unloaded = 	 CASE @TransactionType 
 	  	  	  	  	  	  	  	 WHEN 1 THEN 0 
 	  	  	  	  	  	  	  	 WHEN 2 THEN 0 
 	  	  	  	  	  	  	  	 WHEN 3 THEN 1 
 	  	  	  	  	  	  	  	 ELSE 0 
 	  	  	  	  	  	  	 END
IF @WriteDirect = 1 AND @UpdateClientOnly = 0
BEGIN
 	 EXECUTE 	 @RC = spServer_DBMgrUpdPEInputEvent
 	  	  	  	  	 @TransactionType, 
 	  	  	  	  	 0,
 	  	  	  	  	 @Timestamp,
 	  	  	  	  	 @UserId, 
 	  	  	  	  	 @CommentId,
 	  	  	  	  	 @PEIId, 
 	  	  	  	  	 @PEIPId,
 	  	  	  	  	 @EventId,
 	  	  	  	  	 @DimensionX,
 	  	  	  	  	 @DimensionY,
 	  	  	  	  	 @DimensionZ,
 	  	  	  	  	 @DimensionA,
 	  	  	  	  	 @Unloaded,
 	  	  	  	  	 @EntryOn OUTPUT,
                                        @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(9)
 	 END
END
RETURN(0)
