CREATE PROCEDURE dbo.spEM_IEImportVarSpecs
 	 @PL_Desc  	  	  	 nvarchar(50),
 	 @PU_Desc  	  	  	 nvarchar(50),
 	 @Var_Desc  	  	  	 nvarchar(50),
 	 @Central  	  	  	 nVarChar(10),
 	 @Prod_Code  	  	  	 nvarchar(25),
 	 @L_Entry  	  	  	 nvarchar(25),
 	 @OL_Entry  	  	  	 nVarChar(10),
 	 @L_Reject  	  	  	 nvarchar(25),
 	 @OL_Reject  	  	  	 nVarChar(10),
 	 @L_Warning  	  	  	 nvarchar(25),
 	 @OL_Warning  	  	  	 nVarChar(10),
 	 @L_User  	  	  	 nvarchar(25),
 	 @OL_User  	  	  	 nVarChar(10),
 	 @Target  	  	  	 nvarchar(25),
 	 @OTarget  	  	  	 nVarChar(10),
 	 @U_User 	  	  	   	 nvarchar(25),
 	 @OU_User 	  	  	 nVarChar(10),
 	 @U_Warning  	  	  	 nvarchar(25),
 	 @OU_Warning  	  	  	 nVarChar(10),
 	 @U_Reject  	  	  	 nvarchar(25),
 	 @OU_Reject  	  	  	 nVarChar(10),
 	 @U_Entry  	  	  	 nvarchar(25),
 	 @OU_Entry  	  	  	 nVarChar(10),
 	 @Test_Freq_Str 	  	  	 nvarchar(25),
 	 @OTest_Freq_Str 	  	  	 nVarChar(10),
 	 @ESigLevel 	  	  	 nvarchar(50),
 	 @OESigLevel 	  	  	 nVarChar(10),
 	 @L_Control 	  	  	 nvarchar(25),
 	 @OL_Control 	  	  	 nVarChar(10),
 	 @T_Control 	  	  	 nvarchar(25),
 	 @OT_Control 	  	  	 nVarChar(10),
 	 @U_Control 	  	  	 nvarchar(25),
 	 @OU_Control 	  	  	 nVarChar(10),
 	 @User_Id 	  	  	 Int,
 	 @Trans_Id 	  	  	 Int
AS
Declare 	 @PU_Id  	  	 int,
 	 @Prod_Id  	 int,
 	 @Var_Id  	 int,
 	 @PL_Id  	  	 int,
 	 @MasterUnit  	 int,
 	 @Test_Freq 	 int,
 	 @Spec 	   	 int,
 	 @Spec_Total 	 int,
 	 @Value_String 	 nvarchar(30),
 	 @Value 	  	 float,
 	 @Last_Value 	 float,
 	 @iESigLevel 	 Int,
 	 @DT 	  	 Int,
 	 @iCentral 	 Int,
 	 @iOLE 	  	 Int,
 	 @iOLR 	  	 Int,
 	 @iOLW 	  	 Int,
 	 @iOLU 	  	 Int,
 	 @iOT 	  	 Int,
 	 @iOUU 	  	 Int,
 	 @iOUW 	  	 Int,
 	 @iOUR 	  	 Int,
 	 @iOUE 	  	 Int,
 	 @iOTF 	  	 Int,
 	 @iOES 	  	 Int,
 	 @iOLC 	  	 Int,
 	 @iOTC 	  	 Int,
 	 @iOUC 	  	 Int,
 	 @iCLE 	  	 Int,
 	 @iCLR 	  	 Int,
 	 @iCLW 	  	 Int,
 	 @iCLU 	  	 Int,
 	 @iCT 	  	 Int,
 	 @iCUU 	  	 Int,
 	 @iCUW 	  	 Int,
 	 @iCUR 	  	 Int,
 	 @iCUE 	  	 Int,
 	 @iCTF 	  	 Int,
 	 @iCES 	  	 Int,
 	 @iCLC 	  	 Int,
 	 @iCTC 	  	 Int,
 	 @iCUC 	  	 Int,
 	 @iOverRideCount 	 Int,
 	 @iCOverRideCount Int,
 	 @Now  	  	 DateTime,
 	 @RemoveOveride 	 Int,
 	 @SpecId 	  	 Int,
 	 @EqualLimits 	 Int
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Select  	 @Prod_Id  	  	 = Null,
 	  	 @Spec 	  	  	 = 0,
 	  	 @Spec_Total 	  	 = 9
SELECT @EqualLimits = Value
 	 FROM Site_Parameters
 	 WHERE Parm_Id = 88 and HostName = ''
SET @EqualLimits = Coalesce(@EqualLimits,0)
/*****************************************************************************************************
*                            Clean Arguments 	  	  	  	  	  	   *
*****************************************************************************************************/
Select  	 @Prod_Code 	  	 = LTrim(RTrim(@Prod_Code)),
 	 @PL_Desc 	  	 = LTrim(RTrim(@PL_Desc)),
 	 @PU_Desc 	  	 = LTrim(RTrim(@PU_Desc)),
 	 @Var_Desc 	  	 = LTrim(RTrim(@Var_Desc)),
 	 @L_Entry 	  	 = LTrim(RTrim(@L_Entry)),
 	 @L_Reject 	  	 = LTrim(RTrim(@L_Reject)),
 	 @L_Warning 	  	 = LTrim(RTrim(@L_Warning)),
 	 @L_User 	  	  	 = LTrim(RTrim(@L_User)),
 	 @Target 	  	  	 = LTrim(RTrim(@Target)),
 	 @U_User 	  	  	 = LTrim(RTrim(@U_User)),
 	 @U_Warning 	  	 = LTrim(RTrim(@U_Warning)),
 	 @U_Reject  	  	 = LTrim(RTrim(@U_Reject)),
 	 @U_Entry  	  	 = LTrim(RTrim(@U_Entry)),
 	 @L_Control  	  	 = LTrim(RTrim(@L_Control)),
 	 @T_Control  	  	 = LTrim(RTrim(@T_Control)),
 	 @U_Control  	  	 = LTrim(RTrim(@U_Control)),
 	 @Test_Freq_Str  	  	 = LTrim(RTrim(@Test_Freq_Str)),
 	 @ESigLevel  	  	 = LTrim(RTrim(@ESigLevel)),
 	 @OL_Entry 	  	 = LTrim(RTrim(@OL_Entry)),
 	 @OL_Reject 	  	 = LTrim(RTrim(@OL_Reject)),
 	 @OL_Warning 	  	 = LTrim(RTrim(@OL_Warning)),
 	 @OL_User 	  	 = LTrim(RTrim(@OL_User)),
 	 @OTarget 	  	 = LTrim(RTrim(@OTarget)),
 	 @OU_User 	  	 = LTrim(RTrim(@OU_User)),
 	 @OU_Warning 	  	 = LTrim(RTrim(@OU_Warning)),
 	 @OU_Reject  	  	 = LTrim(RTrim(@OU_Reject)),
 	 @OU_Entry  	  	 = LTrim(RTrim(@OU_Entry)),
 	 @OL_Control  	  	 = LTrim(RTrim(@OL_Control)),
 	 @OT_Control  	  	 = LTrim(RTrim(@OT_Control)),
 	 @OU_Control  	  	 = LTrim(RTrim(@OU_Control)),
 	 @OTest_Freq_Str  	 = LTrim(RTrim(@OTest_Freq_Str)),
 	 @OESigLevel  	  	 = LTrim(RTrim(@OESigLevel))
/*****************************************************************************************************
*                            Validate Arguments 	  	  	  	  	  	   *
*****************************************************************************************************/
If @L_Entry = ''     	 Select @L_Entry = Null
If @L_Reject = ''    	 Select @L_Reject = Null
If @L_Warning = ''   	 Select @L_Warning = Null
If @L_User = ''      	 Select @L_User = Null
If @Target = ''      	 Select @Target = Null
If @U_User = ''      	 Select @U_User = Null
If @U_Warning = ''   	 Select @U_Warning = Null
If @U_Reject = ''    	 Select @U_Reject = Null
If @U_Entry = ''     	 Select @U_Entry = Null
If @L_Control = ''   	 Select @L_Control = Null
If @T_Control = ''   	 Select @T_Control = Null
If @U_Control = ''   	 Select @U_Control = Null
If @Test_Freq_Str = '' Or @Test_Freq_Str Is Null
     Select @Test_Freq = -1
Else
  BEGIN
    If IsNumeric(@Test_Freq_Str) = 0
       BEGIN
         Select 'Failed - Test Freq must be a numeric value'
         RETURN (-100)
       END
    Else
       Select @Test_Freq = convert(int, @Test_Freq_Str)
   END
If IsNumeric(@Central) = 0
       BEGIN
         Select 'Failed - Central Spec must be true or false'
         RETURN (-100)
       END
If @Central = '0' 
 	 Select @iCentral = 0
Else
 	 Select @iCentral = 1
If @ESigLevel = '' or @ESigLevel Is null
 	 Select @iESigLevel = -1
Else
  BEGIN
 	 Select @iESigLevel = Case @ESigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 When 'Undefined' 	 Then -1
 	  	  	  	  	  	  	 Else -2
 	  	  	  	  	  	  END
 	 If @iESigLevel = -2 
 	   BEGIN
         Select 'Failed - ESignature not correct'
         RETURN (-100)
 	   END
  END
/*****************************************************************************************************
*                            Get plant model ids and product id 	  	  	  	   *
*****************************************************************************************************/
Select @Prod_Id = Prod_Id 
From Products 
Where Prod_Code = @Prod_Code
If @Prod_Id Is Null
  BEGIN
     Select 'Failed - Could not find product code'
     Return (-100)
  END
Select @PL_Id = PL_Id
  From Prod_Lines Where PL_Desc = @PL_Desc
If @PL_Id Is Null 
  BEGIN
     Select 'Failed - Could not find production line'
     Return (-100)
  END
Select @PU_Id = PU_Id, @MasterUnit = Coalesce(Master_Unit, PU_Id)
 From Prod_Units Where PU_Desc = @PU_Desc and PL_Id = @PL_Id
If @PU_Id Is Null 
  BEGIN
     Select 'Failed - Could not find production Unit'
     Return (-100)
  END
If (Select Count(*) From PU_Products Where pu_Id =  @MasterUnit and Prod_Id = @Prod_Id) = 0 
  BEGIN
     Select 'Failed - Product Not active on given unit'
     Return (-100)
  END
Select @Var_Id = Var_Id,@DT = Data_Type_Id,@SpecId = Spec_Id
 From Variables Where Var_Desc = @Var_Desc and PU_Id = @PU_Id
If @Var_Id Is Null
  BEGIN
     Select 'Failed - Could not find variable'
     Return (-100)
  END
IF @SpecId Is NULL and @iCentral = 1 
BEGIN
 	 Select 'Failed - Variable is Not central spec in database'
 	 Return (-100)
END
IF @SpecId Is Not NULL and @iCentral = 0 
BEGIN
 	 Select 'Failed - Variable is central spec in database'
 	 Return (-100)
END
If @iCentral = 1
BEGIN
 	 If IsNumeric(@OL_Entry) = 0
 	 BEGIN
 	  	 Select 'Failed - LE Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OL_Entry = '0' 
 	 BEGIN
 	  	 Select @iOLE = 0
 	  	 Select @L_Entry = Null
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOLE = 1
 	  	 Select @L_Entry = IsNull(@L_Entry,'')
 	 END
 	 If IsNumeric(@OL_Reject) = 0
 	 BEGIN
 	  	 Select 'Failed - LR Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OL_Reject = '0' 
 	 BEGIN
 	  	 Select @iOLR = 0
 	  	 Select @L_Reject = Null
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOLR = 1
 	  	 Select @L_Reject = IsNull(@L_Reject,'')
 	 END
 	 If IsNumeric(@OL_Warning) = 0
 	 BEGIN
 	  	 Select 'Failed - LW Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OL_Warning = '0' 
 	 BEGIN
 	  	 Select @L_Warning = Null
 	  	 Select @iOLW = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOLW = 1
 	  	 Select @L_Warning = IsNull(@L_Warning,'')
 	 END
 	 If IsNumeric(@OL_User) = 0
 	 BEGIN
 	  	 Select 'Failed - LU Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OL_User = '0' 
 	 BEGIN
 	  	 Select @L_User = Null
 	  	 Select @iOLU = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOLU = 1
 	  	 Select @L_User = IsNull(@L_User,'')
 	 END
 	 If IsNumeric(@OTarget) = 0
 	 BEGIN
 	  	 Select 'Failed - TGT Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OTarget = '0' 
 	 BEGIN
 	  	 Select @Target = Null
 	  	 Select @iOT = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOT = 1
 	  	 Select @Target = IsNull(@Target,'')
 	 END
 	 If IsNumeric(@OU_User) = 0
 	 BEGIN
 	  	 Select 'Failed - UU Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OU_User = '0' 
 	 BEGIN
 	  	 Select @U_User = Null
 	  	 Select @iOUU = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOUU = 1
 	  	 Select @U_User = IsNull(@U_User,'')
 	 END
 	 If IsNumeric(@OU_Warning) = 0
 	 BEGIN
 	  	 Select 'Failed - UW Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OU_Warning = '0' 
 	 BEGIN
 	  	 Select @U_Warning = Null
 	  	 Select @iOUW = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOUW = 1
 	  	 Select @U_Warning = IsNull(@U_Warning,'')
 	 END
 	 If IsNumeric(@OU_Reject) = 0
 	 BEGIN
 	  	 Select 'Failed - UR Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OU_Reject = '0' 
 	 BEGIN
 	  	 Select @U_Reject = Null
 	  	 Select @iOUR = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOUR = 1
 	  	 Select @U_Reject = IsNull(@U_Reject,'')
 	 END
 	 If IsNumeric(@OU_Entry) = 0
 	 BEGIN
 	  	 Select 'Failed - UE Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OU_Entry = '0' 
 	 BEGIN
 	  	 Select @U_Entry = Null
 	  	 Select @iOUE = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOUE = 1
 	  	 Select @U_Entry = IsNull(@U_Entry,'')
 	 END
 	 If IsNumeric(@OL_Control) = 0
 	 BEGIN
 	  	 Select 'Failed - LC Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OL_Control = '0' 
 	 BEGIN
 	  	 Select @L_Control = Null
 	  	 Select @iOLC = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOLC = 1
 	  	 Select @L_Control = IsNull(@L_Control,'')
 	 END
 	 If IsNumeric(@OT_Control) = 0
 	 BEGIN
 	  	 Select 'Failed - TC Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OT_Control = '0' 
 	 BEGIN
 	  	 Select @T_Control = Null
 	  	 Select @iOTC = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOTC = 1
 	  	 Select @T_Control = IsNull(@T_Control,'')
 	 END
 	 If IsNumeric(@OU_Control) = 0
 	 BEGIN
 	  	 Select 'Failed - UC Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OU_Control = '0' 
 	 BEGIN
 	  	 Select @U_Control = Null
 	  	 Select @iOUC = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOUC = 1
 	  	 Select @U_Control = IsNull(@U_Control,'')
 	 END
 	 If IsNumeric(@OTest_Freq_Str) = 0
 	 BEGIN
 	  	 Select 'Failed - Fx Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OTest_Freq_Str = '0' 
 	 BEGIN
 	  	 SELECT @Test_Freq = Null
 	  	 Select @iOTF = 0
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOTF = 1
 	 END
 	 If IsNumeric(@OESigLevel) = 0
 	 BEGIN
 	  	 Select 'Failed - Esig Central Spec Override must be true or false'
 	  	 RETURN (-100)
 	 END
 	 If @OESigLevel = '0' 
 	 BEGIN
 	  	 Select @iOES = 0
 	  	 SELECT @iESigLevel = Null
 	 END
 	 Else
 	 BEGIN
 	  	 Select @iOES = 1
 	 END
 	 Select @iOverRideCount = @iOLE + @iOLR + @iOLW + @iOLU + @iOT + @iOUU + @iOUW + @iOUR + @iOUE + @iOTF + @iOES + @iOLC + @iOTC + @iOUC
 	 
 	 SELECT  	 @iCLE = Case When Is_Defined & 1 = 1 Then 1 Else 0 END,
 	  	 @iCLR = Case When Is_Defined & 2 = 2 Then 1 Else 0 END,
 	  	 @iCLW = Case When Is_Defined & 4 = 4 Then 1 Else 0 END,
 	  	 @iCLU = Case When Is_Defined & 8 = 8 Then 1 Else 0 END,
 	  	 @iCT = Case When Is_Defined & 16 = 16 Then 1 Else 0 END,
 	  	 @iCUU = Case When Is_Defined & 32 = 32 Then 1 Else 0 END,
 	  	 @iCUW = Case When Is_Defined & 64 = 64 Then 1 Else 0 END,
 	  	 @iCUR = Case When Is_Defined & 128 = 128 Then 1 Else 0 END,
 	  	 @iCUE = Case When Is_Defined & 256 = 256 Then 1 Else 0 END,
 	  	 @iCTF = Case When Is_Defined & 512 = 512 Then 1 Else 0 END,
 	  	 @iCES = Case When Is_Defined & 1024 = 1024 Then 1 Else 0 END,
 	  	 @iCLC = Case When Is_Defined & 8192 = 8192 Then 1 Else 0 END,
 	  	 @iCTC = Case When Is_Defined & 16384 = 16384 Then 1 Else 0 END,
 	  	 @iCUC = Case When Is_Defined & 32768 = 32768 Then 1 Else 0 END
 	  	 From Var_Specs vs
 	  	 Where  (vs.Var_Id  = @Var_Id ) and (vs.Prod_Id = @Prod_Id)and (Effective_Date <  @Now)  and (Expiration_Date >  @Now or Expiration_Date is null)
 	 SELECT @iCOverRideCount = @iCLE + @iCLR + @iCLW + @iCLU + @iCT + @iCUU + @iCUW + @iCUR + @iOUE + @iCTF + @iCES + @iCLC + @iCTC + @iCUC
 	 SELECT @iCOverRideCount = isnull(@iCOverRideCount,0)
 	 If @iOverRideCount = 0 AND @iCOverRideCount = 0
 	 BEGIN
 	  	 Select 'No OverRides Found to import'
 	  	 RETURN (-100)
 	 END
 	 Select @RemoveOveride = 0
 	 If @iCLE = 1 and @iOLE = 0
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 1
 	 END
 	 If @iCLR = 1 and @iOLR = 0
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 2
 	 END
 	 If @iCLW = 1 and @iOLW = 0
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 4
 	 END
 	 If @iCLU = 1 and @iOLU = 0
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 8
 	 END
 	 If @iCT = 1 and @iOT = 0
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 16
 	 END
 	 If @iCUU = 1 and @iOUU = 0
 	 BEGIN
 	  	  Select @RemoveOveride = @RemoveOveride + 32
 	 END
 	 If @iCUW = 1 and @iOUW = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 64
 	 END
 	 If @iCUR = 1 and @iOUR = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 128
 	 END
 	 If @iCUE = 1 and @iOUE = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 258
 	 END
 	 If @iCTF = 1 and @iOTF = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 512
 	 END
 	 If @iCES = 1 and @iOES = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 1024
 	 END
 	 If @iCLC = 1 and @iOLC = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 8192
 	 END
 	 If @iCTC = 1 and @iOTC = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 16384
 	 END
 	 If @iCUC = 1 and @iOUC = 0 
 	 BEGIN
 	  	 Select @RemoveOveride = @RemoveOveride + 32768
 	 END
END
ELSE
BEGIN
 	 If Exists( SELECT 1 From Var_Specs a 	 Where  (a.var_Id  = @Var_Id ) and (a.Prod_Id = @Prod_Id)and (Effective_Date <  @Now)  and (Expiration_Date >  @Now or Expiration_Date is null))
 	 BEGIN
 	  	 SELECT  	 @L_Entry = Case When a.L_Entry IS NULL Then @L_Entry Else Coalesce(@L_Entry,'') End,
 	  	  	 @L_Reject = Case When a.L_Reject IS NULL Then @L_Reject Else Coalesce(@L_Reject,'') End,
 	  	  	 @L_Warning = Case When a.L_Warning IS NULL Then @L_Warning Else Coalesce(@L_Warning,'') End,
 	  	  	 @L_User = Case When a.L_User IS NULL Then @L_User Else Coalesce(@L_User,'') End,
 	  	  	 @Target = Case When a.Target IS NULL Then @Target Else Coalesce(@Target,'') End,
 	  	  	 @U_User = Case When a.U_User IS NULL Then @U_User Else Coalesce(@U_User,'') End,
 	  	  	 @U_Warning = Case When a.U_Warning IS NULL Then @U_Warning Else Coalesce(@U_Warning,'') End,
 	  	  	 @U_Reject = Case When a.U_Reject IS NULL Then @U_Reject Else Coalesce(@U_Reject,'') End,
 	  	  	 @U_Entry = Case When a.U_Entry IS NULL Then @U_Entry Else Coalesce(@U_Entry,'') End,
 	  	  	 @L_Control = Case When a.L_Control IS NULL Then @L_Control Else Coalesce(@L_Control,'') End,
 	  	  	 @T_Control = Case When a.T_Control IS NULL Then @T_Control Else Coalesce(@T_Control,'') End,
 	  	  	 @U_Control = Case When a.U_Control IS NULL Then @U_Control Else Coalesce(@U_Control,'') End,
 	  	  	 @iESigLevel = Case When  (a.Esignature_Level IS Not NULL )Then @iESigLevel ELSE Null End,
 	  	  	 @Test_Freq = Case When  (a.Test_Freq IS Not NULL )Then @Test_Freq ELSE Null End
 	  	  	 From Var_Specs a
 	  	  	 Where  (a.Var_Id  = @Var_Id ) and (a.Prod_Id = @Prod_Id)and (Effective_Date <  @Now)  and (Expiration_Date >  @Now or Expiration_Date is null) 	  	 
 	 END
END
/*****************************************************************************************************
*                            Check to see if numeric specs are in valid sequence   	  	   *
*****************************************************************************************************/
IF @DT In (1,2,4,6,7)
BEGIN
 	 While @Spec < @Spec_Total
     BEGIN
 	  	  Select @Value_String = Case @Spec  	 When 0 Then @L_Entry
 	  	  	  	  	  	 When 1 Then @L_Reject
 	  	  	  	  	  	 When 2 Then @L_Warning
 	  	  	  	  	  	 When 3 Then @L_User
 	  	  	  	  	  	 When 4 Then @Target
 	  	  	  	  	  	 When 5 Then @U_User
 	  	  	  	  	  	 When 6 Then @U_Warning
 	  	  	  	  	  	 When 7 Then @U_Reject
 	  	  	  	  	  	 When 8 Then @U_Entry
 	  	  	  	  	  	 END
 	  	 If @Value_String Is Not Null And @Value_String <> ''
 	  	 BEGIN
 	  	 If @DT = 1 and FLOOR(@Value_String) != @Value_String
 	  	 BEGIN
 	  	  	 Select 'Failed - values are not all integers'
 	  	  	 RETURN (-100)
 	  	 END
          If IsNumeric(@Value_String) = 1
               BEGIN
               Select @Value = convert(float, @Value_String)
               If @Last_Value Is Not Null And @Last_Value >=  @Value and @EqualLimits = 0
                 BEGIN
                    Select 'Failed - values not in correct order'
                    RETURN (-100)
                 END
                If @Last_Value Is Not Null And @Last_Value >  @Value and @EqualLimits = 1
                 BEGIN
                    Select 'Failed - values not in correct order'
                    RETURN (-100)
                 END
              Select @Last_Value = @Value          
               END
          Else
            BEGIN
               Select 'Failed - values not correct Data Type'
               RETURN (-100)
            END
          END
     Select @Spec = @Spec + 1
     END
END
SET @Spec = 0
SET @Spec_Total = 3
SET @Last_Value = Null
IF @DT In (1,2,4,6,7)
BEGIN
 	 While @Spec < @Spec_Total
     BEGIN
 	  	  Select @Value_String = Case @Spec 
 	  	  	  	  	  	 When 0 Then @L_Control
 	  	  	  	  	  	 When 1 Then @T_Control
 	  	  	  	  	  	 When 2 Then @U_Control
 	  	  	  	  	  	 END
 	  	 If @Value_String Is Not Null And @Value_String <> ''
 	  	 BEGIN
 	  	 If @DT = 1 and FLOOR(@Value_String) != @Value_String
 	  	 BEGIN
 	  	  	 Select 'Failed - Control values are not integers'
 	  	  	 RETURN (-100)
 	  	 END
          If IsNumeric(@Value_String) = 1
               BEGIN
               Select @Value = convert(float, @Value_String)
               If @Last_Value Is Not Null And @Last_Value >=  @Value and @EqualLimits = 0
                 BEGIN
                    Select 'Failed - Control values not in correct order'
                    RETURN (-100)
                 END
                If @Last_Value Is Not Null And @Last_Value >  @Value and @EqualLimits = 1
                 BEGIN
                    Select 'Failed - Control values not in correct order'
                    RETURN (-100)
                 END
              Select @Last_Value = @Value          
               END
          Else
            BEGIN
               Select 'Failed - Control values not correct Data Type'
               RETURN (-100)
            END
          END
     Select @Spec = @Spec + 1
     END
END
Execute spEM_PutTransVarValues  @Trans_Id,@Var_Id,@Prod_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,
     	  	  	  	  	  	  	 @U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@iESigLevel,Null,@RemoveOveride,@User_Id
Return(0)
