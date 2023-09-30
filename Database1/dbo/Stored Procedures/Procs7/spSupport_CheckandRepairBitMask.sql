CREATE PROCEDURE dbo.spSupport_CheckandRepairBitMask
  @SpecId    int,
  @CharId 	  	  	 int = null,
  @DoUpdate 	  	 Int = 0
 AS
DECLARE @CharIdsToFix TABLE(id Int Identity(1,1),CharId Int)
DECLARE @Start Int
DECLARE @CurrentChar Int
DECLARE @IsDefined Int
DECLARE @BitDefined Int
DECLARE @End 	 Int
DECLARE @Limit INT
DECLARE @LimitVal 	 VarChar(25)
DECLARE @L_Entry 	 VarChar(25),
 	  	  	  	 @L_Reject 	 VarChar(25),
 	  	  	  	 @L_Warning 	 VarChar(25),
 	  	  	  	 @L_User 	 VarChar(25),
 	  	  	  	 @Target 	 VarChar(25),
 	  	  	  	 @U_User 	 VarChar(25),
 	  	  	  	 @U_Warning 	 VarChar(25),
 	  	  	  	 @U_Reject 	 VarChar(25),
 	  	  	  	 @U_Entry 	 VarChar(25),
 	  	  	  	 @L_Control 	 VarChar(25),
 	  	  	  	 @T_Control 	 VarChar(25),
 	  	  	  	 @U_Control 	 VarChar(25),
 	  	  	  	 @Test_Freq 	 int,
 	  	  	  	 @Sig 	  	 int,
 	  	  	  	 @CurrentBit 	 Int
SELECT @DoUpdate = Coalesce(@DoUpdate,0)
SET @Start = 1
IF @CharId Is Null
BEGIN
 	 INSERT INTO @CharIdsToFix 
 	  	 SELECT Char_Id 
 	  	  	 FROM Characteristics a
 	  	  	 Join Specifications b on b.Prop_Id = a.Prop_Id
 	  	  	 WHERE Spec_Id = @SpecId 	  	  	 
END
ELSE
BEGIN
 	 INSERT INTO @CharIdsToFix(CharId) VALUES (@CharId)
END
SELECT @End = COUNT(*) FROM @CharIdsToFix
WHILE @Start <= @End
BEGIN
 	 SELECT @CurrentChar = charid FROM @CharIdsToFix WHERE id = @Start
 	 SELECT @L_Entry 	 = L_Entry,
 	  	  	  	  	 @L_Reject 	 = L_Reject,
 	  	  	  	  	 @L_Warning 	 =L_Warning,
 	  	  	  	  	 @L_User 	 =L_User,
 	  	  	  	  	 @Target 	 =Target,
 	  	  	  	  	 @U_User 	 =U_User,
 	  	  	  	  	 @U_Warning 	 =U_Warning,
 	  	  	  	  	 @U_Reject 	 =U_Reject,
 	  	  	  	  	 @U_Entry 	 =U_Entry,
 	  	  	  	  	 @L_Control 	 =L_Control,
 	  	  	  	  	 @T_Control 	 =T_Control,
 	  	  	  	  	 @U_Control 	 =U_Control,
 	  	  	  	  	 @Test_Freq 	 =Test_Freq,
 	  	  	  	  	 @Sig 	  	 = a.Esignature_Level,
 	  	  	  	  	 @CurrentBit = Coalesce(a.Is_Defined,0)  
 	 FROM Active_Specs a
 	 WHERE Spec_Id = @SpecId and Char_Id = @CurrentChar AND Expiration_Date IS NULL
 	 SET  @Limit = 1
 	 SET @IsDefined = 0
 	 WHILE @Limit < 32769
 	 BEGIN
 	  	 SELECT @LimitVal = CASE  
 	  	  	 When @Limit = 1     Then @L_Entry
 	  	  	 When @Limit = 2     Then @L_Reject
 	  	  	 When @Limit = 4     Then @L_Warning
 	  	  	 When @Limit = 8     Then @L_User
 	  	  	 When @Limit = 16   Then @Target
 	  	  	 When @Limit = 32   Then @U_User
 	  	  	 When @Limit = 64   Then @U_Warning
 	  	  	 When @Limit = 128 Then @U_Reject
 	  	  	 When @Limit = 256 Then @U_Entry
 	  	  	 When @Limit = 512 Then Convert(varchar(25),@Test_Freq)
 	  	  	 When @Limit = 1024 Then Convert(varchar(25),@Sig)
 	  	  	 When @Limit = 8192 Then @L_Control
 	  	  	 When @Limit = 16384 Then @T_Control
 	  	  	 When @Limit = 32768 Then @U_Control
 	  	  	 END
 	  	 IF @LimitVal IS Not Null
 	  	 BEGIN
 	  	  	 Execute spSupport_CheckandRepairBitMaskGetLim  	 @CurrentChar,@SpecId,@Limit,@LimitVal,@BitDefined 	 Output
 	  	  	 IF @BitDefined = 1 SET @IsDefined = @IsDefined + @Limit
 	  	 END
 	  	 SET @Limit = @Limit * 2
 	 END
 	 IF @CurrentBit <> @IsDefined
 	 BEGIN
 	  	 IF @IsDefined = 0 SET @IsDefined = Null
 	  	 SELECT 'Changing Bitmask for [' + prop_desc + '] [' + Spec_Desc + '] [' + Char_Desc +  '] from  [' + Convert(VarChar(25),coalesce(@CurrentBit,0)) + '] to  [' +  Convert(VarChar(25),coalesce(@IsDefined,0)) + ']'
 	  	  	  	 FROM Product_Properties a
 	  	  	  	 Join Specifications b On b.Spec_Id = @SpecId and b.Prop_Id = a.prop_Id
 	  	  	  	 Join Characteristics c On c.Char_Id = @CurrentChar and c.Prop_Id = a.prop_Id
 	  	 IF @DoUpdate = 1
 	  	  	 UPDATE Active_Specs SET Is_Defined = @IsDefined WHERE Spec_Id = @SpecId and Char_Id = @CurrentChar AND Expiration_Date IS NULL
 	 END
 	 SET @Start = @Start + 1
END
