CREATE PROCEDURE dbo.spServer_StbChkExtTimeTestFreq
@Var_Id int,
@PU_Id int,
@ExtTestFreq int,
@TimeStamp datetime,
@Result nVarChar(30),
@ForceStub int OUTPUT
 AS
Declare
  @MasterUnit int,
  @Prod_Id int,
  @NextEventTime datetime,
 	 @EventType int,
  @UpperLimit nVarChar(30),
  @LowerLimit nVarChar(30)
select @EventType = Event_Type from variables_Base where var_id = @Var_Id
Select @ForceStub = 0
if (@EventType > 0)
  return
Select @MasterUnit = NULL
Select @MasterUnit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@MasterUnit Is NULL)
  Select @MasterUnit = @PU_Id
Select @Prod_Id = Prod_Id
  From Production_Starts
  Where (PU_Id = @MasterUnit) And
        (Start_Time < @TimeStamp) And
        ((End_Time >= @TimeStamp) Or (End_Time Is NULL))
Select @UpperLimit = NULL
Select @LowerLimit = NULL
If (@ExtTestFreq In (2,5))
  Begin
    Select @UpperLimit = U_User,
           @LowerLimit = L_User
      From Var_Specs
      Where (Var_Id = @Var_Id) And
            (Prod_Id = @Prod_Id) And
            (Effective_Date <= @TimeStamp) And
            ((Expiration_Date > @TimeStamp) Or (Expiration_Date Is NULL))
  End
If (@ExtTestFreq In (3,6))
  Begin
    Select @UpperLimit = U_Warning,
           @LowerLimit = L_Warning
      From Var_Specs
      Where (Var_Id = @Var_Id) And
            (Prod_Id = @Prod_Id) And
            (Effective_Date <= @TimeStamp) And
            ((Expiration_Date > @TimeStamp) Or (Expiration_Date Is NULL))
  End
If (@ExtTestFreq In (4,7))
  Begin
    Select @UpperLimit = U_Reject,
           @LowerLimit = L_Reject
      From Var_Specs
      Where (Var_Id = @Var_Id) And
            (Prod_Id = @Prod_Id) And
            (Effective_Date <= @TimeStamp) And
            ((Expiration_Date > @TimeStamp) Or (Expiration_Date Is NULL))
  End
If (@UpperLimit Is NULL) And (@LowerLimit Is NULL)
  Return
If (isnumeric(@result) <> 1)
  Return
If (@UpperLimit Is NULL)
begin
  If  (isnumeric(@LowerLimit) = 1)
   Begin
    If (Convert(float,@LowerLimit) > Convert(float,@Result))
      Select @ForceStub = 1
   End
end
Else
begin
  If (@LowerLimit Is NULL)
 	 begin 
   If  (isnumeric(@UpperLimit)= 1)
    Begin
      If (Convert(float,@UpperLimit) < Convert(float,@Result))
        Select @ForceStub = 1
    End
  end
  Else
    Begin
      If (isnumeric(@LowerLimit) = 1)
        Begin
         If (Convert(float,@LowerLimit) > Convert(float,@Result))
           Select @ForceStub = 1
        End
      If (isnumeric(@UpperLimit) = 1)
       Begin
         If (Convert(float,@UpperLimit) < Convert(float,@Result))
          Select @ForceStub = 1
       End
    End
end
/*************************/
