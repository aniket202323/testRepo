CREATE PROCEDURE dbo.spSDK_IncomingEventDetails
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @EventId 	  	  	  	  	 INT,
 	 @ProcessOrder 	  	  	 nvarchar(50),
 	 @InitialDimX 	  	  	 FLOAT,
 	 @InitialDimY 	  	  	 FLOAT,
 	 @InitialDimZ 	  	  	 FLOAT,
 	 @InitialDimA 	  	  	 FLOAT,
 	 @FinalDimX 	  	  	  	 FLOAT,
 	 @FinalDimY 	  	  	  	 FLOAT,
 	 @FinalDimZ 	  	  	  	 FLOAT,
 	 @FinalDimA 	  	  	  	 FLOAT,
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @TransactionType 	  	 INT OUTPUT,
        @ESignatureId                   INT OUTPUT,
 	 -- Output Parameters
 	 @EventStatus 	  	  	 INT OUTPUT,
 	 @PUId 	  	  	  	  	  	 INT OUTPUT,
 	 @PPId 	  	  	  	  	  	 INT OUTPUT
AS
-- Return Values
-- 0 - Success
-- 1 - Event Not Found
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @EventNum  	  	  	  	 nvarchar(25),
 	  	  	 @AltEventNum 	  	  	 nvarchar(25),
 	  	  	 @OrientationX 	  	  	 FLOAT,
 	  	  	 @OrientationY 	  	  	 FLOAT,
 	  	  	 @OrientationZ 	  	  	 FLOAT,
 	  	  	 @OrderId 	  	  	  	  	 INT,
 	  	  	 @OrderLineId 	  	  	 INT,
 	  	  	 @PPSetupDetailId 	  	 INT,
 	  	  	 @ShipmentId 	  	  	  	 INT,
 	  	  	 @CommentId 	  	  	  	 INT,
 	  	  	 @Timestamp 	  	  	  	 DATETIME,
 	  	  	 @EntryOn 	  	  	  	  	 DATETIME,
 	  	  	 @EventType 	  	  	  	 INT,
 	  	  	 @ProdId 	  	  	  	  	 INT,
 	  	  	 @AppProdId 	  	  	  	 INT,
 	  	  	 @ppsPPId 	  	  	  	  	 INT,
 	  	  	 @edPPId 	  	  	  	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
IF (SELECT COUNT(*) FROM Event_Details WHERE Event_Id = @EventId) = 0 AND @TransactionType = 2
BEGIN
 	 SELECT @TransactionType = 1
END
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id,
 	  	  	 @Timestamp = Timestamp,
 	  	  	 @EventNum = Event_Num,
 	  	  	 @EventStatus = Event_Status
 	 FROM 	 Events 
 	 WHERE 	 Event_Id = @EventId
IF @PUId IS NULL RETURN(1)
--Lookup Original Product
SELECT 	 @PPId = NULL
SELECT 	 @PPId = pp.PP_Id
 	 FROM 	 Production_Plan pp
  JOIN  PrdExec_Path_Units pepu ON pepu.Path_Id = pp.Path_Id and pepu.Is_Schedule_Point = 1 
 	 WHERE 	 pepu.PU_Id = @PUId AND
 	  	  	   pp.Process_Order = @ProcessOrder
SELECT 	 @ppsPPId = NULL
SELECT 	 @ppsPPId = PP_Id
 	 FROM 	 Production_Plan_Starts
 	 WHERE 	 PU_Id = @PUId AND
 	  	  	 Start_Time <= @Timestamp AND
 	  	  	 (End_Time >= @Timestamp OR End_Time IS NULL)
SELECT 	 @edPPId = NULL
SELECT 	 @edPPId = PP_Id
 	 FROM 	 Event_Details
 	 WHERE 	 Event_Id = @EventId
IF @PPId = @ppsPPId AND @edPPId IS NULL
BEGIN
 	 SELECT @PPId = NULL
END
IF @WriteDirect = 1 AND @UpdateClientOnly = 0
BEGIN
 	 EXECUTE 	 @RC = spServer_DBMgrUpdEventDet
 	  	  	  	  	 @UserId, 
 	  	  	  	  	 @EventId, 
 	  	  	  	  	 @PUId, 
 	  	  	  	  	 @EventNum, 
 	  	  	  	  	 @TransactionType, 
 	  	  	  	  	 0, 
 	  	  	  	  	 @AltEventNum 	  	 OUTPUT, 
 	  	  	  	  	 @EventStatus 	  	 OUTPUT, 
 	  	  	  	  	 @InitialDimX 	  	 OUTPUT, 
 	  	  	  	  	 @InitialDimY 	  	 OUTPUT, 
 	  	  	  	  	 @InitialDimZ 	  	 OUTPUT, 
 	  	  	  	  	 @InitialDimA 	  	 OUTPUT, 
 	  	  	  	  	 @FinalDimX 	  	  	 OUTPUT, 
 	  	  	  	  	 @FinalDimY 	  	  	 OUTPUT, 
 	  	  	  	  	 @FinalDimZ 	  	  	 OUTPUT, 
 	  	  	  	  	 @FinalDimA 	  	  	 OUTPUT, 
 	  	  	  	  	 @OrientationX 	  	 OUTPUT, 
 	  	  	  	  	 @OrientationY 	  	 OUTPUT, 
 	  	  	  	  	 @OrientationZ 	  	 OUTPUT, 
 	  	  	  	  	 @ProdId 	  	  	  	 OUTPUT, 
 	  	  	  	  	 @AppProdId 	  	  	 OUTPUT, 
 	  	  	  	  	 @OrderId 	  	  	  	 OUTPUT, 
 	  	  	  	  	 @OrderLineId 	  	 OUTPUT, 
 	  	  	  	  	 @PPId 	  	  	  	  	 OUTPUT, 
 	  	  	  	  	 @PPSetupDetailId 	 OUTPUT, 
 	  	  	  	  	 @ShipmentId 	  	  	 OUTPUT, 
 	  	  	  	  	 @CommentId 	  	  	 OUTPUT, 
 	  	  	  	  	 @EntryOn 	  	  	  	 OUTPUT, 
 	  	  	  	  	 @TimeStamp 	  	  	 OUTPUT, 
 	  	  	  	  	 @EventType 	  	  	 OUTPUT,
                                        @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(9)
 	 END
END
RETURN(0)
