CREATE procedure [dbo].[spSDK_AU_PropertySpecification_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ArraySize int ,
@CommentId int OUTPUT,
@CommentText text ,
@DataType nvarchar(50) ,
@DataTypeId int ,
@EngineeringUnits varchar(200) ,
@ExtendedInfo varchar(255) ,
@ExternalLink varchar(100) ,
@ParentId int ,
@ProductProperty nvarchar(50) ,
@ProductPropertyId int ,
@PropertySpecification nvarchar(50) ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int ,
@SpecificationOrder int ,
@SpecPrecision Tinyint_Precision ,
@Tag varchar(200) 
AS
DECLARE 
 	  	  	  	 @MyComment 	  	  	  	 Varchar(1000),
 	  	  	  	 @CurrentCommentId 	 Int,
 	  	  	  	 @OldSpecDesc 	  	  	 VarChar(50)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
IF @Id is Not Null
BEGIN
 	 SELECT @CurrentCommentId = Comment_Id,@OldSpecDesc = Spec_Desc 
 	  	 FROM Specifications
 	  	 WHERE Spec_Id = @Id
 	 IF @OldSpecDesc <> @PropertySpecification
 	 BEGIN
 	  	 EXECUTE spEM_RenameSpec @Id,@PropertySpecification,@AppUserId
 	 END
END
ELSE
BEGIN
 	 SET @MyComment = SUBSTRING(@CommentText,1,1000) 	 
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportSpecVariables
 	  	  	  	  	 @ProductProperty ,
 	  	  	  	  	 @PropertySpecification,
 	  	  	  	  	 @DataType,
 	  	  	  	  	 @SpecPrecision,
 	  	  	  	  	 @EngineeringUnits,
 	  	  	  	  	 @Tag,
 	  	  	  	  	 @ExtendedInfo,
 	  	  	  	  	 @ExternalLink,
 	  	  	  	  	 @MyComment,
 	  	  	  	  	 @AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
IF @Id Is NUll
BEGIN
 	 SELECT @Id = a.Spec_Id,@CurrentCommentId = Comment_Id
 	  	 FROM Specifications a
 	  	 WHERE Spec_Desc = @PropertySpecification and a.Prop_Id = @ProductPropertyId
END
EXECUTE spEM_PutSecuritySpec @Id,@SecurityGroupId,@AppUserId
 	  	  	  	  	 
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'as',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'as',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
