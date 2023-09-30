CREATE PROCEDURE dbo.spEM_IEImportWasteEventMeasure
@LineDesc 	  	  	 nVarchar (100),
@UnitDesc 	  	  	 nVarchar (100),
@WasteMesDesc  	  	 nVarChar(100),
@sConversion 	  	 nVarChar(100),
@ConversionLineDesc 	 nVarchar (100),
@ConversionUnitDesc 	 nVarchar (100),
@ConversionVarDesc 	 nVarchar (100),
@UserId 	  	  	  	 Int 	 
AS
Declare @UnitId 	  	 Int,
 	  	 @LineId 	  	 Int,
 	  	 @CUnitId 	 Int,
 	  	 @CLineId 	 Int,
 	  	 @CVarId 	  	 Int,
 	  	 @Conversion 	 Float,
 	  	 @WEMId 	  	 Int
 	  	 
SET @LineDesc =  LTrim(RTrim(@LineDesc))
SET @UnitDesc =  LTrim(RTrim(@UnitDesc))
SET @WasteMesDesc =  LTrim(RTrim(@WasteMesDesc))
SET @sConversion =  LTrim(RTrim(@sConversion))
SET @ConversionLineDesc =  LTrim(RTrim(@ConversionLineDesc))
SET @ConversionUnitDesc =  LTrim(RTrim(@ConversionUnitDesc))
SET @ConversionVarDesc =  LTrim(RTrim(@ConversionVarDesc))
IF @LineDesc = '' Set @LineDesc = Null
IF @UnitDesc = '' Set @UnitDesc = Null
IF @WasteMesDesc = '' Set @WasteMesDesc = Null
IF @sConversion = '' Set @sConversion = Null
IF @ConversionLineDesc = '' Set @ConversionLineDesc = Null
IF @ConversionUnitDesc = '' Set @ConversionUnitDesc = Null
IF @ConversionVarDesc = '' Set @ConversionVarDesc = Null
 	  	 
SELECT @LineId = PL_Id 
 	 FROM Prod_Lines WHERE PL_Desc = @LineDesc 
IF @LineId Is Null
BEGIN
 	 Select 'Failed - Production Line Not Found'
 	 Return(-100)
END
SELECT @UnitId = PU_Id 
 	 FROM Prod_Units WHERE PU_Desc = @UnitDesc and PL_Id = @LineId
IF @UnitId Is Null
BEGIN
 	 Select 'Failed - Production Unit Not Found'
 	 Return(-100)
END
If (@sConversion is null and @ConversionVarDesc Is Null)
 	 or (@sConversion is Not null and @ConversionVarDesc Is Not Null)
BEGIN
 	 Select 'Failed - Must define conversion OR conversion variable'
 	 Return(-100)
END 
If @sConversion is Not Null
BEGIN
 	 If isnumeric(@sConversion) = 0 
 	 Begin
 	  	 Select 'Failed - Conversion must be Numeric'
 	  	 Return(-100)
 	 End
 	 SET @Conversion = CONVERT(float,@sConversion)
 	 SET @CVarId = Null
END
ELSE
BEGIN
 	 SELECT @CLineId = PL_Id 
 	  	 FROM Prod_Lines WHERE PL_Desc = @ConversionLineDesc 
 	 IF @CLineId Is Null
 	 BEGIN
 	  	 Select 'Failed - Conversion Line Not Found'
 	  	 Return(-100)
 	 END
 	 SELECT @CUnitId = PU_Id 
 	  	 FROM Prod_Units WHERE PU_Desc = @ConversionUnitDesc and PL_Id = @CLineId
 	 IF @CUnitId Is Null
 	 BEGIN
 	  	 Select 'Failed - Conversion Unit Not Found'
 	  	 Return(-100)
 	 END
 	 SELECT @CVarId = Var_Id 
 	  	 FROM Variables WHERE Var_Desc = @ConversionVarDesc and Pu_Id = @CUnitId
 	 IF @CVarId Is Null
 	 BEGIN
 	  	 Select 'Failed - Conversion Unit Not Found'
 	  	 Return(-100)
 	 END
END
IF @WasteMesDesc Is Null
Begin
 	 Select 'Failed - Description is required'
 	 Return(-100)
End
SELECT @WEMId = a.WEMT_Id  
 	 FROM Waste_Event_Meas a
 	 WHERE a.WEMT_Name  = @WasteMesDesc and a.PU_Id = @UnitId
Declare @RC Int
EXECUTE @RC = spEMEC_UpdateWasteMeas @WEMId,@WasteMesDesc,@Conversion,@CVarId,@UnitId,@UserId
IF @WEMId IS NULL AND @WasteMesDesc IS NOT NULL
BEGIN
 	 SELECT @WEMId = WEMT_Id FROM Waste_Event_Meas WHERE PU_Id = @UnitId AND WEMT_Name = @WasteMesDesc
END
If @WEMId Is Null or @RC > 0
Begin
 	 Select 'Failed - Error Creating Waste Measure'
 	 Return (-100)
End
