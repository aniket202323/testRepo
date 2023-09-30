CREATE PROCEDURE dbo.spEM_ApproveMetricTrans
  @Trans_Id       int,
  @User_Id        int,
  @Group_Id       int
  AS
  DECLARE @AS_Id 	  	 int,
          @Char_Id 	  	 int,
          @Spec_Id 	  	 int,
          @Approved_On  	 datetime,
          @Effective_Date datetime,
          @Exp_Date 	  	 datetime,
          @Old_Eff_Date 	 datetime,
          @Old_Exp_Date datetime,
          @L_Entry  	  	 nVarChar(25),
          @L_Reject 	  	 nVarChar(25),
          @L_Warning 	 nVarChar(25),
          @L_User 	  	 nVarChar(25),
          @Target 	  	 nVarChar(25),
          @U_User 	  	 nVarChar(25),
          @U_Warning 	 nVarChar(25),
          @U_Reject 	  	 nVarChar(25),
          @U_Entry 	  	 nVarChar(25),
          @L_Control 	 nVarChar(25),
          @T_Control 	 nVarChar(25),
          @U_Control 	 nVarChar(25),
 	  	   @Esignature_Level 	 Int,
          @InsertId 	  	 int,
          @New_Trans_Id 	 Int
Create Table #RebuildFuture (Spec_Id Int,Char_Id Int, Effective_Date DateTime)
-- Remove any future specs and add them to Trans_Metric_Properties for reapproval
Declare ApproveMetricTransCursor1 Cursor 
  For Select Spec_Id,Char_Id,Effective_Date,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Esignature_Level
 	  from Trans_Metric_Properties
 	  Where Trans_Id = @Trans_Id 
 	  Order by Effective_Date,Spec_Id,Char_Id
Open ApproveMetricTransCursor1
MetCursor:
 	 Fetch next from ApproveMetricTransCursor1 Into  @Spec_Id,@Char_Id,@Effective_Date,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Esignature_Level
If @@Fetch_Status = 0
  Begin
 	 Declare @FutureCount int,@CurrentCount Int
 	 Select @FutureCount = count(*) from Active_Specs 
 	  	 Where Spec_Id =  @Spec_Id and Char_Id = @Char_Id and Effective_Date > @Effective_Date
 	 Select @AS_Id = Null
 	 Select @AS_Id = As_Id from Active_Specs 
 	  	 Where Spec_Id =  @Spec_Id and Char_Id = @Char_Id and Effective_Date = @Effective_Date
 	 If @AS_Id is Null and @FutureCount > 0
 	  	 Insert InTo #RebuildFuture(Spec_Id,Char_Id,Effective_Date) Values (@Spec_Id,@Char_Id,@Effective_Date)
 	 If @AS_Id is not null -- replace spec
 	   Begin
 	  	 If @L_Entry is not null
 	  	   Begin
 	  	  	 If @L_Entry = '' Select  @L_Entry = Null
 	  	     Update Active_Specs Set L_Entry = @L_Entry Where As_Id = @AS_Id
 	  	     Update Var_Specs Set L_Entry = @L_Entry Where As_Id = @AS_Id
 	  	   End
 	  	 If @L_Reject is not null
 	  	   Begin
 	  	  	 If @L_Reject = '' Select @L_Reject = Null
 	  	     Update Active_Specs Set L_Reject = @L_Reject Where As_Id = @AS_Id
 	  	     Update Var_Specs Set L_Reject = @L_Reject Where As_Id = @AS_Id
 	  	   End
 	  	 If @L_Warning is not null
 	  	   Begin
 	  	  	 If @L_Warning = '' Select @L_Warning = Null
 	  	     Update Active_Specs Set L_Warning = @L_Warning Where As_Id = @AS_Id
 	  	     Update Var_Specs Set L_Warning = @L_Warning Where As_Id = @AS_Id
 	  	   End
 	  	 If @L_User is not null
 	  	   Begin
 	  	  	 If @L_User = '' Select @L_User = Null
 	  	     Update Active_Specs Set L_User = @L_User Where As_Id = @AS_Id
 	  	     Update Var_Specs Set L_User = @L_User Where As_Id = @AS_Id
 	  	   End
 	  	 If @Target is not null
 	  	   Begin
 	  	  	 If @Target = '' Select @Target = Null
 	  	     Update Active_Specs Set Target = @Target Where As_Id = @AS_Id
 	  	     Update Var_Specs Set Target = @Target Where As_Id = @AS_Id
 	  	   End
 	  	 If @U_User is not null
 	  	   Begin
 	  	  	 If @U_User = '' Select @U_User = Null
 	  	     Update Active_Specs Set U_User = @U_User Where As_Id = @AS_Id
 	  	     Update Var_Specs Set U_User = @U_User Where As_Id = @AS_Id
 	  	   End
 	  	 If @U_Warning is not null
 	  	   Begin
 	  	  	 If @U_Warning = '' Select @U_Warning = Null
 	  	     Update Active_Specs Set U_Warning = @U_Warning Where As_Id = @AS_Id
 	  	     Update Var_Specs Set U_Warning = @U_Warning Where As_Id = @AS_Id
 	  	   End
 	  	 If @U_Reject is not null
 	  	   Begin
 	  	  	 If @U_Reject = '' Select @U_Reject = Null
 	  	     Update Active_Specs Set U_Reject = @U_Reject Where As_Id = @AS_Id
 	  	     Update Var_Specs Set U_Reject = @U_Reject Where As_Id = @AS_Id
 	  	   End
 	  	 If @U_Entry is not null
 	  	   Begin
 	  	  	 If @U_Entry = '' Select @U_Entry = Null
 	  	     Update Active_Specs Set U_Entry = @U_Entry Where As_Id = @AS_Id
 	  	     Update Var_Specs Set U_Entry = @U_Entry Where As_Id = @AS_Id
 	  	   End
 	  	 If @L_Control is not null
 	  	   Begin
 	  	  	 If @L_Control = '' Select @L_Control = Null
 	  	     Update Active_Specs Set L_Control = @L_Control Where As_Id = @AS_Id
 	  	     Update Var_Specs Set L_Control = @L_Control Where As_Id = @AS_Id
 	  	   End
 	  	 If @T_Control is not null
 	  	   Begin
 	  	  	 If @T_Control = '' Select @T_Control = Null
 	  	     Update Active_Specs Set T_Control = @T_Control Where As_Id = @AS_Id
 	  	     Update Var_Specs Set T_Control = @T_Control Where As_Id = @AS_Id
 	  	   End
 	  	 If @U_Control is not null
 	  	   Begin
 	  	  	 If @U_Control = '' Select @U_Control = Null
 	  	     Update Active_Specs Set U_Control = @U_Control Where As_Id = @AS_Id
 	  	     Update Var_Specs Set U_Control = @U_Control Where As_Id = @AS_Id
 	  	   End
 	  	 If @Esignature_Level <> 0 
 	  	   Begin
 	  	  	 If @Esignature_Level = -1 Select @Esignature_Level = Null
 	  	     Update Active_Specs Set Esignature_Level = Esignature_Level Where As_Id = @AS_Id
 	  	     Update Var_Specs Set Esignature_Level = Esignature_Level Where As_Id = @AS_Id
 	  	   End
 	   End
 	 Goto MetCursor
  End
Close ApproveMetricTransCursor1
Deallocate ApproveMetricTransCursor1
-- Remove any future specs and add them to Trans_Metric_Properties for reapproval
Declare ApproveMetricTransRebuild Cursor 
  For Select Spec_Id,Char_Id,Effective_Date = min(Effective_Date)
 	  from #RebuildFuture
 	  Group by Spec_Id,Char_Id
Open ApproveMetricTransRebuild
Rebuild:
 	 Fetch next from ApproveMetricTransRebuild Into @Spec_Id,@Char_Id, @Effective_Date
If @@Fetch_Status = 0
  Begin
 	 Insert into Trans_Metric_Properties (Trans_Id,Spec_Id,Char_Id,L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,Esignature_Level,
 	  	  	  AS_Id,Effective_Date)
 	  	 Select @Trans_Id,a.Spec_Id,a.Char_Id,
 	  	  	  	 L_Warning = Case When t.L_Warning is not null then t.L_Warning
 	  	  	  	  	  	  	  	 Else a.L_Warning
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 L_Reject = Case When t.L_Reject is not null then t.L_Reject
 	  	  	  	  	  	  	  	 Else a.L_Reject
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 L_Entry = Case When t.L_Entry is not null then t.L_Entry
 	  	  	  	  	  	  	  	 Else a.L_Entry
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 U_User 	 = Case When t.U_User is not null then t.U_User
 	  	  	  	  	  	  	  	 Else a.U_User
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 Target = Case When t.Target is not null then t.Target
 	  	  	  	  	  	  	  	 Else a.Target
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 L_User= Case When t.L_User is not null then t.L_User
 	  	  	  	  	  	  	  	 Else a.L_User
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 U_Entry = Case When t.U_Entry is not null then t.U_Entry
 	  	  	  	  	  	  	  	 Else a.U_Entry
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 U_Reject = Case When t.U_Reject is not null then t.U_Reject
 	  	  	  	  	  	  	  	 Else a.U_Reject
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 U_Warning = Case When t.U_Warning is not null then t.U_Warning
 	  	  	  	  	  	  	  	 Else a.U_Warning
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 L_Control = Case When t.L_Control is not null then t.L_Control
 	  	  	  	  	  	  	  	 Else a.L_Control
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 T_Control = Case When t.T_Control is not null then t.T_Control
 	  	  	  	  	  	  	  	 Else a.T_Control
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 U_Control = Case When t.U_Control is not null then t.U_Control
 	  	  	  	  	  	  	  	 Else a.U_Control
 	  	  	  	  	  	  	  	 End,
 	  	  	  	 Esignature_Level = Case When t.Esignature_Level is not null or t.Esignature_Level = 0 then t.Esignature_Level
 	  	  	  	  	  	  	  	 Else a.Esignature_Level
 	  	  	  	  	  	  	  	 End,
 	  	  	  a.AS_Id,a.Effective_Date
 	  	   From Active_Specs  a
 	  	   Left Join Trans_Metric_Properties t On a.Spec_Id = t.Spec_Id and a.Char_Id = t.Char_Id and a.Effective_Date = t.Effective_Date and t.Trans_Id = @Trans_Id
 	  	   Where  a.Spec_Id = @Spec_Id and a.Char_Id = @Char_Id and a.Effective_Date > @Effective_Date
 	  	   Delete From Active_Specs  where Spec_Id = @Spec_Id and Char_Id = @Char_Id and Effective_Date > @Effective_Date
 	 Goto Rebuild
  End
Close ApproveMetricTransRebuild
Deallocate ApproveMetricTransRebuild
-- make changes based on as_Id
select @Old_Eff_Date  = null
-- Build new trans_propertys for each - asId and call approve
Declare ApproveMetricTransCursor Cursor 
  For Select Spec_Id,Char_Id,L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,Esignature_Level,
 	  	  	  AS_Id,Effective_Date
 	  from Trans_Metric_Properties
 	  Where Trans_Id = @Trans_Id
 	  Order by Effective_Date 
Open ApproveMetricTransCursor
MetricCursor:
 	 Fetch next from ApproveMetricTransCursor Into @Spec_Id,@Char_Id,@L_Warning,@L_Reject,@L_Entry,@U_User,@Target,@L_User,@U_Entry,
 	  	  	  	  	 @U_Reject,@U_Warning,@L_Control,@T_Control,@U_Control,@Esignature_Level,@AS_Id,@Effective_Date
If @@Fetch_Status = 0
  Begin
 	 If (Select count(*) from active_Specs where Spec_Id =  @Spec_Id and Char_Id = @Char_Id and Effective_Date > @Effective_Date) = 0 
 	   Begin
 	  	 If @Old_Eff_Date <> @Effective_Date and @Old_Eff_Date is not null
 	  	   Begin
 	  	  	 Execute spEM_ApproveTrans  @New_Trans_Id,@User_Id,@Group_Id,Null,Null, @Old_Eff_Date
 	  	  	 Select @Old_Eff_Date = Null
 	  	   End
 	  	 if @Old_Eff_Date is null
 	  	   Begin
 	  	    Insert into Transactions (Trans_Desc,Transaction_Grp_Id,Trans_Type_Id) Values ('<' + Convert(nVarChar(10),@Trans_Id) + '>' + '<' + Convert(nVarChar(25),@Effective_Date) + '>' + 'Metrics',1,5)
 	  	    Select  @New_Trans_Id = Scope_Identity()
 	  	  	 Select @Old_Eff_Date = @Effective_Date
 	  	   End
 	  	   Insert Into Trans_Properties(Trans_Id,Spec_Id,Char_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,is_defined)
 	  	  	 Values (@New_Trans_Id,@Spec_Id,@Char_Id,@U_Entry,@U_Reject,@U_Warning,@U_User,@Target,@L_User,@L_Warning,@L_Reject, 	 @L_Entry,@L_Control,@T_Control,@U_Control,Null,@Esignature_Level,null,Null)
 	   End
 	 goto MetricCursor
  End
  If  @Old_Eff_Date is not null
 	 Begin
 	   Execute spEM_ApproveTrans  @New_Trans_Id,@User_Id,@Group_Id,Null,Null, @Old_Eff_Date
 	   Select @Old_Eff_Date = Null
 	 End
  Close ApproveMetricTransCursor
  Deallocate ApproveMetricTransCursor
  UPDATE Transactions
    SET Approved_By = @User_Id,Approved_On = dbo.fnServer_CmnGetDate(getUTCdate()), Effective_Date = dbo.fnServer_CmnGetDate(getUTCdate()),Transaction_Grp_Id = @Group_Id
    WHERE Trans_Id = @Trans_Id
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     where Audit_Trail_Id = @InsertId
 RETURN(0)
