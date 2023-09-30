Create Procedure dbo.spSDK_IncomingInputEvent412
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @TransactionType 	  	 INT,
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @InputName 	  	  	  	 nvarchar(50),
 	 @Position 	  	  	  	 nvarchar(50),
 	 @SrcLineName 	  	  	 nvarchar(50),
 	 @SrcUnitName 	  	  	 nvarchar(50),
 	 @SrcEventName 	  	  	 nvarchar(50),
 	 @Timestamp 	  	  	  	 DATETIME,
 	 @DimensionX 	  	  	  	 FLOAT,
 	 @DimensionY 	  	  	  	 FLOAT,
 	 @DimensionZ 	  	  	  	 FLOAT,
 	 @DimensionA 	  	  	  	 FLOAT,
 	 @UserId 	  	  	  	  	 INT,
 	 -- Output Parameters
 	 @PEIId 	  	  	  	  	 INT OUTPUT,
 	 @PEIPId 	  	  	  	  	 INT OUTPUT,
 	 @EventId 	  	  	  	  	 INT OUTPUT,
 	 @Unloaded 	  	  	  	 INT OUTPUT
AS
DECLARE @ESignatureId Int, @Rc Int
EXECUTE @RC = spSDK_IncomingInputEvent 	 @WriteDirect, 	 @UpdateClientOnly, 	 @TransactionType, 	 @LineName,@UnitName,
 	 @InputName, 	 @Position,@SrcLineName,@SrcUnitName,@SrcEventName,
 	 @Timestamp,@DimensionX,@DimensionY,@DimensionZ,@DimensionA,
 	 @UserId,@ESignatureId OUTPUT,@PEIId OUTPUT,@PEIPId OUTPUT,@EventId OUTPUT,
 	 @Unloaded 	  OUTPUT
RETURN(@Rc)
