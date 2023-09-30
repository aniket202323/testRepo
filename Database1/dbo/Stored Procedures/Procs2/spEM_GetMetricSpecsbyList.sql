--- spEM_GetMetricSpecsbyList 7053,'135136134',9565,'2003-02-04 12:00:00.000'
CREATE PROCEDURE dbo.spEM_GetMetricSpecsbyList
  @SpecId 	 Int,
  @CharIds 	 VarChar(7000),
  @TransId 	 Int,
  @Eff_Date DateTime,
  @DecimalSep     nVarChar(2) = '.'
 AS
Declare @Id 	 int
Create Table #IDS (Ids Int)
While (Datalength( LTRIM(RTRIM(@CharIds))) > 1) 
  Begin
       Select @Id = Convert(Int,SubString(@CharIds,1,CharIndex(Char(1),@CharIds)-1))
       Select @CharIds = SubString(@CharIds,CharIndex(Char(1),@CharIds),Datalength(@CharIds))
       Select @CharIds = Right(@CharIds,Datalength(@CharIds)-1)
       Insert Into #IDS values(@Id)
  End
 	 Select  [Id] = a.Char_Id,
 	  	  	 a.As_Id,
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
 	  	  	 Esignature_Level
  	  	 From Active_Specs a
 	  	 Join #IDS c on c.Ids = a.Char_Id
 	  	 Join Characteristics cs on cs.Char_Id = a.Char_Id
 	  	 Join Specifications s on s.Spec_Id = a.Spec_Id
 	   Where   (a.Spec_Id = @SpecId) and (a.Effective_Date  = @Eff_Date)
 	 -- Select Transaction
 	 Select  [Id] = t.Char_Id,
 	  	  	 t.AS_Id,
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
 	  	  	 Esignature_Level
 	  	 From Trans_Metric_Properties t
 	  	 Join #IDS c on c.Ids = t.Char_Id
 	  	 Join Specifications s on s.Spec_Id = t.Spec_Id
 	  	 Join Characteristics cs on cs.Char_Id = t.Char_Id
 	   Where  (t.Spec_Id = @SpecId) and (Trans_Id = @TransId) and (t.Effective_Date = @Eff_Date)
Drop Table #IDS
