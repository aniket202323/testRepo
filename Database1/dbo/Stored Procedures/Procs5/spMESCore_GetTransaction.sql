CREATE PROCEDURE dbo.spMESCore_GetTransaction
 	  	 @Trans_Id 	 Int
AS
 	 SELECT 	 a.Trans_Desc,c.Char_Desc,d.Spec_Desc,
 	  	  	  	  	 b.L_Entry,b.L_Reject,b.L_Warning,b.L_User,
 	  	  	  	  	 b.Target,b.U_User,b.U_Warning,b.U_Reject,b.U_Entry,
 	  	  	  	  	 L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,e.Prop_Desc
 	 FROM Transactions a 
 	 Join Trans_Properties b on a.Trans_Id = b.Trans_Id
 	 Join Characteristics c on c.Char_Id = b.Char_Id 
 	 Join Specifications d on d.Spec_Id = b.Spec_Id
 	 Join Product_Properties e on e.Prop_Id = d.Prop_Id 
 	 WHERE a.Trans_id = @Trans_Id
