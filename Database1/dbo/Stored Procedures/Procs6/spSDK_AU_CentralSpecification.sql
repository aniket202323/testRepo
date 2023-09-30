CREATE procedure [dbo].[spSDK_AU_CentralSpecification]
@AppUserId int,
@Id int OUTPUT,
@Characteristic nvarchar(50) ,
@CharacteristicId int ,
@CommentId int OUTPUT,
@CommentText text ,
@EffectiveDate datetime ,
@EsignatureLevel varchar(200) ,
@ESignatureLevelId int ,
@ExpirationDate datetime ,
@LCL nvarchar(25) ,
@LEL nvarchar(25) ,
@LRL nvarchar(25) ,
@LUL nvarchar(25) ,
@LWL nvarchar(25) ,
@OEsignatureLevel tinyint ,
@OLCL tinyint ,
@OLEL tinyint ,
@OLRL tinyint ,
@OLUL tinyint ,
@OLWL tinyint ,
@OTCL tinyint ,
@OTestingFrequency tinyint ,
@OTGT tinyint ,
@OUCL tinyint ,
@OUEL tinyint ,
@OURL tinyint ,
@OUUL tinyint ,
@OUWL tinyint ,
@ProductProperty nvarchar(50) ,
@ProductPropertyId int ,
@PropertySpecification nvarchar(50) ,
@PropertySpecificationId int ,
@SpecTransaction varchar(100) OUTPUT,
@SpecTransactionId int OUTPUT,
@TCL nvarchar(25) ,
@TestingFrequency int ,
@TGT nvarchar(25) ,
@UCL nvarchar(25) ,
@UEL nvarchar(25) ,
@URL nvarchar(25) ,
@UUL nvarchar(25) ,
@UWL nvarchar(25) 
AS
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @ApprovedDate DateTime, @CurrentComment INT, @Derived INT
If (@ProductProperty Is NULL)
 	 Select @ProductProperty = Prop_Desc From Product_Properties Where Prop_Id = @ProductPropertyId
 	 
IF @Id IS NULL
BEGIN
 	 Select @Derived = NULL
 	 Select @Derived = Derived_From_Parent From Characteristics Where Char_Id = @CharacteristicId
 	 If (@Derived Is NULL)
 	  	 Set @Derived = 0
 	 Else
 	  	 Set @Derived = 1
 	 DECLARE @CurrentTransId Int
 	 
 	 IF NOT EXISTS(SELECT 1 FROM Transactions)
 	  	 Select @CurrentTransId = 1
 	 Else
 	  	 SELECT @CurrentTransId = IDENT_CURRENT('Transactions') + 1
 	  	 
 	 SELECT @SpecTransaction = '<' + Convert(VarChar(10),@CurrentTransId) + '>' + 'SDK-Specs' 
 	 
 	 EXECUTE spEM_CreateTransaction  @SpecTransaction,Null,1,Null,@AppUserId,@SpecTransactionId OUTPUT 	 
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportCentralSpecs
 	  	  	  	  	  	  	 @ProductProperty,@PropertySpecification,@Characteristic,@Derived,@LEL,@OLEL,
 	  	  	  	  	  	  	 @LRL,@OLRL,@LWL,@OLWL,@LUL,@OLUL,@TGT,@OTGT,@UUL,@OUUL,@UWL,@OUWL,@URL,@OURL,
 	  	  	  	  	  	  	 @UEL,@OUEL,@TestingFrequency,@OTestingFrequency,@EsignatureLevel,@OEsignatureLevel,@LCL,@OLCL,@TCL,@OTCL,
 	  	  	  	  	  	  	 @UCL,@OUCL,@AppUserId,@SpecTransactionId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_ApproveTrans @SpecTransactionId,@AppUserId,1,Null,@ApprovedDate,@EffectiveDate Output
 	 SELECT @Id = a.AS_Id,@CurrentComment = Comment_Id  
 	  	 FROM Active_Specs a
 	  	 WHERE a.Char_Id = @CharacteristicId AND a.Spec_Id = @PropertySpecificationId and a.Effective_Date = @EffectiveDate
 	 SET @CommentId = COALESCE(@CurrentComment,@CommentId)
 	 IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
 	 BEGIN
 	  	 UPDATE Active_Specs SET Comment_Id = NULL WHERE AS_Id =  @Id
 	  	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	  	 SET @CommentId = NULL
 	 END
 	 IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
 	 BEGIN
    Insert Into Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 values (@CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 5)
    Select @CommentId = Scope_Identity()
 	  	 UPDATE Active_Specs SET Comment_Id = @CommentId WHERE AS_Id =  @Id
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @CommentId IS NOT NULL -- UPDATE TEXT
 	  	 BEGIN
 	  	  	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	  	 END
 	 END
END
ELSE
BEGIN
 	 SELECT 'Error - Updates to specifications are not supported'
 	 RETURN(-100)
END
RETURN(1)
