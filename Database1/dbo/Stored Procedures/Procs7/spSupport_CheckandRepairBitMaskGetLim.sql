Create Procedure dbo.spSupport_CheckandRepairBitMaskGetLim 
 	 @CharId 	 int,
 	 @SpecId 	 int,
 	 @Limit 	  	 int,
 	 @Value 	  	 VarChar(25),
 	 @IsOveriden 	 Int Output
 AS
Declare 	  	 @PrevChar 	 int,
 	  	 @Defined 	 Int,
 	  	 @Start 	  	 Int,
 	  	 @End 	  	  	 Int,
 	  	 @NextVal 	 VarChar(25)
 	 SET @PrevChar = Null
 	 SELECT @PrevChar  = a.Derived_From_Parent FROM Characteristics a WHERE a.Char_Id = @CharId
IF @PrevChar Is Null
BEGIN
 	 SET @IsOveriden = 1
 	 RETURN
END
SELECT @NextVal = Case 	 
 	  	  	 When @Limit = 1     Then L_Entry
 	  	  	 When @Limit = 2     Then L_Reject
 	  	  	 When @Limit = 4     Then L_Warning
 	  	  	 When @Limit = 8     Then L_User
 	  	  	 When @Limit = 16   Then Target
 	  	  	 When @Limit = 32   Then U_User
 	  	  	 When @Limit = 64   Then U_Warning
 	  	  	 When @Limit = 128 Then U_Reject
 	  	  	 When @Limit = 256 Then U_Entry
 	  	  	 When @Limit = 512 Then Convert(varchar(25),Test_Freq)
 	  	  	 When @Limit = 1024 Then Convert(varchar(25),Esignature_Level)
 	  	  	 When @Limit = 8192 Then L_Control
 	  	  	 When @Limit = 16384 Then T_Control
 	  	  	 When @Limit = 32768 Then U_Control
 	  	  	 End
 	  	  	 From Active_Specs
 	  	  	 WHERE Spec_Id = @SpecId and Char_Id = @PrevChar AND Expiration_Date IS NULL
 	 IF @NextVal Is Null
 	 BEGIN
 	  	 SET @IsOveriden = 1
 	  	 RETURN
 	 END
 	 IF @NextVal <> @Value
 	 BEGIN
 	  	 SET @IsOveriden = 1
 	  	 RETURN
 	 END
 	 SET @IsOveriden = 0
RETURN
