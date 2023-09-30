CREATE procedure [dbo].[spSDK_AU_Product_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@EventESignatureLevel varchar(200) ,
@EventESignatureLevelId int ,
@ExtendedInfo varchar(100) ,
@ExternalLink varchar(100) ,
@IsManufacturingProduct tinyint ,
@IsSalesProduct tinyint ,
@ProdChgESignatureLevel varchar(200) ,
@ProdChgESignatureLevelId int ,
@ProductCode nvarchar(25) ,
@ProductDescription nvarchar(50) ,
@ProductFamily nvarchar(50) ,
@ProductFamilyId int 
AS
/* Obsolite fields: @IsManufacturingProduct,@IsSalesProduct */
DECLARE @ProductComment 	  	 Varchar(1000),
 	  	  	  	 @CurrentCommentId 	 Int,
 	  	  	  	 @OldDesc1 	  	  	  	  	 VarChar(50),
 	  	  	  	 @OldDesc2 	  	  	  	  	 VarChar(50),
 	  	  	  	 @OldFamilyId 	  	  	 Int
 	  	  	  	 
 	  	  	  	 
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
IF @Id is null
BEGIN
 	 SET @ProductComment = SUBSTRING(@CommentText,1,1000)
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportProdFamily
 	  	  	  	  	  	  	  	 @ProductCode,
 	  	  	  	  	  	  	  	 @ProductDescription,
 	  	  	  	  	  	  	  	 @ProductComment,
 	  	  	  	  	  	  	  	 @ProductFamily,
 	  	  	  	  	  	  	  	 Null, 	 
 	  	  	  	  	  	  	  	 @EventESignatureLevel,
 	  	  	  	  	  	  	  	 @ProdChgESignatureLevel,
 	  	  	  	  	  	  	  	 @AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = a.Prod_Id ,@CurrentCommentId = Comment_Id
 	  	 FROM Products a
 	  	 WHERE Prod_Code 	 = @ProductCode
END
ELSE
BEGIN
 	 SELECT @CurrentCommentId = Comment_Id,@OldDesc1 = Prod_Code,@OldDesc2 = Prod_Desc,@OldFamilyId = a.Product_Family_Id 
 	  	 FROM Products a
 	  	 WHERE Prod_Id  = @Id
  	  IF @OldDesc2 <> @ProductDescription
 	  BEGIN
  	  	  IF Exists(Select 1 FROM Products WHERE Prod_Desc = @ProductDescription) 
 	  	  BEGIN
  	    	  	  SELECT 'Error - Product Description Already Exists - rename failed'
  	    	  	  RETURN (-100)
  	  	  END  
  	  	  IF Exists(Select 1 FROM Products_Aspect_MaterialDefinition a WHERE a.Prod_Id = @Id) 
 	  	  BEGIN
  	    	  	  SELECT 'Error - Product is Aspected - rename must be done in SOA '
  	    	  	  RETURN (-100)
  	  	  END 
 	  	  EXECUTE spEM_RenameProdDesc  @Id,@ProductDescription,@AppUserId
 	 END
END 	   
IF @OldDesc1 <> @ProductCode
BEGIN
 	 IF Exists(Select 1 FROM Products WHERE Prod_Code = @ProductCode)
 	 BEGIN
 	  	 SELECT 'Error - Product Code Already Exists - rename failed'
 	  	 RETURN (-100)
 	 END
 	 EXECUTE spEM_RenameProdCode  @Id,@ProductCode,@AppUserId
END
IF @OldFamilyId <> @ProductFamilyId
BEGIN
 	 EXECUTE spEM_ChangeProductFamily @Id,@ProductFamilyId,@AppUserId
END
EXECUTE spEM_PutProductProperties  @Id,@EventESignatureLevelId,@ProdChgESignatureLevelId,@AppUserId
EXECUTE spEM_PutExtLink @Id,'aj',@ExternalLink,@ExtendedInfo,Null,@AppUserId
SET @CommentId = Coalesce(@CurrentCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 EXECUTE spEM_DeleteComment @Id,'aj',@AppUserId
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	 EXECUTE spEM_CreateComment  @Id,'aj',@AppUserId,1,@CommentId Output
END
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
RETURN(1)
