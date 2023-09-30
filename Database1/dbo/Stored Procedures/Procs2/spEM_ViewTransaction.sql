CREATE PROCEDURE dbo.spEM_ViewTransaction
  @Trans_Id int
  AS
 	 Select [Name] = v.Test_Name,[Product] = p.Prod_Code,
 	  	 [LE] = L_Entry,
 	  	 [LR] = L_Reject,
 	  	 [LW] = L_Warning,
 	  	 [LU] = L_User,
 	  	 [T] = Target,
 	  	 [UU] = U_User,
 	  	 [UW] = U_Warning,
 	  	 [UR] = U_Reject,
 	  	 [UE] = U_Entry,
 	  	 [LC] = L_Control,
 	  	 [TC] = T_Control,
 	  	 [UC] = U_Control,
 	  	 [TF] = Test_Freq,
 	  	 [SIG] = Case When tv.Esignature_Level = 1 then 'User'
 	  	  	  	 When tv.Esignature_Level = 2 then 'Approver'
 	  	  	  	 Else ' '
 	  	  	  	 End
        FROM Trans_Variables tv
        JOIN Variables v ON v.Var_Id = tv.Var_Id
 	  	 Join Products p On p.Prod_Id = tv.Prod_Id
        WHERE Trans_Id = @Trans_Id
 	 Order BY [Name],Product
