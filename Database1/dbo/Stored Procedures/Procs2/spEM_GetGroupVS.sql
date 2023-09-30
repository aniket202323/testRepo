CREATE PROCEDURE dbo.spEM_GetGroupVS
  @PUG_Id int,
  @Prod_Id int,
  @Prop_Id Int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE @Now          DateTime,
 	 @PU_Id        int,
 	 @Char_Id      Int 
 --
  -- Initialize local variables.
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
   --
  -- Get the current variable specifications for this unit. Note that we don't
  -- need to join to PU_Products as there should be no invalid products for a
  -- give variable in Var_Specs.
  --
If @PUG_Id is Null
  Begin
--     Select  @Prop_Id = Prop_Id From Characteristics where Char_Id = @Char_Id
     SELECT v.Var_Id,
         Prod_Id = @Prod_Id,
         U_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Entry
 	  	  	  	  	  	 End,
         U_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Reject
 	  	  	  	  	  	 End,
         U_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Warning
 	  	  	  	  	  	 End,
         U_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_User
 	  	  	  	  	  	 End,
         Target = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.Target
 	  	  	  	  	  	 End,
         L_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_User
 	  	  	  	  	  	 End,
         L_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Warning
 	  	  	  	  	  	 End,
         L_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Reject
 	  	  	  	  	  	 End,
         L_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Entry
 	  	  	  	  	  	 End,
         L_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Control
 	  	  	  	  	  	 End,
         T_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.T_Control
 	  	  	  	  	  	 End,
         U_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Control
 	  	  	  	  	  	 End,
 	   	  s.Test_Freq,
 	  	  s.Esignature_Level,
         s.Comment_Id,
         s.Expiration_Date,
         s.AS_Id,
         v.Spec_Id,
         Char_Id,
         Prop_Id = COALESCE(sp.Prop_Id, 0),
         s.Is_Defined, 
         s.Is_OverRidable
       FROM Variables v
           Join Specifications sp on sp.spec_Id = v.spec_Id  and sp.prop_Id = @Prop_Id
            LEFT JOIN Var_Specs s ON (s.Var_Id = v.Var_Id)  And  (s.Prod_Id = @Prod_Id)  And  (s.Effective_Date <= @Now)  And   ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND (s.Expiration_Date > @Now)))
           LEFT Join Active_Specs a on a.AS_Id = s.AS_Id
 	    Where (PVar_Id is null) or (SPC_Group_Variable_Type_Id is not Null) and v.SA_Id <> 0
   End
Else
  Begin 
    Create Table #Variables(Var_Id Int,Data_Type_Id Int,Spec_Id Int,PVar_Id Int,SPC_Group_Variable_Type_Id Int)
 	 Insert Into #Variables(Var_Id,Data_Type_Id,Spec_Id) 
 	  	 Select  Var_Id,Data_Type_Id,Spec_Id
 	  	 From Variables
 	  	 Where PUG_Id = @PUG_Id AND ((PVar_Id is null) or (SPC_Group_Variable_Type_Id is not Null)) and SA_Id <> 0
     Delete From #Variables
 	  	 From  #Variables v
 	  	   Join Specifications s on s.Spec_Id = v.Spec_Id
 	  	   Join Product_Properties pp on pp.prop_Id = s.prop_Id and Property_Type_Id <> 1
 	   SELECT v.Var_Id,
     	      s.Prod_Id,
         	  U_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Entry
 	  	  	  	  	  	 End,
 	          U_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Reject
 	  	  	  	  	  	 End,
     	      U_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Warning
 	  	  	  	  	  	 End,
         	  U_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_User
 	  	  	  	  	  	 End,
 	          Target = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.Target
 	  	  	  	  	  	 End,
     	      L_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_User
 	  	  	  	  	  	 End,
         	  L_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Warning
 	  	  	  	  	  	 End,
 	          L_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Reject
 	  	  	  	  	  	 End,
     	      L_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Entry
 	  	  	  	  	  	 End,
     	      L_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.L_Control
 	  	  	  	  	  	 End,
     	      T_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.T_Control
 	  	  	  	  	  	 End,
     	      U_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(s.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else s.U_Control
 	  	  	  	  	  	 End,
         	  s.Test_Freq,
 	          s.Esignature_Level,
     	      s.Comment_Id,
         	  s.Expiration_Date,
 	          s.AS_Id,
         	  v.Spec_Id,
     	      Char_Id,
 	          Prop_Id = COALESCE(sp.Prop_Id, 0),
     	      s.Is_Defined, 
         	  s.Is_OverRidable
 	     FROM #Variables v
          LEFT JOIN Var_Specs s ON s.Var_Id = v.Var_Id
          LEFT Join Active_Specs a on a.AS_Id = s.AS_Id
          LEFT Join Specifications sp on sp.spec_Id = v.spec_Id
     	 WHERE (s.Prod_Id = @Prod_Id) AND (s.Effective_Date <= @Now) and 
          ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND (s.Expiration_Date > @Now)))
  End
