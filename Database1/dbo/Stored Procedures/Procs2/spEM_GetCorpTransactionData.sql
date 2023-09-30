CREATE PROCEDURE dbo.spEM_GetCorpTransactionData
  @Trans_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
Declare @Now DateTime
Select @DecimalSep = Coalesce(@DecimalSep,'.')
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Create Table #Output 	 (Var_Id 	  	  	 Int,
 	  	  	  	  	    	 Prod_Id 	  	  	 Int,
 	  	  	  	  	    	 Data_Type_Id 	 Int,
 	  	  	  	  	  	 Var_Precision 	 Int,
 	  	  	  	  	  	 Var_Desc 	  	 nvarchar(50),
 	  	  	  	  	  	 Prod_Code 	  	 nvarchar(20),
 	  	  	  	  	  	 L_Entry  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Entry_Trans   	 nvarchar(25),
 	  	  	  	  	  	 L_Reject   	  	 nvarchar(25),
 	  	  	  	  	  	 L_Reject_Trans  nvarchar(25),
 	  	  	  	  	  	 L_Warning  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Warning_Trans nvarchar(25),
 	  	  	  	  	  	 L_User   	  	 nvarchar(25),
 	  	  	  	  	  	 L_User_Trans   	 nvarchar(25),
 	  	  	  	  	  	 Target   	  	 nvarchar(25),
 	  	  	  	  	  	 Target_Trans  	 nvarchar(25),
 	  	  	  	  	  	 U_User  	  	  	 nvarchar(25),
 	  	  	  	  	  	 U_User_Trans   	 nvarchar(25),
 	  	  	  	  	  	 U_Warning  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Warning_Trans nvarchar(25),
 	  	  	  	  	  	 U_Reject  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Reject_Trans  	 nvarchar(25),
 	  	  	  	  	  	 U_Entry  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Entry_Trans  	 nvarchar(25),
 	  	  	  	  	  	 L_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Control_Trans nvarchar(25),
 	  	  	  	  	  	 T_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 T_Control_Trans nvarchar(25),
 	  	  	  	  	  	 U_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Control_Trans 	 nvarchar(25),
 	  	  	  	  	  	 Test_Freq 	  	 Int,
 	  	  	  	  	  	 Test_Freq_Trans Int,
 	  	  	  	  	  	 Esignature_Level Int,
 	  	  	  	  	  	 Esignature_Level_Trans Int,
 	  	  	  	  	  	 Is_OverRidable 	 Int)
Insert InTo #Output 	 (Var_Id,Prod_Id,Data_Type_Id,Var_Precision,Var_Desc,Prod_Code,L_Entry,
 	  	  	  	  	  	 L_Entry_Trans,L_Reject,L_Reject_Trans,L_Warning,L_Warning_Trans,L_User,
 	  	  	  	  	  	 L_User_Trans,Target,Target_Trans,U_User,U_User_Trans,U_Warning,U_Warning_Trans,
 	  	  	  	  	  	 U_Reject,U_Reject_Trans,U_Entry,U_Entry_Trans,
 	  	  	  	  	  	 L_Control,L_Control_Trans,T_Control,T_Control_Trans,U_Control,U_Control_Trans,
 	  	  	  	  	  	 Test_Freq,Test_Freq_Trans,Esignature_Level,Esignature_Level_Trans,
 	  	  	  	  	  	 Is_OverRidable)
SELECT Distinct tv.Var_Id,tv.Prod_Id,v.Data_Type_Id,v.Var_Precision,v.Var_Desc,p.Prod_Code,
 	  	  	 L_Entry = coalesce(tv.L_Entry,vs.L_Entry),
 	  	  	 L_Entry_Trans = tv.L_Entry,
 	  	  	 L_Reject = coalesce(tv.L_Reject,vs.L_Reject),
 	  	  	 L_Reject_Trans = tv.L_Reject,
 	  	  	 L_Warning = coalesce(tv.L_Warning,vs.L_Warning),
 	  	  	 L_Warning_Trans = tv.L_Warning,
 	  	  	 L_User = coalesce(tv.L_User,vs.L_User),
 	  	  	 L_User_Trans = tv.L_User,
 	  	  	 Target = coalesce(tv.Target,vs.Target),
 	  	  	 Target_Trans = tv.Target,
 	  	  	 U_User = coalesce(tv.U_User,vs.U_User),
 	  	  	 U_User_Trans = tv.U_User,
 	  	  	 U_Warning = coalesce(tv.U_Warning,vs.U_Warning),
 	  	  	 U_Warning_Trans = tv.U_Warning,
 	  	  	 U_Reject = coalesce(tv.U_Reject,vs.U_Reject),
 	  	  	 U_Reject_Trans = tv.U_Reject,
 	  	  	 U_Entry = coalesce(tv.U_Entry,vs.U_Entry),
 	  	  	 U_Entry_Trans = tv.U_Entry,
 	  	  	 L_Control = coalesce(tv.L_Control,vs.L_Control),
 	  	  	 L_Control_Trans = tv.L_Control,
 	  	  	 T_Control = coalesce(tv.T_Control,vs.T_Control),
 	  	  	 T_Control_Trans = tv.T_Control,
 	  	  	 U_Control = coalesce(tv.U_Control,vs.U_Control),
 	  	  	 U_Control_Trans = tv.U_Control,
 	  	  	 Test_Freq = coalesce(case when tv.Test_Freq = -1 then '' else tv.Test_Freq end,vs.Test_Freq),
 	  	  	 Test_Freq_Trans = case when tv.Test_Freq = -1 then '' else tv.Test_Freq end,
 	  	  	 Esignature_Level = coalesce(tv.Esignature_Level,vs.Esignature_Level),
 	  	  	 Esignature_Level_Trans = case when tv.Esignature_Level = -1 then '' else tv.Esignature_Level end,
 	  	  	 tv.Is_OverRidable
        FROM Trans_Variables tv
        JOIN Variables v ON v.Var_Id = tv.Var_Id
 	  	 Join Products p on p.Prod_id = tv.prod_Id
 	  	 Left Join Var_Specs vs on vs.Var_Id = tv.Var_Id and vs.Prod_id = tv.prod_Id and (vs.effective_Date < @Now and (vs.Expiration_Date is null or vs.Expiration_Date > @Now))
        WHERE Trans_Id = @Trans_Id
   If @DecimalSep != '.' 
     BEGIN
       Update #Output Set L_Entry = REPLACE(L_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_Reject = REPLACE(L_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_Warning = REPLACE(L_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_User = REPLACE(L_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set Target = REPLACE(Target, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_User = REPLACE(U_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Warning = REPLACE(U_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Reject = REPLACE(U_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Entry = REPLACE(U_Entry, '.', @DecimalSep) Where Data_Type_Id = 2
       Update #Output Set L_Control = REPLACE(L_Control, '.', @DecimalSep) Where Data_Type_Id = 2
       Update #Output Set T_Control = REPLACE(T_Control, '.', @DecimalSep) Where Data_Type_Id = 2
       Update #Output Set U_Control = REPLACE(U_Control, '.', @DecimalSep) Where Data_Type_Id = 2
       Update #Output Set L_Entry_Trans = REPLACE(L_Entry_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_Reject_Trans = REPLACE(L_Reject_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_Warning_Trans = REPLACE(L_Warning_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_User_Trans = REPLACE(L_User_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set Target_Trans = REPLACE(Target_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_User_Trans = REPLACE(U_User_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Warning_Trans = REPLACE(U_Warning_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Reject_Trans = REPLACE(U_Reject_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Entry_Trans = REPLACE(U_Entry_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set L_Control_Trans = REPLACE(L_Control_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set T_Control_Trans = REPLACE(T_Control_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #Output Set U_Control_Trans = REPLACE(U_Control_Trans, '.', @DecimalSep) Where Data_Type_Id = 2 
     END
  Select * From #Output 	 Order by Var_Desc,Prod_Code
