CREATE PROCEDURE dbo.spMESCore_IEImportCentralSpecs
@Prop_Desc  	 VarChar(50),
@Spec_Desc  	 VarChar(50),
@Char_Desc  	 VarChar(50),
@L_Entry  	 VarChar(25),
@L_Reject  	 VarChar(25),
@L_Warning  	 VarChar(25),
@L_User  	 VarChar(25),
@Target  	 VarChar(25),
@U_User  	 VarChar(25),
@U_Warning  	 VarChar(25),
@U_Reject  	 VarChar(25),
@U_Entry  	 VarChar(25),
@Test_Freq_Str  VarChar(25),
@L_Control 	 VarChar(25),
@T_Control 	 VarChar(25),
@U_Control 	 VarChar(25),
@Esignature 	 VarChar(50),
@User_Id 	 Int,
@Trans_Id 	 Int
AS
Declare  @ReturnString Table(ReturnCode Int,Success Varchar(255))
DECLARE @OL_Entry  	 VarChar(1),
 	  	 @OL_Reject  	 VarChar(1),
 	  	 @OL_Warning VarChar(1),
 	  	 @OL_User  	 VarChar(1),
 	  	 @OTarget  	 VarChar(1),
 	  	 @OU_User  	 VarChar(1),
 	  	 @OU_Warning VarChar(1),
 	  	 @OU_Reject  	 VarChar(1),
 	  	 @OU_Entry  	 VarChar(1),
 	  	 @OTestFreq  VarChar(1),
 	  	 @OL_Control 	 VarChar(1),
 	  	 @OT_Control 	 VarChar(1),
 	  	 @OU_Control 	 VarChar(1),
 	  	 @OEsig 	  	 VarChar(1)
 	  	 
 	 SET 	  	 @OL_Entry  	 = '0'
 	 SET 	  	 @OL_Reject= '0'
 	 SET 	  	 @OL_Warning = '0'
 	 SET 	  	 @OL_User  	 = '0'
 	 SET 	  	 @OTarget= '0'
 	 SET 	  	 @OU_User = '0'
 	 SET 	  	 @OU_Warning = '0'
 	 SET 	  	 @OU_Reject = '0'
 	 SET 	  	 @OU_Entry = '0'
 	 SET 	  	 @OTestFreq = '0'
 	 SET 	  	 @OL_Control = '0'
 	 SET 	  	 @OT_Control = '0'
 	 SET 	  	 @OU_Control = '0'
 	 SET 	  	 @OEsig= '0'
IF ltrim(rtrim(@L_Entry)) 	 = '' SET @L_Entry = null
IF ltrim(rtrim(@L_Reject)) = '' SET @L_Reject = null
IF ltrim(rtrim(@L_Warning)) = '' SET @L_Warning = null
IF ltrim(rtrim(@L_User)) = '' SET @L_User = null
IF ltrim(rtrim(@Target)) = '' SET @Target = null
IF ltrim(rtrim(@U_User)) = '' SET @U_User = null
IF ltrim(rtrim(@U_Warning)) = '' SET @U_Warning = null
IF ltrim(rtrim(@U_Reject)) = '' SET @U_Reject = null
IF ltrim(rtrim(@U_Entry)) = '' SET @U_Entry = null
IF ltrim(rtrim(@Test_Freq_Str)) = '' SET @Test_Freq_Str = null
IF ltrim(rtrim(@L_Control)) 	 = '' SET @L_Control = null
IF ltrim(rtrim(@T_Control)) 	 = '' SET @T_Control = null
IF ltrim(rtrim(@U_Control)) 	 = '' SET @U_Control = null
IF ltrim(rtrim(@Esignature)) 	 = '' SET @Esignature = null
IF @L_Entry 	 Is Not Null SET @OL_Entry = '1'
IF @L_Reject Is Not Null SET @OL_Reject = '1'
IF @L_Warning Is Not Null SET @OL_Warning = '1'
IF @L_User Is Not Null SET @OL_User = '1'
IF @Target Is Not Null SET @OTarget = '1'
IF @U_User Is Not Null SET @OU_User = '1'
IF @U_Warning Is Not Null SET @OU_Warning = '1'
IF @U_Reject Is Not Null SET @OU_Reject = '1'
IF @U_Entry Is Not Null SET @OU_Entry = '1'
IF @Test_Freq_Str Is Not Null SET @OTestFreq = '1'
IF @L_Control 	 Is Not Null SET @OL_Control = '1'
IF @T_Control 	 Is Not Null SET @OT_Control = '1'
IF @U_Control 	 Is Not Null SET @OU_Control = '1'
IF @Esignature 	 Is Not Null SET @OEsig = '1'
Insert INTO @ReturnString(Success)
EXECUTE dbo.spEM_IEImportCentralSpecs
@Prop_Desc,
@Spec_Desc,
@Char_Desc, '0',
@L_Entry,@OL_Entry,
@L_Reject,@OL_Reject,
@L_Warning,@OL_Warning,
@L_User,@OL_User,
@Target,@OTarget,
@U_User,@OU_User,
@U_Warning,@OU_Warning,
@U_Reject,@OU_Reject,
@U_Entry,@OU_Entry,
@Test_Freq_Str,@OTestFreq,
@Esignature,@OEsig,
@L_Control,@OL_Control,
@T_Control,@OT_Control,
@U_Control,@OU_Control,
@User_Id,
@Trans_Id
UPdate @ReturnString Set ReturnCode = -100
IF NOT EXISTS(SELECT 1 From @ReturnString WHERE ReturnCode = -100)
 	 INSERT INTO @ReturnString(ReturnCode,Success) VALUES (0,'Success')
SELECT Success
FROM @ReturnString
