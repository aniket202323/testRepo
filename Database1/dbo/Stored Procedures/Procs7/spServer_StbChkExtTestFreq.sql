CREATE PROCEDURE dbo.spServer_StbChkExtTestFreq
@Var_Id int,
@PU_Id int,
@ExtTestFreq int,
@TimeStamp datetime,
@Result nVarChar(30),
@StubYear int OUTPUT,
@StubMonth int OUTPUT,
@StubDay int OUTPUT,
@StubHour int OUTPUT,
@StubMin int OUTPUT,
@StubSec int OUTPUT,
@ForceStub int OUTPUT
 AS
Declare
  @MasterUnit int,
  @Prod_Id int,
  @NextEventTime datetime,
  @Event_Status int,
  @UpperLimit nVarChar(30),
  @LowerLimit nVarChar(30)
Select @ForceStub = 0
Select @StubYear = 0
Select @StubMonth = 0
Select @StubDay = 0
Select @StubHour = 0
Select @StubMin = 0
Select @StubSec = 0
Select @MasterUnit = NULL
Select @MasterUnit = Master_Unit From Prod_Units_Base Where PU_Id = @PU_Id
If (@MasterUnit Is NULL)
  Select @MasterUnit = @PU_Id
Select @Prod_Id = Prod_Id
  From Production_Starts
  Where (PU_Id = @MasterUnit) And
        (Start_Time < @TimeStamp) And
        ((End_Time >= @TimeStamp) Or (End_Time Is NULL))
Select @NextEventTime = NULL
Select @NextEventTime = TimeStamp
  From Events
  Where (PU_Id = @MasterUnit) And
        (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @MasterUnit) And (TimeStamp > @TimeStamp) And ((Testing_Status <> 2) Or (Testing_Status Is NULL))))
If (@NextEventTime Is NULL)
  Return
Select @StubYear = DatePart(Year,@NextEventTime)
Select @StubMonth = DatePart(Month,@NextEventTime)
Select @StubDay = DatePart(Day,@NextEventTime)
Select @StubHour = DatePart(Hour,@NextEventTime)
Select @StubMin = DatePart(Minute,@NextEventTime)
Select @StubSec = DatePart(Second,@NextEventTime)
Select @Event_Status = NULL
Select @Event_Status = Event_Status From Events Where (PU_Id = @MasterUnit) And (TimeStamp = @TimeStamp)
If (@Event_Status In (10,12)) And (@ExtTestFreq In (5,6,7,8))
  Begin 
    Select @ForceStub = 1
    Return
  End
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
  If  (isnumeric(@LowerLimit) = 1)
   Begin
    If (Convert(float,@LowerLimit) > Convert(float,@Result))
      Select @ForceStub = 1
   End
Else
  If (@LowerLimit Is NULL) 
   If  (isnumeric(@UpperLimit)= 1)
    Begin
      If (Convert(float,@UpperLimit) < Convert(float,@Result))
        Select @ForceStub = 1
    End
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
