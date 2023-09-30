Create Procedure dbo.spCMN_CreateAntiTransaction (@NewTransDesc nvarchar(50),@OldTransId Int,@AntiTransId Int Output)
 	 as
  Declare @Transaction_Grp_Id Int,@Now DateTime
  Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  If (Select count(*) From Transactions Where Trans_Id = @OldTransId) <> 1 -- No Transaction
 	 Return (-100)
  If (Select count(*) From Transactions Where Trans_Desc = @NewTransDesc) > 0  -- Duplicate Description
 	 Return (-101)
  Select @Transaction_Grp_Id = Coalesce(Transaction_Grp_Id,1) From Transactions Where Trans_Id = @OldTransId
  Insert into Transactions (Trans_Desc,Transaction_Grp_Id,Trans_Type_Id)
 	  Values (@NewTransDesc,@Transaction_Grp_Id,5)
  Select  @AntiTransId = Scope_Identity()
  Insert Into Trans_Variables (Trans_Id, Var_Id,Prod_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
 	  	 Select  @AntiTransId,
 	  	              s.Var_Id,
 	  	  	 s.Prod_Id,
 	  	  	 U_Entry = Case   When t.U_Entry is null Then s.U_Entry
 	  	  	  	    	  When s.U_Entry is null Then ''
 	  	  	  	     	  Else   s.U_Entry
 	  	  	  	    End,
 	  	  	 U_Reject = Case   When t.U_Reject is null Then s.U_Reject
 	  	  	  	    	  When s.U_Reject is null Then ''
 	  	  	  	     	  Else   s.U_Reject
 	  	  	  	    End,
 	  	  	 U_Warning = Case   When t.U_Warning is null Then s.U_Warning
 	  	  	  	    	  When s.U_Warning is null Then ''
 	  	  	  	     	  Else   s.U_Warning
 	  	  	  	    End,
 	  	  	 U_User = Case   When t.U_User is null Then s.U_User
 	  	  	  	    	  When s.U_User is null Then ''
 	  	  	  	     	  Else   s.U_User
 	  	  	  	    End,
 	  	  	 Target = Case   When t.Target is null Then s.Target
 	  	  	  	    	  When s.Target is null Then ''
 	  	  	  	     	  Else   s.Target
 	  	  	  	    End,
 	  	  	 L_User = Case   When t.L_User is null Then s.L_User
 	  	  	  	    	  When s.L_User is null Then ''
 	  	  	  	     	  Else   s.L_User
 	  	  	  	    End,
 	  	  	 L_Warning = Case   When t.L_Warning is null Then s.L_Warning
 	  	  	  	    	  When s.L_Warning is null Then ''
 	  	  	  	     	  Else   s.L_Warning
 	  	  	  	    End,
 	  	  	 L_Reject = Case   When t.L_Reject is null Then s.L_Reject
 	  	  	  	    	  When s.L_Reject is null Then ''
 	  	  	  	     	  Else   s.L_Reject
 	  	  	  	    End,
 	  	  	 L_Entry = Case   When t.L_Entry is null Then s.L_Entry
 	  	  	  	    	  When s.L_Entry is null Then ''
 	  	  	  	     	  Else   s.L_Entry
 	  	  	  	    End,
 	  	  	 L_Control = Case   When t.L_Control is null Then s.L_Control
 	  	  	  	    	  When s.L_Control is null Then ''
 	  	  	  	     	  Else   s.L_Control
 	  	  	  	    End,
 	  	  	 T_Control = Case   When t.T_Control is null Then s.T_Control
 	  	  	  	    	  When s.T_Control is null Then ''
 	  	  	  	     	  Else   s.T_Control
 	  	  	  	    End,
 	  	  	 U_Control = Case   When t.U_Control is null Then s.U_Control
 	  	  	  	    	  When s.U_Control is null Then ''
 	  	  	  	     	  Else   s.U_Control
 	  	  	  	    End,
 	  	  	 Test_Freq = Case   When t.Test_Freq is null Then s.Test_Freq
 	  	  	  	    	  When s.Test_Freq is null Then -1
 	  	  	  	     	  Else   s.Test_Freq
 	  	  	  	    End,
 	  	  	 Esignature_Level = Case   When t.Esignature_Level is null Then s.Esignature_Level
 	  	  	  	    	  When s.Esignature_Level is null Then -1
 	  	  	  	     	  Else s.Esignature_Level
 	  	  	  	    End,
 	  	  	 Comment_Id = Case   When t.Comment_Id is null Then s.Comment_Id
 	  	  	  	     	  Else   s.Comment_Id
 	  	  	  	    End
 	  	   From Trans_Variables t
  	                Left JOIN Var_Specs s ON (s.Prod_Id = t.Prod_Id) AND  (s.Var_Id = t.Var_Id) AND
             	  	  	  (s.Effective_Date <= @Now) AND  ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND  (s.Expiration_Date > @Now)))
 	  	   Where Trans_Id = @OldTransId 
 	    Insert Into Trans_Properties(Trans_Id,Spec_Id,Char_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,is_defined)
 	  	 Select  	 @AntiTransId, 
 	  	  	 s.Spec_Id,
 	  	  	 s.Char_Id,
 	  	  	 U_Entry = Case   When t.U_Entry is null Then s.U_Entry
 	  	  	  	    	  When s.U_Entry is null Then ''
 	  	  	  	     	  Else   s.U_Entry
 	  	  	  	    End,
 	  	  	 U_Reject = Case   When t.U_Reject is null Then s.U_Reject
 	  	  	  	    	  When s.U_Reject is null Then ''
 	  	  	  	     	  Else   s.U_Reject
 	  	  	  	    End,
 	  	  	 U_Warning = Case   When t.U_Warning is null Then s.U_Warning
 	  	  	  	    	  When s.U_Warning is null Then ''
 	  	  	  	     	  Else   s.U_Warning
 	  	  	  	    End,
 	  	  	 U_User = Case   When t.U_User is null Then s.U_User
 	  	  	  	    	  When s.U_User is null Then ''
 	  	  	  	     	  Else   s.U_User
 	  	  	  	    End,
 	  	  	 Target = Case   When t.Target is null Then s.Target
 	  	  	  	    	  When s.Target is null Then ''
 	  	  	  	     	  Else   s.Target
 	  	  	  	    End,
 	  	  	 L_User = Case   When t.L_User is null Then s.L_User
 	  	  	  	    	  When s.L_User is null Then ''
 	  	  	  	     	  Else   s.L_User
 	  	  	  	    End,
 	  	  	 L_Warning = Case   When t.L_Warning is null Then s.L_Warning
 	  	  	  	    	  When s.L_Warning is null Then ''
 	  	  	  	     	  Else   s.L_Warning
 	  	  	  	    End,
 	  	  	 L_Reject = Case   When t.L_Reject is null Then s.L_Reject
 	  	  	  	    	  When s.L_Reject is null Then ''
 	  	  	  	     	  Else   s.L_Reject
 	  	  	  	    End,
 	  	  	 L_Entry = Case   When t.L_Entry is null Then s.L_Entry
 	  	  	  	    	  When s.L_Entry is null Then ''
 	  	  	  	     	  Else   s.L_Entry
 	  	  	  	    End,
 	  	  	 L_Control = Case   When t.L_Control is null Then s.L_Control
 	  	  	  	    	  When s.L_Control is null Then ''
 	  	  	  	     	  Else   s.L_Control
 	  	  	  	    End,
 	  	  	 T_Control = Case   When t.T_Control is null Then s.T_Control
 	  	  	  	    	  When s.T_Control is null Then ''
 	  	  	  	     	  Else   s.T_Control
 	  	  	  	    End,
 	  	  	 U_Control = Case   When t.U_Control is null Then s.U_Control
 	  	  	  	    	  When s.U_Control is null Then ''
 	  	  	  	     	  Else   s.U_Control
 	  	  	  	    End,
 	  	  	 Test_Freq = Case   When t.Test_Freq is null Then s.Test_Freq
 	  	  	  	    	  When s.Test_Freq is null Then -1
 	  	  	  	     	  Else   s.Test_Freq
 	  	  	  	    End,
 	  	  	 Esignature_Level = Case   When t.Esignature_Level is null Then s.Esignature_Level
 	  	  	  	    	  When s.Esignature_Level is null Then -1
 	  	  	  	     	  Else   s.Esignature_Level
 	  	  	  	    End,
 	  	  	 Comment_Id = Case   When t.Comment_Id is null Then s.Comment_Id
 	  	  	  	     	  Else   s.Comment_Id
 	  	  	  	    End,
 	  	  	  t.Is_Defined
 	  	   From Trans_Properties t 
 	  	   LEFT JOIN Active_Specs s ON (s.Spec_Id = t.Spec_Id) AND (s.Char_Id = t.Char_Id) AND
            	  	  	  (s.Effective_Date <= @Now) AND  ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND  (s.Expiration_Date > @Now)))
 	  	    WHERE t.Trans_Id = @OldTransId
 	 
