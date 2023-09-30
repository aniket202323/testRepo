CREATE FUNCTION dbo.fnCmn_ConvertEngUnit(@FromENGUnit nVarChar(15),@ToENGUnit nVarChar(15),@Value nVarChar(25),@Percision Int) 
 	 Returns nVarChar(25)
AS 
BEGIN
 	 DECLARE @RVFloat FLOAT
 	 Declare @ToId 	 Int,@FromId Int,@Slope Float,@Intercept Float
 	 Declare @ReturnValue nVarChar(25)
 	 SELECT @ReturnValue = @Value
 	 IF (IsNumeric(@Value) = 0) Or @Percision Is Null
 	  	 Return @Value
 	 SELECT @RVFloat = CONVERT(FLOAT,@Value)
 	 IF (@ToENGUnit Is Null) Or (@FromENGUnit Is Null)
 	  	 GOTO ExitSP
 	 IF @ToENGUnit = @FromENGUnit
 	  	 GOTO ExitSP
 	 Select @ToId = Eng_Unit_Id
 	 From Engineering_Unit
 	 Where Eng_Unit_Code = @ToENGUnit
 	 If @ToId Is Null
 	  	 GOTO ExitSP
 	 Select @FromId = Eng_Unit_Id
 	 From Engineering_Unit
 	 Where Eng_Unit_Code = @FromENGUnit
 	 If @FromId Is Null
 	  	 GOTO ExitSP
 	 Select @Slope = Slope,@Intercept = Intercept
 	  	 From Engineering_Unit_Conversion
 	  	 Where From_Eng_Unit_Id = @FromId And To_Eng_Unit_Id = @ToId 	  	  	  	 
 	 IF @Slope is not null
 	 BEGIN
 	  	 Select  @ReturnValue = @RVFloat * @Slope + IsNull(@Intercept,0.0)
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select  @ReturnValue = @RVFloat + IsNull(@Intercept,0.0)
 	 END
ExitSP:
 	 If @Percision = 0 or @Percision Is Null 
 	  	 RETURN Cast(@RVFloat as Decimal(25,0))
 	 Else If @Percision =  1 
 	  	 RETURN Cast(@RVFloat as Decimal(25,1))
 	 Else If @Percision =  3 
 	  	 RETURN Cast(@RVFloat as Decimal(25,3))
 	 Else If @Percision =  4 
 	  	 RETURN Cast(@RVFloat as Decimal(25,4))
 	 Else If @Percision =  5 
 	  	 RETURN Cast(@RVFloat as Decimal(25,5))
 	 Else If @Percision =  6
 	  	 RETURN Cast(@RVFloat as Decimal(25,6))
 	 Else
 	  	 RETURN Cast(@RVFloat as Decimal(25,2))
RETURN Cast(@RVFloat as Decimal(25,2))
END
