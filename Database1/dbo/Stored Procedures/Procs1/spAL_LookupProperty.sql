Create Procedure dbo.spAL_LookupProperty
  @VS_Id int,
  @Property_Desc nvarchar(100) OUTPUT,
  @LCL 	  	  	  nvarchar(25) = Null OUTPUT,
  @TCL 	  	  	  nvarchar(25) = Null OUTPUT,
  @UCL 	  	  	  nvarchar(25)= Null OUTPUT ,
  @TestFreq 	  	  Int = 0 OUTPUT
As
  Declare @PropertyDesc nvarchar(50),
          @SpecDesc nvarchar(50),
 	  	  	 @VarId Int
Select @PropertyDesc = pp.Prop_Desc, @SpecDesc = s.Spec_Desc
  From Var_Specs vs
  Join Active_Specs a on a.AS_Id = vs.AS_Id
  Join Specifications s on s.Spec_Id = a.Spec_Id
  Join Product_Properties pp on pp.Prop_Id = s.Prop_Id
  Where vs.VS_Id = @VS_Id
If @PropertyDesc is NULL
  Select @PropertyDesc = 'No Property'
If @SpecDesc is NULL
  Select @SpecDesc = 'No Specification'
Select @Property_Desc = @PropertyDesc + '\' + @SpecDesc
SELECT 	 @LCL = L_Control,
 	  	 @TCL = T_Control,
 	  	 @UCL = U_Control,
 	  	 @TestFreq = Test_Freq,
 	  	 @VarId =Var_Id
 	 FROM var_Specs
  Where VS_Id = @VS_Id
IF @TestFreq Is Null
BEGIN
 	 SELECT @TestFreq = Sampling_Interval
 	  FROM Variables Where Var_Id = @VarId and Event_Type = 1
END
