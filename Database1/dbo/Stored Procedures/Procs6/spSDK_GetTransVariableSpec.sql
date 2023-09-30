CREATE PROCEDURE dbo.spSDK_GetTransVariableSpec
 	 @TransId 	  	  	 INT,
 	 @VarId 	  	  	 INT,
 	 @ProdId 	  	  	 INT,
 	 @LE 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @LR 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @LW 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @LU 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @Target 	  	  	 nvarchar(25) 	 OUTPUT,
 	 @UU 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @UW 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @UR 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @UE 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @TestFreq 	  	  	 INT 	  	  	 OUTPUT,
 	 @ESig 	  	  	 INT 	  	  	 OUTPUT,
 	 @LC 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @TC 	  	  	  	 nvarchar(25) 	 OUTPUT,
 	 @UC 	  	  	  	 nvarchar(25) 	 OUTPUT
AS
SELECT 	 @LE = 	 CASE 
 	  	  	  	  	  	 WHEN tv.L_Entry IS NOT NULL 	  	 THEN tv.L_Entry
 	  	  	  	  	  	 WHEN tv.Not_Defined & 1 = 1 	  	 THEN as1.L_Entry
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 1 = 0 	  	 THEN as2.L_Entry
 	  	  	  	  	  	 ELSE vs1.L_Entry
 	  	  	  	  	 END, 
 	  	  	 @LR = CASE 
 	  	  	  	  	  	 WHEN tv.L_Reject IS NOT NULL 	  	 THEN tv.L_Reject
 	  	  	  	  	  	 WHEN tv.Not_Defined & 2 = 2 	  	 THEN as1.L_Reject
 	  	  	  	  	  	 WHEN as2.AS_Id IS NOT NULL 	  	  	 THEN as2.L_Reject
 	  	  	  	  	  	 ELSE vs1.L_Reject
 	  	  	  	  	 END, 
 	  	  	 @LW = CASE 
 	  	  	  	  	  	 WHEN tv.L_Warning IS NOT NULL 	  	 THEN tv.L_Warning
 	  	  	  	  	  	 WHEN tv.Not_Defined & 4 = 4 	  	 THEN as1.L_Warning
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 4 = 0 	  	 THEN as2.L_Warning
 	  	  	  	  	  	 ELSE vs1.L_Warning
 	  	  	  	  	 END, 
 	  	  	 @LU = CASE 
 	  	  	  	  	  	 WHEN tv.L_User IS NOT NULL 	  	  	 THEN tv.L_User
 	  	  	  	  	  	 WHEN tv.Not_Defined & 8 = 8 	  	 THEN as1.L_User
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 8 = 0 	  	 THEN as2.L_User
 	  	  	  	  	  	 ELSE vs1.L_User
 	  	  	  	  	 END, 
 	  	  	 @Target = CASE 
 	  	  	  	  	  	 WHEN tv.Target IS NOT NULL 	  	  	 THEN tv.Target
 	  	  	  	  	  	 WHEN tv.Not_Defined & 16 = 16 	  	 THEN as1.Target
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 16 = 0 	  	 THEN as2.Target
 	  	  	  	  	  	 ELSE vs1.Target
 	  	  	  	  	 END,
 	  	  	 @UU = CASE 
 	  	  	  	  	  	 WHEN tv.U_User IS NOT NULL 	  	  	 THEN tv.U_User
 	  	  	  	  	  	 WHEN tv.Not_Defined & 32 = 32 	  	 THEN as1.U_User
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 32 = 0 	  	 THEN as2.U_User
 	  	  	  	  	  	 ELSE vs1.U_User
 	  	  	  	  	 END, 
 	  	  	 @UW = CASE 
 	  	  	  	  	  	 WHEN tv.U_Warning IS NOT NULL 	  	 THEN tv.U_Warning
 	  	  	  	  	  	 WHEN tv.Not_Defined & 64 = 64 	  	 THEN as1.U_Warning
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 64 = 0 	  	 THEN as2.U_Warning
 	  	  	  	  	  	 ELSE vs1.U_Warning
 	  	  	  	  	 END, 
 	  	  	 @UR = CASE 
 	  	  	  	  	  	 WHEN tv.U_Reject IS NOT NULL 	  	 THEN tv.U_Reject
 	  	  	  	  	  	 WHEN tv.Not_Defined & 128 = 128 	 THEN as1.U_Reject
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 128 = 0 	  	 THEN as2.U_Reject
 	  	  	  	  	  	 ELSE vs1.U_Reject
 	  	  	  	  	 END, 
 	  	  	 @UE = CASE 
 	  	  	  	  	  	 WHEN tv.U_Entry IS NOT NULL 	  	 THEN tv.U_Entry
 	  	  	  	  	  	 WHEN tv.Not_Defined & 256 = 256 	 THEN as1.U_Entry
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 256 = 0 	  	 THEN as2.U_Entry
 	  	  	  	  	  	 ELSE vs1.U_Entry
 	  	  	  	  	 END, 
 	  	  	 @TestFreq = CASE 
 	  	  	  	  	  	 WHEN tv.Test_Freq IS NOT NULL 	  	 THEN tv.Test_Freq
 	  	  	  	  	  	 WHEN tv.Not_Defined & 512 = 512 	 THEN as1.Test_Freq
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 512 = 0 	  	 THEN as2.Test_Freq
 	  	  	  	  	  	 ELSE vs1.Test_Freq
 	  	  	  	  	 END,
 	  	  	 @ESig = CASE 
 	  	  	  	  	  	 WHEN tv.Esignature_Level IS NOT NULL 	 THEN tv.Esignature_Level
 	  	  	  	  	  	 WHEN tv.Not_Defined & 1024 = 1024 	  	 THEN as1.Esignature_Level
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 1024 = 0 	  	 THEN as2.Esignature_Level
 	  	  	  	  	  	 ELSE vs1.Esignature_Level
 	  	  	  	  	 END,
 	  	  	 @LC = CASE 
 	  	  	  	  	  	 WHEN tv.L_Control IS NOT NULL 	  	 THEN tv.L_Control
 	  	  	  	  	  	 WHEN tv.Not_Defined & 8192 = 8192 	 THEN as1.L_Control
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 8192 = 0 	 THEN as2.L_Control
 	  	  	  	  	  	 ELSE vs1.L_Control
 	  	  	  	  	 END, 
 	  	  	 @TC = CASE 
 	  	  	  	  	  	 WHEN tv.T_Control IS NOT NULL 	  	  	 THEN tv.T_Control
 	  	  	  	  	  	 WHEN tv.Not_Defined & 16384 = 16384 	 THEN as1.T_Control
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 16384 = 0 	  	 THEN as2.T_Control
 	  	  	  	  	  	 ELSE vs1.T_Control
 	  	  	  	  	 END, 
 	  	  	 @UC = CASE 
 	  	  	  	  	  	 WHEN tv.U_Control IS NOT NULL 	  	  	 THEN tv.U_Control
 	  	  	  	  	  	 WHEN tv.Not_Defined & 32768 = 32768 	 THEN as1.U_Control
 	  	  	  	  	  	 WHEN vs1.Is_Defined & 32768 = 0 	  	 THEN as2.U_Control
 	  	  	  	  	  	 ELSE vs1.U_Control
 	  	  	  	  	 END
 	 FROM 	 Variables v 	  	  	  	  	  	 LEFT JOIN
 	  	  	 PU_Products pup 	  	  	  	 ON 	 v.PU_Id = pup.PU_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pup.Prod_Id = @ProdId 	  	  	  	  	 LEFT JOIN
 	  	  	 Var_Specs vs1 	  	  	  	  	 ON 	 v.Var_Id = vs1.Var_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pup.Prod_Id = vs1.Prod_Id AND 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	 vs1.Effective_Date <= dbo.fnServer_CmnGetDate(getUTCdate()) AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 (vs1.Expiration_Date > dbo.fnServer_CmnGetDate(getUTCdate()) OR 
 	  	  	  	  	  	  	  	  	  	  	  	  	  vs1.Expiration_Date IS NULL) 	  	  	 LEFT JOIN
 	  	  	 Trans_Variables tv 	  	  	 ON (v.Var_Id = tv.Var_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  pup.Prod_Id = tv.Prod_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  tv.Trans_Id = @TransId) LEFT JOIN
  	  	  	 Active_Specs as1 	  	  	  	 ON (vs1.AS_Id = as1.AS_Id) LEFT JOIN
 	  	  	 Trans_Characteristics tc 	 ON (pup.Prod_Id = tc.Prod_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  v.PU_Id = tc.PU_Id) LEFT JOIN
 	  	  	 Active_Specs as2 	  	  	  	 ON (v.Spec_Id = as2.Spec_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  tc.Char_Id = as2.Char_Id)
 	 WHERE 	 v.Var_Id = @VarId
