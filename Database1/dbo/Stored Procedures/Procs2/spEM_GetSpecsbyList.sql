CREATE PROCEDURE dbo.spEM_GetSpecsbyList
  @VarorSpecId 	 Int,
  @CharorProdIds 	 VarChar(7000),
  @TransId 	 Int,
  @IsProperty 	 Tinyint,
  @DecimalSep     nVarChar(2) = '.'
 AS
Declare @Id 	 int,
 	 @Now 	  	 DateTime
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Create Table #IDS (Ids Int)
While (Datalength( LTRIM(RTRIM(@CharorProdIds))) > 1) 
  Begin
       Select @Id = Convert(Int,SubString(@CharorProdIds,1,CharIndex(Char(1),@CharorProdIds)-1))
       Select @CharorProdIds = SubString(@CharorProdIds,CharIndex(Char(1),@CharorProdIds),Datalength(@CharorProdIds))
       Select @CharorProdIds = Right(@CharorProdIds,Datalength(@CharorProdIds)-1)
       Insert Into #IDS values(@Id)
  End
If @IsProperty = 1 
 Begin
 	 -- Select Active Specifications
 	 Select  [Id] = a.Char_Id,
          	 U_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Entry
 	  	  	  	  	  	 End,
 	         U_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Reject
 	  	  	  	  	  	 End,
     	     U_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Warning
 	  	  	  	  	  	 End,
         	 U_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_User
 	  	  	  	  	  	 End,
 	         Target = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.Target
 	  	  	  	  	  	 End,
     	     L_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_User
 	  	  	  	  	  	 End,
         	 L_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Warning
 	  	  	  	  	  	 End,
 	         L_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Reject
 	  	  	  	  	  	 End,
     	     L_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Entry
 	  	  	  	  	  	 End,
     	     L_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Control
 	  	  	  	  	  	 End,
     	     T_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.T_Control
 	  	  	  	  	  	 End,
     	     U_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Control
 	  	  	  	  	  	 End,
 	  	  	 Test_Freq,Esignature_Level,Is_OverRidable,Is_Defined,a.Expiration_Date,
 	  	  	 [LockCells] = case When cs.Derived_From_Parent is null then 0
 	  	  	  	 Else 1
 	  	  	  	 End
  	  	 From Active_Specs a
 	  	 Join #IDS c on c.Ids = a.Char_Id
 	  	 Join Characteristics cs on cs.Char_Id = a.Char_Id
 	  	 Join Specifications s on s.Spec_Id = a.Spec_Id
 	   Where   (a.Spec_Id = @VarorSpecId) and (a.Effective_Date < @Now and (a.Expiration_Date >= @Now or a.Expiration_Date is null))
 	 -- Select Transaction
 	 Select  [Id] = t.Char_Id,
          	 U_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Entry
 	  	  	  	  	  	 End,
 	         U_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Reject
 	  	  	  	  	  	 End,
     	     U_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Warning
 	  	  	  	  	  	 End,
         	 U_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_User
 	  	  	  	  	  	 End,
 	         Target = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.Target
 	  	  	  	  	  	 End,
     	     L_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_User
 	  	  	  	  	  	 End,
         	 L_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Warning
 	  	  	  	  	  	 End,
 	         L_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Reject
 	  	  	  	  	  	 End,
     	     L_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Entry
 	  	  	  	  	  	 End,
     	     L_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Control
 	  	  	  	  	  	 End,
     	     T_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.T_Control
 	  	  	  	  	  	 End,
     	     U_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Control
 	  	  	  	  	  	 End,
 	  	  	 Test_Freq,Esignature_Level,Is_Defined,Expiration_Date = null,
 	  	  	 [LockCells] = case When cs.Derived_From_Parent is null then 0
 	  	  	  	 Else 1
 	  	  	  	 End
 	  	 From Trans_Properties t
 	  	 Join #IDS c on c.Ids = t.Char_Id
 	  	 Join Specifications s on s.Spec_Id = t.Spec_Id
 	  	 Join Characteristics cs on cs.Char_Id = t.Char_Id
 	   Where  (t.Spec_Id = @VarorSpecId) and (Trans_Id = @TransId)
 End
Else
 Begin
 	 -- Select Variable Specifications
 	 Select  [Id] = vs.Prod_Id,
          	 U_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.U_Entry
 	  	  	  	  	  	 End,
 	         U_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.U_Reject
 	  	  	  	  	  	 End,
     	     U_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.U_Warning
 	  	  	  	  	  	 End,
         	 U_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.U_User
 	  	  	  	  	  	 End,
 	         Target = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.Target
 	  	  	  	  	  	 End,
     	     L_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.L_User
 	  	  	  	  	  	 End,
         	 L_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.L_Warning
 	  	  	  	  	  	 End,
 	         L_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.L_Reject
 	  	  	  	  	  	 End,
     	     L_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.L_Entry
 	  	  	  	  	  	 End,
     	     L_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.L_Control
 	  	  	  	  	  	 End,
     	     T_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.T_Control
 	  	  	  	  	  	 End,
     	     U_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(vs.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else vs.U_Control
 	  	  	  	  	  	 End,
 	  	 Test_Freq,vs.Esignature_Level,Is_OverRidable,Is_Defined,vs.Expiration_Date,
 	  	 [LockCells] = case When vs.as_Id is null then 0
 	  	  	  	 Else 1
 	  	  	  	 End
 	  	 From Var_Specs vs
 	  	 Join #IDS c on c.Ids = vs.Prod_Id
 	  	 Join Variables v on v.Var_Id = vs.Var_Id
 	   Where   (vs.Var_Id = @VarorSpecId) and (vs.Effective_Date < @Now and (vs.Expiration_Date >= @Now or vs.Expiration_Date is null))
 	 -- Select Transaction
 	 Select  [Id] = t.Prod_Id,
          	 U_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Entry
 	  	  	  	  	  	 End,
 	         U_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Reject
 	  	  	  	  	  	 End,
     	     U_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Warning
 	  	  	  	  	  	 End,
         	 U_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_User
 	  	  	  	  	  	 End,
 	         Target = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.Target
 	  	  	  	  	  	 End,
     	     L_User = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_User
 	  	  	  	  	  	 End,
         	 L_Warning = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Warning
 	  	  	  	  	  	 End,
 	         L_Reject = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Reject
 	  	  	  	  	  	 End,
     	     L_Entry = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Entry
 	  	  	  	  	  	 End,
     	     L_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Control
 	  	  	  	  	  	 End,
     	     T_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.T_Control
 	  	  	  	  	  	 End,
     	     U_Control = Case When v.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Control
 	  	  	  	  	  	 End,
        Test_Freq,t.Esignature_Level,Expiration_Date = null,Is_Defined,
 	  	 [LockCells] = case When v.spec_Id is null then 0
 	  	  	  	 Else 1
 	  	  	  	 End
 	  	 From Trans_Variables t
 	  	 Join #IDS c on c.Ids = t.Prod_Id
 	  	 Join Variables v on v.Var_Id = t.Var_Id
 	   Where (t.Var_Id = @VarorSpecId) and (Trans_Id = @TransId)
 End
Drop Table #IDS
