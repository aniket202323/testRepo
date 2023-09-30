CREATE procedure [dbo].[spSDK_AU_DataTypePhrase]
@AppUserId int,
@Id int OUTPUT,
@CommentRequired bit ,
@DataType nvarchar(50) ,
@DataTypeId int ,
@DataTypePhrase nvarchar(25) ,
@DataTypePhraseOrder Smallint_Natural ,
@IsActive bit 
AS
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldOrder Int,@OldPhrase VarChar(50),@OldActive Bit
DECLARE @OrderError Int
DECLARE @MinOrder Int
DECLARE @MaxOrder Int
If (@IsActive Is NULL)
 	 Select @IsActive = 0
 	 
If (@CommentRequired Is NULL)
 	 Select @CommentRequired = 0
 	 
IF @Id Is Null
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportDataTypes 	 @DataType,@DataTypePhrase,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = Phrase_Id From Phrase a where Phrase_Value = @DataTypePhrase and a.Data_Type_Id = @DataTypeId
END
ELSE
BEGIN
 	 SELECT  @OldOrder = Phrase_Order,@OldPhrase = Phrase_Value,@OldActive = Active
 	  	 FROM Phrase
 	  	 WHERE Phrase_Id = @Id
 	 SET @IsActive = Coalesce(@IsActive,@OldActive)
 	 IF @OldPhrase <> @DataTypePhrase
 	 BEGIN
 	  	 EXECUTE spEM_RenamePhrase  @Id,@DataTypePhrase,1,@AppUserId
 	 END
 	 
 	 IF @OldOrder <> @DataTypePhraseOrder
 	 BEGIN
 	   SELECT @MaxOrder = MAX(Phrase_Order),@MinOrder = MIN(Phrase_Order)
 	  	  	 FROM Phrase
 	  	  	 WHERE Data_Type_Id = @DataTypeId
 	  	 IF @DataTypePhraseOrder > @MaxOrder OR @DataTypePhraseOrder  < @MinOrder
 	  	 BEGIN
 	  	  	 SELECT 'New Order must be between [' + CONVERT(VarChar(10),@MinOrder) + '] and [' + CONVERT(VarChar(10),@MaxOrder) + ']'
 	  	  	 RETURN(-100)
 	  	 END
 	  	 EXECUTE spEM_OrderPhrases  @Id,@DataTypePhraseOrder, 0,@AppUserId,@OrderError OUTPUT
 	  	 IF @OrderError = 1
 	  	 BEGIN
 	  	  	 SELECT 'order is incorrect - cannot be repaired using SDK' 
 	  	  	 RETURN(-100)
 	  	 END
 	 END
END
 	 
UPDATE Phrase Set Comment_Required =  @CommentRequired,Active =  @IsActive WHERE Phrase_Id = @Id
Return(1)
