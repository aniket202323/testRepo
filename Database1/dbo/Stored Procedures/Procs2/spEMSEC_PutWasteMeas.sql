Create Procedure dbo.spEMSEC_PutWasteMeas
 	 @WEMTName nVarChar(100),
 	 @Conversion real,
 	 @ConversionSpec int,
 	 @PUId int,
 	 @UserId int,
 	 @WEMTId int OUTPUT
AS
Declare @RC Int
EXECUTE @RC = spEMEC_UpdateWasteMeas @WEMTId,@WEMTName,@Conversion,@ConversionSpec,@PUId,@UserId
IF @WEMTId IS NULL AND @WEMTName IS NOT NULL
BEGIN
 	 SELECT @WEMTId = WEMT_Id FROM Waste_Event_Meas WHERE PU_Id = @PUId AND WEMT_Name = @WEMTName
END
SELECT @RC = isnull(@RC,0)
RETURN(@RC)
