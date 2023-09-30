CREATE PROCEDURE dbo.spSDK_IncomingProductionEvent412
 	 @WriteDirect 	  	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @EventName 	  	  	  	  	 nvarchar(25),
 	 @EventType 	  	  	  	  	 nvarchar(50),
 	 @EventStatus 	  	  	  	 nvarchar(50),
 	 @TestingStatus 	  	  	 nvarchar(50),
 	 @AppliedProduct 	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	  	  	 nvarchar(50),
 	 @StartTime 	  	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	  	  	 INT,
 	 @SignoffUserId 	  	  	 INT OUTPUT,
 	 @ApproverUserId 	  	  	 INT OUTPUT,
 	 @TransNum 	  	   	  	  	  	 INT OUTPUT,
 	 @EventId 	  	  	  	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
 	 @EventTypeId 	  	  	  	 INT OUTPUT,
 	 @EventStatusId 	  	  	 INT OUTPUT,
 	 @TestingStatusID 	  	 INT OUTPUT,
 	 @OriginalProductId 	 INT OUTPUT,
 	 @AppliedProductID 	  	 INT OUTPUT,
 	 @PUId 	  	  	  	  	  	  	  	 INT OUTPUT,
 	 @CommentId 	  	  	  	  	 INT OUTPUT,
 	 @ProductChangeStart 	 DATETIME OUTPUT,
 	 @ProductChangeEnd 	  	 DATETIME OUTPUT
AS
DECLARE @Rc Int
DECLARE @ESignatureId Int
SET @ESignatureId = Null
EXECUTE @Rc =  dbo.spSDK_IncomingProductionEvent 	 @WriteDirect,@UpdateClientOnly,@EventName,@EventType,@EventStatus,
 	 @TestingStatus,@AppliedProduct,@UnitName,@LineName,@StartTime,
 	 @EndTime,@UserId,@SignoffUserId OUTPUT,@ApproverUserId OUTPUT,@TransNum OUTPUT,
 	 @EventId OUTPUT,@TransactionType OUTPUT,@ESignatureId OUTPUT, 	 @EventTypeId OUTPUT,@EventStatusId OUTPUT,
 	 @TestingStatusID OUTPUT,@OriginalProductId OUTPUT,@AppliedProductID OUTPUT,@PUId OUTPUT,@CommentId OUTPUT,
 	 @ProductChangeStart OUTPUT, 	 @ProductChangeEnd 	  OUTPUT
 	 
RETURN(@Rc)
