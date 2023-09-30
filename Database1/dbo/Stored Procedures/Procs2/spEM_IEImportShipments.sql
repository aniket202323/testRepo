CREATE PROCEDURE dbo.spEM_IEImportShipments
@ShipmentNumber 	  	 nvarchar(50),
@CarrierType  	  	 nVarChar(10),
@CarrierCode 	  	 nvarchar(50),
@VehicleName 	  	 nvarchar(50),
@ShipmentDate 	  	 nvarchar(25),
@ArrivalDate 	  	 nvarchar(25),
@CompleteDate 	  	 nvarchar(25),
@COADate 	  	  	 nvarchar(25),
@Active 	  	  	  	 nVarChar(10),
@In_User_Id  	  	 int
As
Select @ShipmentNumber 	 = Ltrim(Rtrim(@ShipmentNumber))
Select @CarrierType 	  	 = Ltrim(Rtrim(@CarrierType))
Select @CarrierCode 	  	 = Ltrim(Rtrim(@CarrierCode))
Select @VehicleName 	  	 = Ltrim(Rtrim(@VehicleName))
Select @ShipmentDate 	 = Ltrim(Rtrim(@ShipmentDate))
Select @ArrivalDate 	  	 = Ltrim(Rtrim(@ArrivalDate))
Select @CompleteDate 	 = Ltrim(Rtrim(@CompleteDate))
Select @COADate 	  	  	 = Ltrim(Rtrim(@COADate))
Select @Active 	  	  	 = Ltrim(Rtrim(@Active))
If @ShipmentNumber = '' 	 Select @ShipmentNumber = Null
If @CarrierType = '' 	 Select @CarrierType = Null
If @CarrierCode = ''  	 Select @CarrierCode = Null
If @VehicleName = ''  	 Select @VehicleName = Null
If @ShipmentDate = ''  	 Select @ShipmentDate = Null
If @ArrivalDate = ''  	 Select @ArrivalDate = Null
If @CompleteDate = ''  	 Select @CompleteDate = Null
If @COADate = ''  	  	 Select @COADate = Null
If @Active = ''  	  	 Select @Active = Null
Declare @IsActive 	 bit,
 	  	 @ShipmentId 	 Int,
 	  	 @Now 	  	 DateTime,
 	  	 @SDate 	  	 DateTime,
 	  	 @ADate 	  	 DateTime,
 	  	 @CODate 	  	 DateTime,
 	  	 @CDate 	  	 DateTime
/*  Non nullable
Order_Type
Order_Status
Customer_Order_Number
Plant_Order_Number
Customer_Id 
*/
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
If  @ShipmentNumber is null --Plant_Order_Number
  Begin
 	 Select  'Shipment Number Not Found'
 	 Return(-100)
  End
If @ShipmentDate is null 
  Begin
 	 Select  'Shipment Date Not Found'
 	 Return(-100)
  End
If @ShipmentDate is not Null
BEGIN
 	 If Len(@ShipmentDate) <> 14 
 	 BEGIN
 	  	 Select 'Failed - Shipment Date not correct format'
 	  	 Return (-100)
 	 END
 	 SELECT @SDate = 0
 	 SELECT @SDate = DateAdd(year,convert(int,substring(@ShipmentDate,1,4)) - 1900,@SDate)
 	 SELECT @SDate = DateAdd(month,convert(int,substring(@ShipmentDate,5,2)) - 1,@SDate)
 	 SELECT @SDate = DateAdd(day,convert(int,substring(@ShipmentDate,7,2)) - 1,@SDate)
 	 SELECT @SDate = DateAdd(hour,convert(int,substring(@ShipmentDate,9,2)) ,@SDate)
 	 SELECT @SDate = DateAdd(minute,convert(int,substring(@ShipmentDate,11,2)),@SDate)
END
 	 
IF @ArrivalDate is not Null
BEGIN
 	 If Len(@ArrivalDate) <> 14 
 	 BEGIN
 	  	 Select 'Failed - Arrival Date not correct format'
 	  	 Return (-100)
 	 END
 	 SELECT @ADate = 0
 	 SELECT @ADate = DateAdd(year,convert(int,substring(@ArrivalDate,1,4)) - 1900,@ADate)
 	 SELECT @ADate = DateAdd(month,convert(int,substring(@ArrivalDate,5,2)) - 1,@ADate)
 	 SELECT @ADate = DateAdd(day,convert(int,substring(@ArrivalDate,7,2)) - 1,@ADate)
 	 SELECT @ADate = DateAdd(hour,convert(int,substring(@ArrivalDate,9,2)) ,@ADate)
 	 SELECT @ADate = DateAdd(minute,convert(int,substring(@ArrivalDate,11,2)),@ADate)
END
If @CompleteDate is not Null
BEGIN
 	 If Len(@CompleteDate) <> 14 
 	 BEGIN
 	  	 Select 'Failed - Complete Date not correct format'
 	  	 Return (-100)
 	 END
 	 SELECT @CDate = 0
 	 SELECT @CDate = DateAdd(year,convert(int,substring(@CompleteDate,1,4)) - 1900,@CDate)
 	 SELECT @CDate = DateAdd(month,convert(int,substring(@CompleteDate,5,2)) - 1,@CDate)
 	 SELECT @CDate = DateAdd(day,convert(int,substring(@CompleteDate,7,2)) - 1,@CDate)
 	 SELECT @CDate = DateAdd(hour,convert(int,substring(@CompleteDate,9,2)) ,@CDate)
 	 SELECT @CDate = DateAdd(minute,convert(int,substring(@CompleteDate,11,2)),@CDate)
END
If @COADate is not Null
BEGIN
 	 If Len(@COADate) <> 14 
 	 BEGIN
 	  	 Select 'Failed - Actual Manufacturing date not correct format'
 	  	 Return (-100)
 	 END
 	 SELECT @CODate = 0
 	 SELECT @CODate = DateAdd(year,convert(int,substring(@COADate,1,4)) - 1900,@CODate)
 	 SELECT @CODate = DateAdd(month,convert(int,substring(@COADate,5,2)) - 1,@CODate)
 	 SELECT @CODate = DateAdd(day,convert(int,substring(@COADate,7,2)) - 1,@CODate)
 	 SELECT @CODate = DateAdd(hour,convert(int,substring(@COADate,9,2)) ,@CODate)
 	 SELECT @CODate = DateAdd(minute,convert(int,substring(@COADate,11,2)),@CODate)
END
If @Active = 'Yes' or @Active = 'TRUE' Or @Active = '1'
 	 Select  @IsActive = 1
Else
 	 Select  @IsActive = 0
Select @ShipmentId = Shipment_Id From Shipment
  Where Shipment_Number = @ShipmentNumber
/* If doesn't exist then create */
If @ShipmentId Is Null
  Begin
 	 Insert into Shipment (Is_Active,Shipment_Date,Arrival_Date,Carrier_Code,Carrier_Type,Vehicle_Name,Shipment_Number,Complete_Date,COA_Date)
 	  	 Values(@IsActive,@SDate,@ADate,@CarrierCode,@CarrierType,@VehicleName,@ShipmentNumber,@CDate,@CODate)
 	 Select @ShipmentId = Scope_Identity()
  End
Else
 	 Update Shipment set Is_Active = @IsActive,Shipment_Date = @SDate,Arrival_Date = @ADate,Carrier_Code = @CarrierCode,Carrier_Type = @CarrierType,
 	  	 Vehicle_Name = @VehicleName,Shipment_Number = @ShipmentNumber, Complete_Date = @CDate,COA_Date = @CODate Where Shipment_Id = @ShipmentId
If @ShipmentId is null
  Begin
 	 Select 'Failed - could not create shipment'
 	 Return (-100)
  End
Return(0)
