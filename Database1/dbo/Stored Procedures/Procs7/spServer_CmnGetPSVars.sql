CREATE PROCEDURE dbo.spServer_CmnGetPSVars
@PU_Id int,
@Prod_Id int,
@TimeStamp datetime
AS
Select 
  a.Var_Id,
  a.DS_Id,
  a.Data_Type_Id,
  a.Sampling_Type,
  a.Tot_Factor,
  a.Event_Type,
  a.Unit_Reject,
  a.Var_Reject,
  a.Rank,
  a.Input_Tag,
  a.DQ_Tag,
  b.U_Entry,
  b.U_Reject,
  b.U_Warning,
  b.U_User,
  b.Target,
  b.L_User,
  b.L_Warning,
  b.L_Reject,
  b.L_Entry,
  a.Var_Precision,
  a.Comparison_Operator_Id,
  a.Comparison_Value,
  a.CPK_SubGroup_Size
From Variables_Base a
Left Join Var_Specs b on
  (b.Var_Id = a.Var_Id) And
  (b.Prod_Id = @Prod_Id) And
  (b.Effective_Date <= @TimeStamp) And 
  ((b.Expiration_Date > @TimeStamp) Or (b.Expiration_Date Is Null))
Where
  (a.PU_Id = @PU_Id) And
  (a.ShouldArchive = 1) And 
  (a.Unit_Summarize <> 0) And
  ((a.Data_Type_Id In (1,2,3,6,7)) Or (a.Data_Type_Id > 50))
