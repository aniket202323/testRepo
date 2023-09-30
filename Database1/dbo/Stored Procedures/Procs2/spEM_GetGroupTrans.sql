CREATE PROCEDURE dbo.spEM_GetGroupTrans
  @PUG_Id int,
  @Trans_Id int,
  @Prod_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE  	 @Now          	  DateTime,
 	  	 @MasterPU 	 int,
 	  	 @Prop_Id           int,
 	  	 @Char_Id           int,
 	  	 @ParentChar 	 int,
 	  	 @CharId 	 int
 Create Table #TransProp( Spec_Id 	 int,
 	  	  	 Char_Id 	  	 int,
 	  	  	 L_Entry 	  	 nvarchar(25),
 	  	  	 L_Reject 	 nvarchar(25),
 	  	  	 L_Warning 	 nvarchar(25),
 	  	  	 L_User 	  	 nvarchar(25),
 	  	  	 Target 	  	 nvarchar(25),
 	  	  	 U_User 	  	 nvarchar(25),
 	  	  	 U_Warning 	 nvarchar(25),
 	  	  	 U_Reject 	 nvarchar(25),
 	  	  	 U_Entry 	  	 nvarchar(25),
 	  	  	 L_Control 	 nvarchar(25),
 	  	  	 T_Control 	 nvarchar(25),
 	  	  	 U_Control 	 nvarchar(25),
 	  	  	 Test_Freq 	 int,
 	  	  	 Esignature_Level Int,
 	  	  	 Comment_Id 	 int,
 	  	  	 Expiration_Date 	 DateTime,
 	  	  	 Is_Defined 	 Int,
 	  	  	 Not_Defined  	 Int)
Create Table #Chrs (Char_Id Int)
Insert into #Chrs Select Distinct To_Char_Id From Trans_Char_Links Where Trans_Id = @Trans_Id
Insert into #Chrs Select Distinct From_Char_Id From Trans_Char_Links Where Trans_Id = @Trans_Id
Insert Into #Chrs Select Distinct Char_Id From Trans_Properties Where  Trans_Id = @Trans_Id
Execute ('Declare GGT_Char_Cursor Cursor Global  ' +
  'For Select Char_Id From #Chrs ' +
  'For Read only')
Open GGT_Char_Cursor
NextChar:
  Fetch Next From GGT_Char_Cursor into @CharId
If @@Fetch_Status = 0
  Begin
     Insert into #TransProp Execute spEM_TransPPExpand @Trans_Id,@CharId,1
     Goto NextChar
  End
Close GGT_Char_Cursor
Deallocate GGT_Char_Cursor
Create Table #TransVar (Var_Id 	  	 Int,
 	  	  	 Prod_Id 	  	 Int,
 	  	  	 Char_Id 	  	 Int,
 	  	  	 Spec_Id 	 Int,
 	  	  	 U_Entry 	  	 nvarchar(25),
 	  	  	 U_Reject 	 nvarchar(25),
 	  	  	 U_Warning 	 nvarchar(25),
 	  	  	 U_User 	  	 nvarchar(25),
 	  	  	 Target 	  	 nvarchar(25),
 	  	  	 L_User 	  	 nvarchar(25),
 	  	  	 L_Warning 	 nvarchar(25),
 	  	  	 L_Reject 	 nvarchar(25),
 	  	  	 L_Entry 	  	 nvarchar(25),
 	  	  	 L_Control 	 nvarchar(25),
 	  	  	 T_Control 	 nvarchar(25),
 	  	  	 U_Control 	 nvarchar(25),
 	  	  	 Test_Freq 	 int,
 	  	  	 Esignature_Level Int, 
 	  	  	 Comment_Id 	 Int,
 	  	  	 Expiration_Date DateTime,
 	  	  	 Not_Defined  	 Int,
 	  	  	 Is_Defined 	  	 Int)
 Insert into #TransVar  Execute spEM_TransVSExpand @Trans_Id,@PUG_Id,@Prod_Id,1
 -- Initialize local variables.
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  --
  -- Get the pending Product Properties
  --
  Select @MasterPu =  PU_Id FROM PU_Groups where PUG_Id = @PUG_Id
  Select @MasterPu = COALESCE((SELECT Master_Unit FROM Prod_Units WHERE PU_Id = @MasterPu),@MasterPu)
-- 
-- Process Property Characteristics Transactions (apply to unitchar)
--
 Select tc.Prop_id,tc.Char_Id From Trans_Characteristics tc
      Join Specifications s On s.Prop_Id = tc.Prop_Id
      Join Variables v on v.spec_id = s.spec_id     
 	   Where   tc.Trans_Id = @Trans_Id  and tc.Prod_Id = @Prod_Id AND tc.PU_Id = @MasterPU and v.pug_id = @pug_id
--
-- Process Characteristic Transaction (apply to variables)
--
--
-- Process Characteristic Transaction (apply to variables)
--
   SELECT
         v.Var_Id,
         s.Spec_Id,
         c.Char_Id,
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
         a.Test_Freq,
 	  	  a.Esignature_Level,
         a.Comment_Id,
         a.Expiration_Date,
         Not_Defined = null
       FROM Trans_Characteristics t
       Join Characteristics c On c.char_Id = t.char_Id
       Join Specifications s On s.Prop_Id = t.Prop_Id
      Join Variables v on v.spec_id = s.spec_id  
     LEFT JOIN Active_Specs a ON (s.Spec_Id = a.Spec_Id) and (a.Char_Id =t.Char_Id)  AND (Effective_Date <= @Now) AND
          ((Expiration_Date IS NULL) OR ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
       WHERE (t.Pu_Id  = @MasterPU) and (t.Trans_Id = @Trans_Id) and t.Prod_Id = @Prod_Id
 	 and v.pug_id = @pug_id
--
-- Get the transaction for trans_properties
--
  SELECT t.Spec_Id,
         t.Char_Id,
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
         t.Test_Freq,
 	  	  t.Esignature_Level,
         t.Comment_Id,
         t.Expiration_Date,
         u.Prop_Id,
         t.Not_Defined
    FROM #TransProp t
    Left Join Specifications s on s.Spec_Id = t.Spec_Id
    left Join Trans_Characteristics tc on tc.char_Id = t.char_Id 
    left Join PU_Characteristics u On u.Char_Id = t.Char_Id and s.Prop_Id = u.Prop_Id and u.Prod_Id = @Prod_Id   and u.Pu_Id = @MasterPu
  --
  -- Get the pending variable specifications for this unit.
  --
 select t.Var_Id,
 	  	 t.Prod_Id,
 	  	 t.Char_Id,
 	  	 t.Spec_Id,
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
 	  	 t.Test_Freq,
 	  	 t.Esignature_Level,
  	  	 t.Comment_Id,
 	  	 t.Expiration_Date,
 	  	 t.Not_Defined
  from #TransVar t
  Left Join Variables s on s.Var_Id = t.Var_Id
-- get transaction characteristics
Drop Table #TransProp
Drop Table #TransVar
