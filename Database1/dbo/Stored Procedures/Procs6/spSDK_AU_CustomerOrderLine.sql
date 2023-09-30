CREATE procedure [dbo].[spSDK_AU_CustomerOrderLine]
@AppUserId int,
@Id int OUTPUT,
@COADate datetime ,
@CommentId int OUTPUT,
@CommentText text ,
@CompleteDate datetime ,
@ConsigneeCode varchar(50) ,
@ConsigneeId int ,
@CustomerCode varchar(50) ,
@CustomerId int ,
@CustomerOrderId int ,
@DimensionA real ,
@DimensionATolerance real ,
@DimensionX real ,
@DimensionXTolerance real ,
@DimensionY real ,
@DimensionYTolerance real ,
@DimensionZ real ,
@DimensionZTolerance real ,
@EndCustomerCode varchar(50) ,
@EndCustomerId int ,
@ExtendedInfo varchar(255) ,
@IsActive bit ,
@LineItemNumber int ,
@OrderedQuantity float ,
@OrderedUnitOfMeasure varchar(10) ,
@OrderLineGeneral1 varchar(255) ,
@OrderLineGeneral2 varchar(255) ,
@OrderLineGeneral3 varchar(255) ,
@OrderLineGeneral4 varchar(255) ,
@OrderLineGeneral5 varchar(255) ,
@ProductCode nvarchar(25) ,
@ProductId int ,
@ShipToCustomerCode varchar(50) ,
@ShipToCustomerId int 
AS
DECLARE @sCOADate Varchar(14),@sCompleteDate Varchar(14),@CurrentCommentId Int
DECLARE @PlantOrderNumber varchar(100)
EXECUTE spSDK_ConvertDate @COADate,@sCOADate OUTPUT
EXECUTE spSDK_ConvertDate @CompleteDate,@sCompleteDate OUTPUT
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldCustomerCode 	 VarChar(50)
Select @PlantOrderNumber = NULL
Select @PlantOrderNumber = Plant_Order_Number From Customer_Orders Where Order_Id = @CustomerOrderId
IF @Id Is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Customer_Order_Line_Items WHERE Order_Line_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Order Line Item not found for update'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Customer_Order_Line_Items a  	  	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Customer_Orders b on b.Order_Id  = a.Order_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 WHERE b.Plant_Order_Number = @PlantOrderNumber and Line_Item_Number = @LineItemNumber)
 	 BEGIN
 	  	 SELECT 'Order Line Item already exists add not allowed'
 	  	 RETURN(-100)
 	 END
 	 SELECT @CurrentCommentId = a.Comment_Id
 	  	 FROM Customer_Order_Line_Items a
 	  	 WHERE Order_Line_Id = @Id
END
INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportOrderLineItems 	 @PlantOrderNumber,@LineItemNumber,@ProductCode,@OrderedQuantity,@OrderedUnitOfMeasure,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ShipToCustomerCode,@ConsigneeCode,@DimensionX,@DimensionY,@DimensionZ,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @DimensionA,@DimensionXTolerance,@DimensionZTolerance,@DimensionYTolerance,@DimensionATolerance,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @sCompleteDate,@sCOADate,@ExtendedInfo,@OrderLineGeneral1,@OrderLineGeneral2,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @OrderLineGeneral3,@OrderLineGeneral4,@OrderLineGeneral5,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = a.Order_Line_Id,@CurrentCommentId = a.Comment_Id
 	  	 FROM Customer_Order_Line_Items a
 	  	 Join Customer_Orders b on b.Order_Id  = a.Order_Id
 	 WHERE b.Plant_Order_Number = @PlantOrderNumber and Line_Item_Number = @LineItemNumber
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Customer Order Line Item failed'
 	  	 RETURN(-100)
 	 END
END
Update Customer_Order_Line_Items Set EndUser_Id = @EndCustomerId, Extended_Info = @ExtendedInfo Where Order_Line_Id = @Id
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
  UPDATE Customer_Order_Line_Items SET Comment_Id = Null WHERE Line_Item_Number = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Customer_Order_Line_Items SET Comment_Id = @CommentId WHERE Order_Line_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
