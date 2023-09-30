CREATE procedure [dbo].[spSDK_AU_Shipment]
@AppUserId int,
@Id int OUTPUT,
@ArrivalDate datetime ,
@CarrierCode varchar(25) ,
@CarrierType varchar(10) ,
@COADate datetime ,
@CommentId int OUTPUT,
@CommentText text ,
@CompleteDate datetime ,
@IsActive bit ,
@Shipment varchar(100) ,
@ShipmentDate datetime ,
@VehicleName varchar(25) 
AS
DECLARE @sShipmentDate 	 VarChar(14)
DECLARE @sCompleteDate 	 VarChar(14)
DECLARE @sCOADate 	  	  	  	 VarChar(14)
DECLARE @sArrivalDate 	  	 VarChar(14)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldShipmentNo 	 VarChar(50)
DECLARE @CurrentCommentId Int
EXECUTE spSDK_ConvertDate @ShipmentDate,@sShipmentDate Output
EXECUTE spSDK_ConvertDate @CompleteDate,@sCompleteDate Output
EXECUTE spSDK_ConvertDate @COADate,@sCOADate Output
EXECUTE spSDK_ConvertDate @ArrivalDate,@sArrivalDate Output
IF @Id is NOT NULL 
BEGIN
 	 IF Not Exists(SELECT 1 FROM Shipment WHERE Shipment_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Shipment not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @CurrentCommentId = Comment_Id,@OldShipmentNo = Shipment_Number
 	  	 FROM Shipment
 	  	 WHERE Shipment_Id = @Id
 	 IF @OldShipmentNo <> @Shipment
 	 BEGIN
 	  	 UPDATE Shipment SET Shipment_Number = @Shipment WHERE Shipment_Id = @Id
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Shipment WHERE  Shipment_Number = @Shipment)
 	 BEGIN
 	  	  	 SELECT 'Shipment already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportShipments 	 @Shipment,@CarrierType,@CarrierCode,@VehicleName,@sShipmentDate,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @sArrivalDate,@sCompleteDate,@sCOADate,@IsActive,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = a.Shipment_Id FROM Shipment a WHERE Shipment_Number = @Shipment
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Shipment failed'
 	  	 RETURN(-100)
 	 END
END
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	 UPDATE Shipment SET Comment_Id = Null WHERE Shipment_Id = @Id
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Shipment SET Comment_Id = @CommentId WHERE Shipment_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
