CREATE procedure [dbo].[spSDK_AU_CustomerOrder_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ActualMfgDate datetime ,
@ActualShipDate datetime ,
@CommentId int OUTPUT,
@CommentText text ,
@ConsigneeCode varchar(50) ,
@ConsigneeId int ,
@CorporateOrderNumber varchar(200) ,
@CustomerCode varchar(50) ,
@CustomerId int ,
@CustomerOrderNumber varchar(200) ,
@EnteredByUserId int ,
@EnteredByUsername nvarchar(30) ,
@EnteredDate datetime ,
@ExtendedInfo varchar(255) ,
@ForecastMfgDate datetime ,
@ForecastShipDate datetime ,
@IsActive bit ,
@OrderGeneral1 varchar(100) ,
@OrderGeneral2 varchar(100) ,
@OrderGeneral3 varchar(100) ,
@OrderGeneral4 varchar(100) ,
@OrderGeneral5 varchar(100) ,
@OrderInstructions varchar(255) ,
@OrderStatus varchar(10) ,
@OrderType varchar(10) ,
@PlantOrderNumber varchar(200) ,
@ScheduleBlockNumber varchar(100) ,
@TotalLineItems int 
AS
/*
@EnteredByUserId = userid
@sEnteredDate  = set to getdate
@TotalLineItems = calculated  not setable
*/
DECLARE @sActualShipDate Varchar(14),@sActualMfgDate Varchar(14),@sEnteredDate Varchar(14),
 	  	  	  	 @sForecastMfgDate Varchar(14),@sForecastShipDate Varchar(14),@OldPlantOrderNumber VarChar(200),
 	  	  	  	 @CurrentCommentId Int
EXECUTE spSDK_ConvertDate @ActualShipDate,@sActualShipDate OUTPUT
EXECUTE spSDK_ConvertDate @ActualMfgDate,@sActualMfgDate OUTPUT
EXECUTE spSDK_ConvertDate @EnteredDate,@sEnteredDate OUTPUT
EXECUTE spSDK_ConvertDate @ForecastMfgDate,@sForecastMfgDate OUTPUT
EXECUTE spSDK_ConvertDate @ForecastShipDate,@sForecastShipDate OUTPUT
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldCustomerCode 	 VarChar(50)
IF @Id Is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Customer_Orders a WHERE Order_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Order not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldPlantOrderNumber = Plant_Order_Number,@CurrentCommentId = Comment_Id 
 	  	 FROM Customer_Orders a WHERE Order_Id = @Id
 	 IF @OldPlantOrderNumber <> @PlantOrderNumber
 	 BEGIN
 	  	 UPDATE Customer_Orders SET Plant_Order_Number = @PlantOrderNumber 	  	 WHERE Order_Id = @Id
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Customer_Orders a WHERE Plant_Order_Number = @PlantOrderNumber)
 	 BEGIN
 	  	 SELECT 'Order already exists add not allowed'
 	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportOrders 	  	 @PlantOrderNumber,@OrderType,@OrderStatus,@CustomerCode,@CustomerOrderNumber,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CorporateOrderNumber,@ConsigneeCode,@sForecastMfgDate,@sActualMfgDate,@sForecastShipDate,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @sActualShipDate,@OrderInstructions,@ExtendedInfo,@OrderGeneral1,@OrderGeneral2,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @OrderGeneral3,@OrderGeneral4,@OrderGeneral5,@IsActive,@ScheduleBlockNumber,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = a.Order_Id FROM Customer_Orders a WHERE Plant_Order_Number = @PlantOrderNumber
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Customer failed'
 	  	 RETURN(-100)
 	 END
END
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	 UPDATE Customer_Orders SET Comment_Id = Null WHERE Order_Id = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Customer_Orders SET Comment_Id = @CommentId WHERE Order_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
  Return(1)
