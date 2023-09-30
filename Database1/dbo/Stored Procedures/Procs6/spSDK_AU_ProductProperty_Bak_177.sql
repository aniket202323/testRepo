CREATE procedure [dbo].[spSDK_AU_ProductProperty_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AutoSyncCharacteristics tinyint ,
@CommentId int OUTPUT,
@CommentText text ,
@ExternalLink varchar(100) ,
@ProductFamily nvarchar(50) ,
@ProductFamilyId int ,
@ProductProperty nvarchar(50) ,
@PropertyOrder int ,
@PropertyType nvarchar(50) ,
@PropertyTypeId int ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int 
AS
DECLARE @OldDesc 	  	  	  	 VarChar(50),
 	  	  	  	 @CurrentComment 	 Int
SET @PropertyTypeId = Coalesce(@PropertyTypeId,1)
IF @PropertyTypeId Not IN (1,3)
BEGIN
 	  	 Select 'Failed - invalid property type'
 	  	 Return (-100)
END
IF @Id Is Null
BEGIN
 	 SELECT @Id = Prop_id From Product_Properties WHERE Prop_Desc = @ProductProperty
  If @Id Is Not Null
  BEGIN
 	  	 Select 'Failed - could not create - property already exists'
 	  	 Return (-100)
  END
 	 Execute spEM_CreateProp @ProductProperty,@PropertyTypeId,@AppUserId,@Id OUTPUT
  If @Id Is Null
  BEGIN
 	  	 Select 'Failed - could not create property'
 	  	 Return (-100)
  END
END
ELSE
BEGIN
 	 SELECT @OldDesc = Prop_Desc,@CurrentComment = Comment_Id 
 	  	 FROM Product_Properties
 	  	 WHERE Prop_Id = @Id
 	 IF @OldDesc <> @ProductProperty
 	 BEGIN
 	  	 EXECUTE spEM_RenameProp @Id,@ProductProperty,@AppUserId
 	 END
END
EXECUTE spEM_PutPropertyData @Id,@ProductFamilyId,@AutoSyncCharacteristics,@AppUserId
EXECUTE spEM_PutSecurityProp @Id,@SecurityGroupId,@AppUserId
EXECUTE spEM_PutExtLink  @Id,'ao',@ExternalLink,Null,null,@AppUserId
SET @CommentId = COALESCE(@CurrentComment,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'ao',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'ao',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
