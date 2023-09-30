CREATE procedure [dbo].[spSDK_AU_ReasonCategory]
@AppUserId int,
@Id int OUTPUT,
@ReasonCategoryName nvarchar(50)
AS
Declare @OldDesc VarChar(100)
IF @Id Is NOT Null --Rename
BEGIN
 	 IF Not Exists(SELECT 1 FROM Event_Reason_Catagories WHERE ERC_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Event Reason Catagory not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldDesc = ERC_Desc   FROM Event_Reason_Catagories WHERE ERC_Id = @Id
 	 IF @OldDesc <> @ReasonCategoryName
 	 BEGIN
 	  	 EXECUTE spEM_RenameReasonCategory @Id,@ReasonCategoryName,@AppUserId
 	 END
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Event_Reason_Catagories a WHERE ERC_Desc = @ReasonCategoryName)
 	 BEGIN
 	  	 SELECT 'Event Reason Catagory exists - add not allowed'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateReasonCategory @ReasonCategoryName,@AppUserId,@Id Output
 	 IF @Id is Null
 	 BEGIN
 	  	 SELECT 'Error adding Event Reason Catagory'
 	  	 RETURN(-100)
 	 END
END
Return(1)
