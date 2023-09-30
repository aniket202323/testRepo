CREATE PROCEDURE dbo.spSDK_IncomingGenealogy
 	 -- Input Variables
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @ParentEventName 	  	 nvarchar(25),
 	 @ParentEventType 	  	 nvarchar(50),
 	 @ParentUnitName 	  	 nvarchar(50),
 	 @ParentLineName 	  	 nvarchar(50),
 	 @ChildEventName 	  	 nvarchar(25),
 	 @ChildEventType 	  	 nvarchar(50),
 	 @ChildUnitName 	  	  	 nvarchar(50),
 	 @ChildLineName 	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	  	 INT,
 	 @DimensionX 	  	  	  	 FLOAT,
 	 @DimensionY 	  	  	  	 FLOAT,
 	 @DimensionZ 	  	  	  	 FLOAT,
 	 @DimensionA 	  	  	  	 FLOAT,
 	 @StartCoordX 	  	  	 REAL,
 	 @StartCoordY 	  	  	 REAL,
 	 @StartCoordZ 	  	  	 REAL,
 	 @StartCoordA 	  	  	 REAL,
 	 @StartTime 	  	  	  	 DATETIME,
 	 @Timestamp 	  	  	  	 DATETIME,
 	 @ParentComponentId 	 INT,
 	 @ExtendedInfo 	  	  	 nvarchar(255),
 	 -- Input/Output Variables
 	 @ComponentId 	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
        @ESignatureId                   INT OUTPUT,
 	 -- Output Variables
 	 @ChildUnitId 	  	  	 INT OUTPUT,
 	 @ParentEventId 	  	  	 INT OUTPUT,
 	 @ChildEventId 	  	  	 INT OUTPUT
AS
-- Return Values
-- 0 - Success
-- 2 - Parent Line Not Found
-- 3 - Parent Unit Not Found
-- 4 - Parent Event Not Found
-- 5 - Child Line Not Found
-- 6 - Child Unit Not Found
-- 7 - Child Event Not Found
-- 8 - Component Not Found For Delete
-- 9 - Access Denied, Manager Level Access To Child Unit Required
DECLARE 	 @ParentUnitId 	 INT,
 	  	  	 @ParentLineId 	 INT,
 	  	  	 @ChildLineId 	 INT,
 	  	  	 @RC 	  	  	  	 INT,
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @AccessLevel 	 INT,
 	  	  	 @CheckId 	  	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
IF @StartTime <= '1900-01-01'
BEGIN
 	 SET 	 @StartTime = NULL
END
IF @Timestamp <= '1900-01-01'
BEGIN
 	 SET 	 @Timestamp = NULL
END
--Lookup Parent Information
Select @ParentLineId = NULL
Select @ParentLineId = PL_Id From Prod_Lines Where PL_Desc = @ParentLineName
If @ParentLineId Is NULL Return(2)
Select @ParentUnitId = NULL
Select @ParentUnitId = PU_Id From Prod_Units Where PU_Desc = @ParentUnitName and PL_Id = @ParentLineId
If @ParentUnitId Is NULL Return(3)
Select @ParentEventId = NULL
Select @ParentEventId = Event_Id From Events Where PU_ID = @ParentUnitId and Event_Num = @ParentEventName
If @ParentEventId Is NULL Return(4)
--Lookup Child Information, Security Is Based On Child
Select @ChildLineId = NULL
Select @ChildLineId = PL_Id From Prod_Lines Where PL_Desc = @ChildLineName
If @ChildLineId Is NULL Return(5)
Select @ChildUnitId = NULL
Select @ChildUnitId = PU_Id, @GroupId = Group_Id From Prod_Units Where PU_Desc = @ChildUnitName and PL_Id = @ChildLineId
If @ChildUnitId Is NULL Return(6)
Select @ChildEventId = NULL
Select @ChildEventId = Event_Id From Events Where PU_ID = @ChildUnitId and Event_Num = @ChildEventName
If @ChildEventId Is NULL Return(7)
If @Timestamp = 0 Select @Timestamp = NULL
IF @ComponentId IS NULL
BEGIN
 	 If @Timestamp Is Null
 	 --See If This Linkage Already Exists
 	  	 SELECT 	 @ComponentId = Component_Id 
 	  	  	 FROM 	 Event_Components 
 	  	  	 WHERE 	 Event_Id = @ChildEventId AND  	 Source_Event_Id = @ParentEventId and Timestamp is null
 	 Else
 	  	 SELECT 	 @ComponentId = Component_Id 
 	  	  	 FROM 	 Event_Components 
 	  	  	 WHERE 	 Event_Id = @ChildEventId AND  	 Source_Event_Id = @ParentEventId and Timestamp = @Timestamp
END
IF 	 @ComponentId IS NULL AND @TransactionType = 3 
BEGIN
 	 RETURN(8)
END
--Check Security
IF @GroupId IS NOT NULL 
BEGIN
 	 --Check Security Group
 	 SELECT 	 @AccessLevel = NULL
 	 SELECT 	 @AccessLevel = MAX(Access_Level)
 	  	 FROM 	 User_Security 
 	  	 WHERE User_id = @UserId AND 
 	  	  	  	 Group_id = @GroupId
 	 
 	 IF @AccessLevel IS NULL RETURN(9)
 	 
 	 IF @AccessLevel < 2 RETURN(9)
END
IF @ParentComponentId <> 0
BEGIN
 	 SET 	  	 @CheckId = NULL
 	 SELECT 	 @CheckId = Component_Id
 	  	 FROM 	 Event_Components
 	  	 WHERE 	 Component_Id = @ParentComponentId
 	 IF 	 @CheckId IS NULL
 	 BEGIN
 	  	 RETURN(11)
 	 END
END
IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
BEGIN
 	 IF @ParentComponentId = 0
 	 BEGIN
 	  	 SET 	 @ParentComponentId = NULL
 	 END
 	 IF @StartTime = 0
 	 BEGIN
 	  	 SET 	 @StartTime = NULL
 	 END
 	 EXECUTE @RC = spServer_DBMgrUpdEventComp
 	  	  	  	 @UserId, 
 	  	  	  	 @ChildEventId, 
 	  	  	  	 @ComponentId OUTPUT, 
 	  	  	  	 @ParentEventId, 
 	  	  	  	 @DimensionX, 
 	  	  	  	 @DimensionY, 
 	  	  	  	 @DimensionZ, 
 	  	  	  	 @DimensionA, 
 	  	  	  	 0, 
 	  	  	  	 @TransactionType, 
 	  	  	  	 @ChildUnitId OUTPUT,
 	  	  	  	 @StartCoordX,
 	  	  	  	 @StartCoordY,
 	  	  	  	 @StartCoordZ,
 	  	  	  	 @StartCoordA,
 	  	  	  	 @StartTime,
 	  	  	  	 @Timestamp,
 	  	  	  	 @ParentComponentId,
 	  	  	  	 NULL,
 	  	  	  	 @ExtendedInfo,
                NULL,
                1,
                @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(10)
 	 END
END
RETURN(0)
