CREATE procedure [dbo].[spSDK_AU_ReasonCategoryData_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ReasonCategoryId int, 
@ReasonCategoryName nvarchar(50), 
@ReasonTreeDataId int
AS
IF @Id Is NOT Null
BEGIN
 	 SELECT 'Event Reason Category Data is not updatable'
 	 RETURN(-100)
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Event_Reason_Category_Data  WHERE ERC_Id = @ReasonCategoryId and Event_Reason_Tree_Data_Id =  @ReasonTreeDataId)
 	 BEGIN
 	  	 SELECT 'Event Reason Category Data exists - add not allowed'
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_CreateCategoryMember @ReasonTreeDataId,@ReasonCategoryId,@AppUserId,@Id Output
 	 IF @Id is Null
 	 BEGIN
 	  	 SELECT 'Error adding Event Reason Category Data'
 	  	 RETURN(-100)
 	 END
END
Return(1)
