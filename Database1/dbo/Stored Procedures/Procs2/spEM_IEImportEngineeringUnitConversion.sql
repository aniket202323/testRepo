CREATE PROCEDURE dbo.spEM_IEImportEngineeringUnitConversion
@ConvDesc 	  	  	 nvarchar(255),
@FromEngDesc 	 nvarchar(255),
@ToEngDesc 	  	 nvarchar(255),
@Slope 	  	  	  	 nvarchar(255),
@Intercept 	  	 nvarchar(255),
@CustSQL  	  	  	 nvarchar(1000),
@User_Id  	  	  	 Int
AS
Declare 	 @FromEngId 	  	 Int,
 	  	  	  	 @ToEngId 	  	  	 Int,
 	  	  	  	 @fSlope 	  	  	  	 Float,
 	  	  	  	 @fIntercept 	  	 Float,
 	  	  	  	 @ConvId 	  	  	  	 Int,
 	  	  	  	 @Rc 	  	  	  	  	  	 Int
Select @ConvDesc = LTrim(RTrim(@ConvDesc))
Select @FromEngDesc = LTrim(RTrim(@FromEngDesc))
Select @ToEngDesc = LTrim(RTrim(@ToEngDesc))
Select @Slope = LTrim(RTrim(@Slope))
Select @Intercept = LTrim(RTrim(@Intercept))
Select @CustSQL = LTrim(RTrim(@CustSQL))
If @ConvDesc = '' Select @ConvDesc = null
If @FromEngDesc = '' Select @FromEngDesc = null
If @ToEngDesc = '' Select @ToEngDesc = null
If @Slope = '' Select @Slope = null
If @Intercept = '' Select @Intercept = null
If @CustSQL = '' Select @CustSQL = null
/*Check From Desc*/
If @ConvDesc IS NULL
    Begin
      Select 'Failed - Conversion Description is missing'
      RETURN (-100)
    End
Select @ConvId = Eng_Unit_Conv_Id 
 	 From Engineering_Unit_Conversion
  Where Conversion_Desc = @ConvDesc
If @ConvId IS Not NULL 
    Begin
      Select 'Failed - conversion alread exists'
      RETURN (-100)
 	   End
If @FromEngDesc IS NULL
    Begin
      Select 'Failed - From engineering unit code missing'
      RETURN (-100)
    End
Select @FromEngId = Eng_Unit_Id 
 	 From Engineering_Unit
  Where Eng_Unit_Code = @FromEngDesc
If @FromEngId IS NULL 
    Begin
      Select 'Failed - From engineering unit code not found'
      RETURN (-100)
 	   End
/*Check To Desc*/
If @ToEngDesc IS NULL
    Begin
      Select 'Failed - To engineering unit code missing'
      RETURN (-100)
    End
Select @ToEngId = Eng_Unit_Id 
 	 From Engineering_Unit
  Where Eng_Unit_Code = @ToEngDesc
If @ToEngId IS NULL 
    Begin
      Select 'Failed - To engineering unit code not found'
      RETURN (-100)
 	   End
Select @ConvId = Eng_Unit_Conv_Id 
 	 From Engineering_Unit_Conversion
  Where To_Eng_Unit_Id = @ToEngId and From_Eng_Unit_Id = @FromEngId
If @ConvId IS Not NULL 
    Begin
      Select 'Failed - conversion alread exists'
      RETURN (-100)
 	   End
If isnumeric(@Slope) = 0 and @Slope is not null
 	 Begin
    	 Select 'Failed - Slope is not correct'
    	 RETURN (-100)
   End
Select @fSlope = Convert(float,@Slope)
If isnumeric(@Intercept) = 0 and @Intercept is not null
 	 Begin
    	 Select 'Failed - Intercept is not correct'
    	 RETURN (-100)
   End
Select @fIntercept = Convert(float,@Intercept)
IF @fIntercept Is Null and @fSlope Is Not Null
Begin
 	 Select 'Failed - Must have intercept if using slope'
 	 RETURN (-100)
End
IF @fIntercept Is Not Null and @fSlope Is Null
Begin
 	 Select 'Failed - Must have slope if using intercept'
 	 RETURN (-100)
End
Execute spEM_EUCreateConversion @ConvDesc,@FromEngId,@ToEngId,@fSlope,@fIntercept,@CustSQL,@User_Id,@ConvId output
If @ConvId is null
 	 Begin
    	 Select 'Failed - could not create conversion'
    	 RETURN (-100)
   End
RETURN(0)
