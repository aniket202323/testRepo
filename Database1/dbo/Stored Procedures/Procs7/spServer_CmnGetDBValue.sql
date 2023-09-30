CREATE PROCEDURE dbo.spServer_CmnGetDBValue
@Var_Id int,
@TimeStamp nVarChar(30),
@Mode int,
@MU_Id int,
@Result nvarchar(50) OUTPUT,
@ActualYear int OUTPUT,
@ActualMonth int OUTPUT,
@ActualDay int OUTPUT,
@ActualHour int OUTPUT,
@ActualMinute int OUTPUT,
@ActualSecond int OUTPUT
 AS
Declare
  @BeforeResult nVarChar(50),
  @BeforeTimeStamp datetime,
  @BeforeDiff int,
  @AfterResult nVarChar(50),
  @AfterTimeStamp datetime,
  @AfterDiff int,
  @ActualTime datetime,
  @StartTimeRange datetime,
  @StopTimeRange datetime
Select @ActualYear = 0
Select @ActualMonth = 0
Select @ActualDay = 0
Select @ActualHour = 0
Select @ActualMinute = 0
Select @ActualSecond = 0
Select @Result = NULL
Select @ActualTime = NULL
Select @StartTimeRange = DateAdd(Month,-9,dbo.fnServer_CmnGetDate(GetUTCDate()))
Select @StopTimeRange = DateAdd(Month,9,dbo.fnServer_CmnGetDate(GetUTCDate()))
If (@Mode = 1) Or (@Mode = 4)  -- Before or ExactOrBefore
  Begin
    Select @Result = Result,
           @ActualTime = Result_On
      From Tests
      Where (Var_Id = @Var_Id) And 
 	     (Result_On = (Select Max(Result_On) From Tests Where (Var_Id = @Var_Id) And (Result_On Between @StartTimeRange And @TimeStamp) And (Result Is NOT NULL)))
  End
If (@Mode = 2) -- After
  Begin
    Select @Result = Result,
           @ActualTime = Result_On
      From Tests
      Where (Var_Id = @Var_Id) And 
 	     (Result_On = (Select Min(Result_On) From Tests Where (Var_Id = @Var_Id) And (Result_On Between @TimeStamp And @StopTimeRange) And (Result Is NOT NULL)))
  End
If (@Mode = 3) -- Exact
  Begin
    Select @Result = Result, 
           @ActualTime = Result_On
      From Tests 
      Where (Var_Id = @Var_Id) And (Result Is Not Null) And (Result_On = @TimeStamp)
  End
If (@Mode = 5) -- Closest
  Begin
    Select @Result = Result,
           @ActualTime = Result_On
      From Tests 
      Where (Var_Id = @Var_Id) And (Result Is Not Null) And (Result_On = @TimeStamp)
    If (@Result Is Null)
      Begin
        Select @BeforeResult = Result, @BeforeTimeStamp = Result_On From Tests Where (Var_Id = @Var_Id) And (Result_On = (Select Max(Result_On) From Tests Where (Var_Id = @Var_Id) And (Result_On Between @StartTimeRange And @TimeStamp) And (Result Is NOT NULL)))
        Select @AfterResult  = Result, @AfterTimeStamp  = Result_On From Tests Where (Var_Id = @Var_Id) And (Result_On = (Select Min(Result_On) From Tests Where (Var_Id = @Var_Id) And (Result_On Between @TimeStamp And @StopTimeRange) And (Result Is NOT NULL)))
 	 If (@BeforeResult Is Not Null) Or (@AfterResult Is Not Null)
          Begin
 	     If (@BeforeResult Is Null)
              Begin
                Select @Result = @AfterResult
                Select @ActualTime = @AfterTimeStamp
              End
            Else
              If (@AfterResult Is Null)
                Begin
                  Select @Result = @BeforeResult
                  Select @ActualTime = @BeforeTimeStamp
                End
              Else
                Begin
 	  	   Select @BeforeDiff = DateDiff(Second,@BeforeTimeStamp,@TimeStamp)
 	  	   Select @AfterDiff  = DateDiff(Second,@TimeStamp,@AfterTimeStamp)
 	  	   If (@BeforeDiff <= @AfterDiff)
                    Begin
                      Select @Result = @BeforeResult
                      Select @ActualTime = @BeforeTimeStamp
                    End
                  Else
                    Begin
                      Select @Result = @AfterResult
                      Select @ActualTime = @AfterTimeStamp
                    End
                End
          End
      End
  End
If (@ActualTime Is NULL)
  Select @Result = NULL
Else
  Begin
    Select @ActualYear = DatePart(Year,@ActualTime)
    Select @ActualMonth = DatePart(Month,@ActualTime)
    Select @ActualDay = DatePart(Day,@ActualTime)
    Select @ActualHour = DatePart(Hour,@ActualTime)
    Select @ActualMinute = DatePart(Minute,@ActualTime)
    Select @ActualSecond = DatePart(Second,@ActualTime)
  End
If (@Result Is Null)
  Select @Result = ''
