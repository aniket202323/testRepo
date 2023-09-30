CREATE PROCEDURE dbo.spSDK_IncomingGenealogy412
 	  	  	 @WriteDirect 	  	  	  	 BIT,
 	  	  	 @UpdateClientOnly 	  	 BIT,
 	  	  	 @ParentEventName 	  	 nvarchar(25),
 	  	  	 @ParentEventType 	  	 nvarchar(50),
 	  	  	 @ParentUnitName 	  	  	 nvarchar(50),
 	  	  	 @ParentLineName 	  	  	 nvarchar(50),
 	  	  	 @ChildEventName 	  	  	 nvarchar(25),
 	  	  	 @ChildEventType 	  	  	 nvarchar(50),
 	  	  	 @ChildUnitName 	  	  	 nvarchar(50),
 	  	  	 @ChildLineName 	  	  	 nvarchar(50),
 	  	  	 @UserId 	  	  	  	  	  	  	 INT,
 	  	  	 @DimensionX 	  	  	  	  	 FLOAT,
 	  	  	 @DimensionY 	  	  	  	  	 FLOAT,
 	  	  	 @DimensionZ 	  	  	  	  	 FLOAT,
 	  	  	 @DimensionA 	  	  	  	  	 FLOAT,
 	  	  	 @StartCoordX 	  	  	  	 REAL,
 	  	  	 @StartCoordY 	  	  	  	 REAL,
 	  	  	 @StartCoordZ 	  	  	  	 REAL,
 	  	  	 @StartCoordA 	  	  	  	 REAL,
 	  	  	 @StartTime 	  	  	  	  	 DATETIME,
 	  	  	 @Timestamp 	  	  	  	  	 DATETIME,
 	  	  	 @ParentComponentId 	 INT,
 	  	  	 @ExtendedInfo 	  	  	  	 nvarchar(255),
 	  	  	 @ComponentId 	  	  	  	 INT OUTPUT,
 	  	  	 @TransactionType 	  	 INT OUTPUT,
 	  	  	 @ChildUnitId 	  	  	  	 INT OUTPUT,
 	  	  	 @ParentEventId 	  	  	 INT OUTPUT,
 	  	  	 @ChildEventId 	  	  	  	 INT OUTPUT
AS
DECLARE 	 
 	  	  	 @RC 	  	  	  	  	  	  	 Int,
 	  	  	 @ESignatureId 	  	 Int
 	  	  	 
SET @ESignatureId = Null 	  	  	 
EXECUTE @RC = spSDK_IncomingGenealogy 	 @WriteDirect,@UpdateClientOnly,@ParentEventName,@ParentEventType,@ParentUnitName,
 	 @ParentLineName,@ChildEventName,@ChildEventType,@ChildUnitName,@ChildLineName,
 	 @UserId,@DimensionX,@DimensionY,@DimensionZ,@DimensionA,
 	 @StartCoordX,@StartCoordY,@StartCoordZ,@StartCoordA,@StartTime,
 	 @Timestamp,@ParentComponentId,@ExtendedInfo,@ComponentId OUTPUT,@TransactionType OUTPUT,
  @ESignatureId OUTPUT,@ChildUnitId OUTPUT,@ParentEventId OUTPUT, 	 @ChildEventId OUTPUT
RETURN(@RC)
