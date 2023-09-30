CREATE PROCEDURE dbo.spSDK_IncomingVariable412
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @VariableName 	  	  	 nvarchar(50),
 	 @CharacteristicName 	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @TimeStamp 	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
 	 @Result 	  	  	  	  	 nvarchar(25),
 	 -- Input/Output Parameters
 	 @SignoffUserId  	  	 INT OUTPUT,
 	 @ApproverUserId  	  	 INT OUTPUT,
 	 @TransNum  	  	  	  	 INT OUTPUT,
 	 @TestId 	  	  	  	  	 INT OUTPUT,
 	 -- Output Parameters
 	 @VariableId 	  	  	  	 INT OUTPUT,
 	 @PUId 	  	  	  	  	  	 INT OUTPUT,
 	 @CommentId 	  	  	  	 INT OUTPUT
AS
DECLARE @ESignatureId Int
DECLARE @RC Int
EXECUTE @RC = spSDK_IncomingVariable 	  	 @WriteDirect,@UpdateClientOnly,@VariableName,@CharacteristicName,@UnitName,
 	  	  	  	  	 @LineName,@TimeStamp,@UserId,@Result,@SignoffUserId  OUTPUT,
 	  	  	  	  	 @ApproverUserId OUTPUT,@ESignatureId OUTPUT,@TransNum OUTPUT,@TestId OUTPUT,@VariableId OUTPUT,
 	  	  	  	  	 @PUId OUTPUT, 	 @CommentId OUTPUT
RETURN(@RC)
