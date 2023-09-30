CREATE PROCEDURE dbo.spServer_EMgrGetEventRepeats
@Event_Id int
AS
Declare
  @TimeStamp Datetime,
  @LastTimeStamp DateTime,
  @MasterUnit int
Select @TimeStamp = TimeStamp,
       @MasterUnit = PU_Id
  From Events
  Where (Event_Id = @Event_Id)
Select @LastTimeStamp = Max(TimeStamp) From Events Where (PU_Id = @MasterUnit) And (TimeStamp < @TimeStamp)
Select Var_Id = a.Var_Id,
       PU_Id = a.PU_Id,
       Result = b.Result
  From Variables_Base a
  Join Tests b on b.Var_Id = a.Var_Id
  Where (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (a.DS_Id = 2) And
        (a.Repeating <> 0) And
        (a.Repeating Is Not Null) And
        (a.Event_Type = 1) And
        (b.Result_On = @LastTimeStamp) And
        (b.Result Is Not Null)
