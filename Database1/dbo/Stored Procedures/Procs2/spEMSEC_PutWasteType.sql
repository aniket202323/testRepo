Create Procedure dbo.spEMSEC_PutWasteType
 	 @WETName nVarChar(100),
 	 @ReadOnly Bit,
 	 @UserId int,
 	 @WETId int OUTPUT
AS
Declare @RC Int
EXECUTE @RC = spEMEC_UpdateWasteTypes @WETId,@WETName,@ReadOnly,@UserId
IF @WETId IS NULL AND @WETName IS NOT NULL
BEGIN
 	 SELECT @WETId = WET_Id FROM Waste_Event_Type WHERE  WET_Name = @WETName
END
SELECT @RC = isnull(@RC,0)
RETURN(@RC)
