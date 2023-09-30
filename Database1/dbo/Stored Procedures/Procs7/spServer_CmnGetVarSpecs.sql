CREATE PROCEDURE dbo.spServer_CmnGetVarSpecs
@Var_Id int,
@Prod_Id int,
@TimeStamp datetime
AS
Select 
  Var_Id,
  U_Entry,
  U_Reject,
  U_Warning,
  U_User,
  Target,
  L_User,
  L_Warning,
  L_Reject,
  L_Entry
From  Var_Specs
Where
  (Var_Id = @Var_Id) And
  (Prod_Id = @Prod_Id) And
  (Effective_Date <= @TimeStamp) And 
  ((Expiration_Date > @TimeStamp) Or (Expiration_Date Is Null))
