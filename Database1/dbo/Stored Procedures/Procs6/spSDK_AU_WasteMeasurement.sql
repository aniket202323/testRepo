CREATE procedure [dbo].[spSDK_AU_WasteMeasurement]
@AppUserId int,
@Id int OUTPUT,
@Conversion real ,
@ConversionSpec int ,
@Department varchar(200) ,
@DepartmentId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@WasteMeasurement varchar(100) 
AS
DECLARE @ReturnCode 	  	  	 Int
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
IF @Id IS NOT Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Waste_Event_Meas WHERE WEMT_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Waste Event Measure not found for update'
 	  	 RETURN(-100)
 	 END
 	 --SELECT @ConversionSpec = Conversion_Spec
 	  	 --FROM Waste_Event_Meas
 	  	 --WHERE WEMT_Id = @Id 
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Waste_Event_Meas WHERE PU_Id = @ProductionUnitId and WEMT_Name = @WasteMeasurement)
 	 BEGIN
 	  	 SELECT 'Waste Event Measure already exists cannot add'
 	  	 RETURN(-100)
 	 END
END
EXECUTE @ReturnCode = spEMEC_UpdateWasteMeas 	 @Id,@WasteMeasurement,@Conversion,@ConversionSpec,@ProductionUnitId,@AppUserId
IF @ReturnCode > 0
BEGIN
 	 SELECT 'Add/Update failed'
 	 Return (-100)
END
Select @Id = WEMT_Id from Waste_Event_Meas WHERE PU_Id = @ProductionUnitId and WEMT_Name = @WasteMeasurement
If (@Id Is NULL)
 	 Begin
 	  	 SELECT 'Add/Update failed'
 	  	 Return (-100)
 	 End
 	 
RETURN(1)
