CREATE PROCEDURE dbo.spServer_CmnGetXRefVarId
@MasterUnit int,
@DS_Id int,
@Event_Type int,
@FirstTry nVarChar(100),
@SecondTry nVarChar(100),
@Var_Id int OUTPUT,
@Var_Precision int OUTPUT
 AS
Select @Var_Precision = 0
If (@MasterUnit = 0)
  Begin
    Select @Var_Id = NULL
    If (@DS_Id <> 0)
      Select @Var_Id = Var_Id From Variables_Base Where (DS_Id = @DS_Id) And (Event_Type = @Event_Type) And (Input_Tag = @FirstTry)
    Else
      Select @Var_Id = Var_Id From Variables_Base Where (Event_Type = @Event_Type) And (Input_Tag = @FirstTry)
    If (@Var_Id Is Not NULL)
      Begin
        Select @Var_Precision = Var_Precision From Variables_Base Where Var_Id = @Var_Id
        Return
      End
    If (@DS_Id <> 0)
      Select @Var_Id = Var_Id From Variables_Base Where (DS_Id = @DS_Id) And (Event_Type = @Event_Type) And (Input_Tag = @SecondTry)
    Else
      Select @Var_Id = Var_Id From Variables_Base Where (Event_Type = @Event_Type) And (Input_Tag = @SecondTry)
    If (@Var_Id Is Not NULL)
      Select @Var_Precision = Var_Precision From Variables_Base Where Var_Id = @Var_Id
    Else
      Select @Var_Id = 0
    Return
  End
Select @Var_Id = NULL
If (@DS_Id <> 0)
  Select @Var_Id = Var_Id From Variables_Base Where (PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And (DS_Id = @DS_Id) And (Event_Type = @Event_Type) And (Input_Tag = @FirstTry)
Else
  Select @Var_Id = Var_Id From Variables_Base Where (PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And (Event_Type = @Event_Type) And (Input_Tag = @FirstTry)
If (@Var_Id Is Not NULL)
  Begin
    Select @Var_Precision = Var_Precision From Variables_Base Where Var_Id = @Var_Id
    Return
  End
Select @Var_Id = NULL
If (@DS_Id <> 0)
  Select @Var_Id = Var_Id From Variables_Base Where (PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And (DS_Id = @DS_Id) And (Event_Type = @Event_Type) And (Input_Tag = @SecondTry)
Else
  Select @Var_Id = Var_Id From Variables_Base Where (PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And (Event_Type = @Event_Type) And (Input_Tag = @SecondTry)
If (@Var_Id Is Not NULL)
  Select @Var_Precision = Var_Precision From Variables_Base Where Var_Id = @Var_Id
Else
  Select @Var_Id = 0
