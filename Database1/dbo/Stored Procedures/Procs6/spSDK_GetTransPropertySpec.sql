CREATE PROCEDURE dbo.spSDK_GetTransPropertySpec
 	 @TransId 	  	  	 INT,
 	 @SpecId 	  	  	 INT,
 	 @CharId 	  	  	 INT,
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
 	  	  	  	  	  	 WHEN tp.L_Entry IS NOT NULL 	  	 THEN tp.L_Entry
 	  	  	  	  	  	 WHEN tp.Not_Defined & 1 = 1 	  	 THEN as2.L_Entry
 	  	  	  	  	  	 ELSE as1.L_Entry
 	  	  	  	  	 END, 
 	  	  	 @LR = CASE 
 	  	  	  	  	  	 WHEN tp.L_Reject IS NOT NULL 	  	 THEN tp.L_Reject
 	  	  	  	  	  	 WHEN tp.Not_Defined & 2 = 2 	  	 THEN as2.L_Reject
 	  	  	  	  	  	 ELSE as1.L_Reject
 	  	  	  	  	 END, 
 	  	  	 @LW = CASE 
 	  	  	  	  	  	 WHEN tp.L_Warning IS NOT NULL 	  	 THEN tp.L_Warning
 	  	  	  	  	  	 WHEN tp.Not_Defined & 4 = 4 	  	 THEN as2.L_Warning
 	  	  	  	  	  	 ELSE as1.L_Warning
 	  	  	  	  	 END, 
 	  	  	 @LU = CASE 
 	  	  	  	  	  	 WHEN tp.L_User IS NOT NULL 	  	  	 THEN tp.L_User
 	  	  	  	  	  	 WHEN tp.Not_Defined & 8 = 8 	  	 THEN as2.L_User
 	  	  	  	  	  	 ELSE as1.L_User
 	  	  	  	  	 END, 
 	  	  	 @Target = CASE 
 	  	  	  	  	  	 WHEN tp.Target IS NOT NULL 	  	  	 THEN tp.Target
 	  	  	  	  	  	 WHEN tp.Not_Defined & 16 = 16 	  	 THEN as2.Target
 	  	  	  	  	  	 ELSE as1.Target
 	  	  	  	  	 END,
 	  	  	 @UU = CASE 
 	  	  	  	  	  	 WHEN tp.U_User IS NOT NULL 	  	  	 THEN tp.U_User
 	  	  	  	  	  	 WHEN tp.Not_Defined & 32 = 32 	  	 THEN as2.U_User
 	  	  	  	  	  	 ELSE as1.U_User
 	  	  	  	  	 END, 
 	  	  	 @UW = CASE 
 	  	  	  	  	  	 WHEN tp.U_Warning IS NOT NULL 	  	 THEN tp.U_Warning
 	  	  	  	  	  	 WHEN tp.Not_Defined & 64 = 64 	  	 THEN as2.U_Warning
 	  	  	  	  	  	 ELSE as1.U_Warning
 	  	  	  	  	 END, 
 	  	  	 @UR = CASE 
 	  	  	  	  	  	 WHEN tp.U_Reject IS NOT NULL 	  	 THEN tp.U_Reject
 	  	  	  	  	  	 WHEN tp.Not_Defined & 128 = 128 	 THEN as2.U_Reject
 	  	  	  	  	  	 ELSE as1.U_Reject
 	  	  	  	  	 END, 
 	  	  	 @UE = CASE 
 	  	  	  	  	  	 WHEN tp.U_Entry IS NOT NULL 	  	 THEN tp.U_Entry
 	  	  	  	  	  	 WHEN tp.Not_Defined & 256 = 256 	 THEN as2.U_Entry
 	  	  	  	  	  	 ELSE as1.U_Entry
 	  	  	  	  	 END, 
 	  	  	 @TestFreq = CASE 
 	  	  	  	  	  	 WHEN tp.Test_Freq IS NOT NULL 	  	 THEN tp.Test_Freq
 	  	  	  	  	  	 WHEN tp.Not_Defined & 512 = 512 	 THEN as2.Test_Freq
 	  	  	  	  	  	 ELSE as1.Test_Freq
 	  	  	  	  	 END,
 	  	  	 @ESig = CASE 
 	  	  	  	  	  	 WHEN tp.Esignature_Level IS NOT NULL 	  	 THEN tp.Esignature_Level
 	  	  	  	  	  	 WHEN tp.Not_Defined & 1024 = 1024 	 THEN as2.Esignature_Level
 	  	  	  	  	  	 ELSE as1.Esignature_Level
 	  	  	  	  	 END,
 	  	  	 @LC = CASE 
 	  	  	  	  	  	 WHEN tp.L_Control IS NOT NULL 	  	 THEN tp.L_Control
 	  	  	  	  	  	 WHEN tp.Not_Defined & 8192 = 8192 	 THEN as2.L_Control
 	  	  	  	  	  	 ELSE as1.L_Control
 	  	  	  	  	 END, 
 	  	  	 @TC = CASE 
 	  	  	  	  	  	 WHEN tp.T_Control IS NOT NULL 	  	 THEN tp.T_Control
 	  	  	  	  	  	 WHEN tp.Not_Defined & 16384 = 16384 	 THEN as2.T_Control
 	  	  	  	  	  	 ELSE as1.T_Control
 	  	  	  	  	 END, 
 	  	  	 @UC = CASE 
 	  	  	  	  	  	 WHEN tp.U_Control IS NOT NULL 	  	 THEN tp.U_Control
 	  	  	  	  	  	 WHEN tp.Not_Defined & 32768 = 32768 	 THEN as2.U_Control
 	  	  	  	  	  	 ELSE as1.U_Control
 	  	  	  	  	 END 
 	 FROM 	  	  	 Specifications s
 	 INNER 	 JOIN 	 Product_Properties p 	 ON 	  	 (s.Prop_Id = s.Prop_Id)
 	 INNER 	 JOIN 	 Characteristics c1 	 ON 	  	 (p.Prop_Id = c1.Prop_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1.Char_Id = @CharId) 
 	 LEFT JOIN 	 Active_Specs as1 	  	 ON 	  	 (s.Spec_Id = as1.Spec_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1.Char_Id = as1.Char_Id) 
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 as1.Effective_Date <= dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 (as1.Expiration_Date > dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR 	 as1.Expiration_Date IS NULL)
 	 LEFT JOIN 	 Trans_Properties tp 	 ON 	  	 (s.Spec_Id = tp.Spec_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c1.Char_Id = tp.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 tp.Trans_Id = @TransId)
 	 LEFT JOIN 	 Trans_Char_Links tcl 	 ON (c1.Char_Id = tcl.From_Char_Id) 
 	 LEFT JOIN 	 Characteristics c2 	 ON (COALESCE(tcl.To_Char_Id, c1.Derived_From_Parent) = c2.Char_Id) 
 	 LEFT JOIN 	 Active_Specs as2 	  	 ON (s.Spec_Id = as2.Spec_Id
 	  	  	  	  	  	  	  	  	  	  	  	 AND 	 c2.Char_Id = as2.Char_Id)
 	 WHERE 	 s.Spec_Id = @SpecId
 	 AND 	 c1.Char_Id = @CharId 
