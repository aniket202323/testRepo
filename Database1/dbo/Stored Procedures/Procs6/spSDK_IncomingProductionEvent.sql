CREATE PROCEDURE dbo.spSDK_IncomingProductionEvent
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @EventName 	  	  	  	 nvarchar(25),
 	 @EventType 	  	  	  	 nvarchar(50),
 	 @EventStatus 	  	  	 nvarchar(50),
 	 @TestingStatus 	  	  	 nvarchar(50),
 	 @AppliedProduct 	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @StartTime 	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @SignoffUserId 	  	  	 INT OUTPUT,
 	 @ApproverUserId 	  	  	 INT OUTPUT,
 	 @TransNum  	  	  	  	 INT OUTPUT,
 	 @EventId 	  	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
     @ESignatureId          	 INT OUTPUT,
 	 -- Output Parameters
 	 @EventTypeId 	  	  	 INT OUTPUT,
 	 @EventStatusId 	  	  	 INT OUTPUT,
 	 @TestingStatusID 	  	 INT OUTPUT,
 	 @OriginalProductId 	  	 INT OUTPUT,
 	 @AppliedProductID 	  	 INT OUTPUT,
 	 @PUId 	  	  	  	  	 INT OUTPUT,
 	 @CommentId 	  	  	  	 INT OUTPUT,
 	 @ProductChangeStart 	  	 DATETIME OUTPUT,
 	 @ProductChangeEnd 	  	 DATETIME OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Line Not Found
-- 3 - Unit Not Found
-- 4 - Event Not Found For Delete
-- 5 - Applied Product Not Found
-- 6 - Event Status Not Found
-- 7 - Direct Write Failed
-- 8 - Signoff User Name Not Found
-- 9 - Approver User Name Not Found
-- 10 - Esignature required but not supplied
-- 11 - Inadquate Esignature level supplied
-- 12 - Event Name must be specified
DECLARE 	 @PLId 	  	  	  	 INT,
 	  	 @ESignatureLevel 	 INT,
 	  	 @OldSignoffUserId 	 INT,
 	  	 @OldApproverUserId 	 INT,
        @VerifyUserId 	  	 INT
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(2)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PU_Desc = @UnitName AND 
 	  	  	 PL_Id = @PLId
IF @PUId IS NULL RETURN(3)
-- If we are not supplied an event id, look it up by name
If @EventId=0 Set @EventId = NULL
IF @EventId IS NULL
BEGIN
    -- Is there an event name?
    If @EventName='' Set @EventName = null
    IF @EventName is Null return(12)
 	 --Lookup Event
 	 SELECT 	 @EventId = Event_Id,
 	  	  	  	 @CommentId = Comment_Id 
 	  	 FROM 	 Events 
 	  	 WHERE 	 PU_Id = @PUId AND 
 	  	  	  	 Event_Num = @EventName
 	 
    -- Return error if we are deleting and the event was not found
 	 IF @TransactionType = 3 AND @EventId IS NULL 
 	 BEGIN
 	  	 RETURN(4)
 	 END
    -- If we are updating, but the event was not found, switch to add
 	 IF @TransactionType = 2 and @EventId is null
 	 BEGIN
 	  	 SELECT 	 @TransactionType = 1
 	 END
END 
-- If we already have the event id, we just need to get the comment
ELSE
BEGIN
 	 SELECT 	 @CommentId = Comment_Id
 	  	 FROM 	 Events
 	  	 WHERE 	 Event_Id = @EventId
END
-- We do not need any more information if this is a delete
IF @TransactionType <> 3
BEGIN
 	 --Lookup Applied Product
 	 IF @AppliedProduct IS NOT NULL
 	 BEGIN
 	     SELECT 	 @AppliedProductId = NULL
 	     SELECT 	 @AppliedProductId = Prod_Id 
 	  	  	 FROM 	 Products 
 	  	  	 WHERE 	 Prod_Code = @AppliedProduct
 	 
 	     IF @AppliedProductId IS NULL RETURN(5)
 	 END
 	 
 	 --*******************************************************************************
 	 -- TODO: Will Need To Be Modified With Backend Change To Support, etc
 	 --*******************************************************************************
    -- Set EventType and TestingStatus to null
 	 SELECT 	 @EventTypeId = NULL
 	 SELECT 	 @TestingStatusId = NULL
 	 
    -- If there is no event status, return an error
 	 SELECT 	 @EventStatusId = NULL
 	 SELECT 	 @EventStatusId = ProdStatus_Id 
 	  	 FROM 	 Production_Status 
 	  	 WHERE 	 ProdStatus_Desc = @EventStatus
 	 
 	 IF @EventStatusId IS NULL RETURN(6)  	 
END
-- Find the ESignature level required by the product
SELECT 	 @ESignatureLevel = 0
SELECT 	 @ESignatureLevel = Coalesce(p.Event_ESignature_Level, 0)
 	 FROM 	 Production_Starts ps
 	 JOIN 	 Products p on p.Prod_Id = ps.Prod_Id
 	 WHERE 	 (ps.PU_Id = @PUId)
 	 AND 	 (ps.Start_Time <= @StartTime)
 	 AND 	 ((ps.End_Time > @StartTime) OR (ps.End_Time is NULL))
-- If ESignature is required, determine if the level is correct
IF @ESignatureLevel > 0
BEGIN
  -- if no esignature at all is supplied, generate an error
  IF @ESignatureId is NULL RETURN(10)
  -- check level of the esginature record 
  ELSE 
  BEGIN
     SET @VerifyUserId = 0
     SELECT @VerifyUserId = IsNull(Verify_User_Id,0) 
     FROM ESignature e WHERE e.Signature_Id = @ESignatureId
 	  IF (@ESignatureLevel = 2) AND (@VerifyUserId = 0) RETURN(11)
  END
END
-- If the event exists, check data user and approver
IF @ApproverUserId is NULL Set @ApproverUserId = 0
IF @SignoffUserId is NULL Set @SignoffUserId = 0
IF @EventId <> 0 AND @EventId IS NOT NULL
BEGIN
   -- Get GBDB user and approver
 	 SELECT 	 @OldApproverUserId = ISNULL(Approver_User_Id,0),
 	  	  	 @OldSignoffUserId = ISNULL(User_Signoff_Id,0)
 	  	 FROM 	 Events
 	  	 WHERE 	 Event_Id = @EventId
    -- The SDK can update without knowing the user and approver.
    -- If they exist, the user and approver are set from the database.
    IF @TransNum = 0 -- update without approval
    BEGIN
 	  	 IF (@ApproverUserId = 0) AND (@OldApproverUserId <> 0)
 	  	 BEGIN
 	  	  	 SELECT @ApproverUserId = @OldApproverUserId
 	  	 END
 	  	 IF (@SignoffUserId = 0) AND (@OldSignoffUserId <> 0)
 	  	 BEGIN
 	  	     SELECT @SignoffUserId = @OldSignoffUserId
 	  	 END
     END
    -- If the SDK must approve data, the data user and data approver must match
    ELSE IF (@TransNum = 4 OR @TransNum = 5) --APPROVE OR UNAPPROVE
 	 BEGIN
        -- If approval is required and not supplied, reject it
        IF (@OldApproverUserId <> 0) AND (@ApproverUserId = 0)
        BEGIN
 	  	   RETURN(9)
 	  	 END
        -- If a GBDB approver exists, make sure it matches the SDK approver
        IF (@OldApproverUserId <> 0) AND (@ApproverUserId <> 0) AND (@ApproverUserId<>@OldApproverUserId)
        BEGIN
 	  	   RETURN(9)
 	  	 END
        -- If user is required and not supplied, reject it
        IF (@OldSignoffUserId <> 0) AND (@SignoffUserId = 0)
        BEGIN
 	  	   RETURN(8)
 	  	 END
 	  	 -- If a GBDB signoff exists, make sure it matches the SDK signoff
        IF (@OldSignoffUserId <> 0) AND (@SignoffUserId <> 0) AND (@SignoffUserId<>@OldSignoffUserId)
        BEGIN
 	  	   RETURN(8)
 	  	 END
 	  	 -- We have verified that it is allowed, unapprove
 	  	 IF (@TransNum = 5)
        BEGIN
          SET @ApproverUserId = 0
          SET @SignoffUserId = 0
        END
 	 END
END
IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
BEGIN
 	 DECLARE 	 @RC 	  	  	 INT,
 	  	  	 @EntryOn 	  	 DATETIME
    IF (@ApproverUserId = 0) Set @ApproverUserId = null
    If (@SignoffUserId = 0) Set @SignoffUserId = null
    IF (@ESignatureId = 0) Set @ESignatureId = null
 	 EXECUTE 	 @RC = spServer_DBMgrUpdEvent
 	  	  	  	  	 @EventId OUTPUT ,
 	  	  	  	  	 @EventName, 
 	  	  	  	  	 @PUId, 
 	  	  	  	  	 @EndTime, 
 	  	  	  	  	 @AppliedProductId,
 	  	  	  	  	 NULL,
 	  	  	  	  	 @EventStatusId,
 	  	  	  	  	 @TransactionType,
 	  	  	  	  	 @TransNum,
 	  	  	  	  	 @UserId,
 	  	  	  	  	 @CommentId,
 	  	  	  	  	 @EventTypeId,
 	  	  	  	  	 @TestingStatusId,
 	  	  	  	  	 @StartTime,
 	  	  	  	  	 @EntryOn OUTPUT,
 	  	  	  	  	 0,
 	  	  	  	  	 NULL,
 	  	  	  	  	 NULL,
 	  	  	  	  	 NULL,
 	  	  	  	  	 @ApproverUserId,
 	  	  	  	  	 NULL,
 	  	  	  	  	 NULL,
 	  	  	  	  	 @SignoffUserId,
 	  	  	  	  	 NULL,
 	  	  	  	  	 NULL,
                    @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(7)
 	 END
END
RETURN(0)
