CREATE procedure [dbo].[spSDK_AU_ReasonTree_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ReasonTreeName nvarchar(50) ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int 
AS
 	 IF @Id Is Not Null
 	 BEGIN
 	  	 IF Not EXISTS(SELECT 1 FROM Event_Reason_Tree WHERE Tree_Name_Id = @Id)
 	  	 BEGIN
 	  	  	 SELECT 'Event Reason Tree Not Found to Update' 
 	  	  	 RETURN(-100)
 	  	 END
 	  	 IF EXISTS(SELECT 1 FROM Event_Reason_Tree WHERE Tree_Name = @ReasonTreeName)
 	  	 BEGIN
 	  	  	 SELECT 'Event Reason Tree Name already exists Update Failed' 
 	  	  	 RETURN(-100)
 	  	 END
 	  	 EXECUTE spEM_RenameReasonTree @Id,@ReasonTreeName,@AppUserId
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF EXISTS(SELECT 1 FROM Event_Reason_Tree WHERE Tree_Name = @ReasonTreeName)
 	  	 BEGIN
 	  	  	 SELECT 'Event Reason Tree Already Exists - Can Not Add' 
 	  	  	 RETURN(-100)
 	  	 END
 	  	 EXECUTE spEM_CreateReasonTreeName @ReasonTreeName,@AppUserId,@Id OUTPUT
 	  	 IF @Id Is Null
 	  	 BEGIN
 	  	  	 SELECT 'Failed to create Event Reason Tree' 
 	  	  	 RETURN(-100)
 	  	 END
 	 END
 	 EXECUTE spEM_PutSecurityReasonTree @Id,@SecurityGroupId,@AppUserId
  Return(1)
