CREATE PROCEDURE dbo.[spServer_StbGetEventTestFreqValues_Bak_177] 
@MasterUnit int,
@Prod_Id int,
@TimeStamp datetime,
@EventType int = 1,
@EventSubtype int = 0
AS
Declare
  @RunStartTime datetime,
  @PrevProdId int,
  @PrevEventTime datetime,
  @PrevEventStatus int
Select @RunStartTime = Start_Time 
  From Production_Starts 
  Where (PU_Id = @MasterUnit) And 
 	 (Start_Time < @TimeStamp) And      
  ((End_Time >= @TimeStamp) Or (End_Time Is Null))
Declare @TestFreqInfo Table(Var_Id int, PU_Id int , Test_Freq int NULL, Extended_Test_Freq int, Force_Stub int NULL, PrevValue nVarChar(30) COLLATE DATABASE_DEFAULT NULL, PrevTestId bigint NULL, URL nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UWL nVarChar(30) COLLATE DATABASE_DEFAULT NULL, UUL nVarChar(30) COLLATE DATABASE_DEFAULT NULL, Target nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LUL nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LWL nVarChar(30) COLLATE DATABASE_DEFAULT NULL, LRL nVarChar(30) COLLATE DATABASE_DEFAULT NULL)
Insert Into @TestFreqInfo (Var_Id,PU_Id,Test_Freq,Extended_Test_Freq)
(Select Var_Id = a.Var_Id,
       PU_Id = a.PU_Id,
       Test_Freq = Case When b.Test_Freq Is NULL
                     Then a.Sampling_Interval
                     Else b.Test_Freq
                   End,
       Extended_Test_Freq = a.Extended_Test_Freq
  From Variables_Base a 
  Left Outer Join Var_Specs b on (a.Var_Id = b.Var_Id) And 
 	  	  	  	  (b.Prod_Id = @Prod_Id) And
         	  	  	  (b.Effective_Date <= @TimeStamp) And 
         	  	  	  ((b.Expiration_Date > @TimeStamp) Or (b.Expiration_Date Is Null))
  Where (a.DS_Id In (2,11,14,16)) And 
        (a.SA_Id = 1) And 
        (a.Event_Type = @EventType) And
        ((a.Event_SubType_Id = @EventSubtype) Or ((a.Event_SubType_Id is null) And (@EventSubtype = 0)) Or (Event_Type = 1)) And
        ((a.Repeating Is Null) Or (a.Repeating = 0)) And
        (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (((b.Test_Freq > 0) And (b.Test_Freq Is Not Null)) or ((a.Sampling_Interval > 0) And (a.Sampling_Interval Is Not Null)) or ((a.Extended_Test_Freq > 1) And (a.Extended_Test_Freq Is Not NULL)))
)
Insert Into @TestFreqInfo (Var_Id,PU_Id,Test_Freq,Extended_Test_Freq)
(Select Var_Id = a.Var_Id,
       PU_Id = a.PU_Id,
       Test_Freq = Case When b.Test_Freq Is NULL
                     Then a.Sampling_Interval
                     Else b.Test_Freq
                   End,
       Extended_Test_Freq = a.Extended_Test_Freq
  From Variables_Base a 
  Left Outer Join Var_Specs b on (a.Var_Id = b.Var_Id) And 
 	  	  	  	  (b.Prod_Id = @Prod_Id) And
         	  	  	  (b.Effective_Date <= @RunStartTime) And 
         	  	  	  ((b.Expiration_Date > @RunStartTime) Or (b.Expiration_Date Is Null))
  Where (a.DS_Id In (2,11,14,16)) And 
        (a.SA_Id = 2) And 
        (a.Event_Type = @EventType) And
        ((a.Event_SubType_Id = @EventSubtype) Or ((a.Event_SubType_Id is null) And (@EventSubtype = 0)) Or (Event_Type = 1)) And
        ((a.Repeating Is Null) Or (a.Repeating = 0)) And
        (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (((b.Test_Freq > 0) And (b.Test_Freq Is Not Null)) or ((a.Sampling_Interval > 0) And (a.Sampling_Interval Is Not Null)) or ((a.Extended_Test_Freq > 1) And (a.Extended_Test_Freq Is Not NULL)))
)
Delete From @TestFreqInfo Where ((Test_Freq = 0) Or (Test_Freq Is NULL)) And (Extended_Test_Freq = 1)
Select @PrevEventTime = NULL
Select @PrevEventStatus = 5 -- Complete
if (@EventType = 1) -- Production
 	 Select @PrevEventTime = TimeStamp, @PrevEventStatus = Event_Status From Events Where (PU_Id = @MasterUnit) And (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @MasterUnit) And (TimeStamp < @TimeStamp) And ((Testing_Status <> 2) Or (Testing_Status Is NULL)))) 
else if (@EventType = 2) -- Downtime
 	 Select TOP 1 @PrevEventTime = 
 	 --Max(End_Time) 
 	 End_Time
 	 From Timed_Event_Details Where (PU_Id = @MasterUnit) And (End_Time < @TimeStamp) Order by End_Time Desc
else if (@EventType = 3) -- Waste
 	 Select TOP 1 @PrevEventTime = 
 	 --Max(Timestamp) 
 	 [TimeStamp]
 	 From Waste_Event_Details Where (PU_Id = @MasterUnit) And ([TimeStamp] < @TimeStamp) Order by [TimeStamp] Desc
else if (@EventType = 14) -- UDE
 	 Select Top 1 @PrevEventTime =
 	 --Max(End_Time) 
 	 End_Time
 	 From User_Defined_Events With(Index(UDE_IDX_PUIdESIdEndTime))
 	 Where (PU_Id = @MasterUnit) And (End_Time < @TimeStamp) And (Event_Subtype_id = @EventSubtype) And ((Testing_Status <> 2) Or (Testing_Status Is NULL))
 	 Order by End_Time Desc
else if (@EventType = 22) -- Uptime
 	 Select TOP 1 @PrevEventTime = 
 	 --Max(Start_Time) 
 	 Start_Time
 	 From Timed_Event_Details Where (PU_Id = @MasterUnit) And (Start_Time < @TimeStamp) Order by Start_Time Desc
If (@PrevEventTime Is Not NULL)
  Begin
    Update a
      Set a.PrevValue = b.Result,
          a.PrevTestId = b.Test_Id
      From @TestFreqInfo a, Tests b
      Where (a.Force_Stub Is NULL) And
            (a.Extended_Test_Freq > 1) And
            (b.Var_Id = a.Var_Id) And 
            (b.Result_On = @PrevEventTime)
    Select @PrevProdId = Prod_Id
      From Production_Starts 
      Where (PU_Id = @MasterUnit) And 
 	     (Start_Time < @PrevEventTime) And 
 	  	  	 ((End_Time >= @PrevEventTime) Or (End_Time Is Null))
    If (@PrevEventStatus In (10,12)) -- Broke
      Update @TestFreqInfo
        Set Force_Stub = 1
        Where (Force_Stub Is NULL) And
              (Extended_Test_Freq In (5,6,7,8)) And
              (PrevTestId Is NOT NULL)
    Update a
      Set a.URL = b.U_Reject,
          a.UWL = b.U_Warning,
          a.UUL = b.U_User,
          a.Target = b.Target,
          a.LUL = b.L_User,
          a.LWL = b.L_Warning,
          a.LRL = b.L_Reject
      From @TestFreqInfo a, Var_Specs b
      Where (a.Force_Stub Is NULL) And
            (a.Extended_Test_Freq > 1) And
            (b.Var_Id = a.Var_Id) And 
            (b.Prod_Id = @PrevProdId) And 
            (b.Effective_Date <= @PrevEventTime) And
            ((b.Expiration_Date > @PrevEventTime) Or (b.Expiration_Date Is NULL))
    Update @TestFreqInfo
      Set Force_Stub = 1
      Where (Force_Stub Is NULL) And
            (Extended_Test_Freq In (2,5)) And
            (PrevValue Is Not NULL) And
            (((UUL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) > Convert(float,Case IsNumeric(UUL) when 1 then UUL else '0.0' end))) Or
             ((LUL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) < Convert(float,Case IsNumeric(LUL) when 1 then LUL else '0.0' end))))
    Update @TestFreqInfo
      Set Force_Stub = 1
      Where (Force_Stub Is NULL) And
            (Extended_Test_Freq In (3,6)) And
            (PrevValue Is Not NULL) And
            (((UWL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) > Convert(float,Case IsNumeric(UWL) when 1 then UWL else '0.0' end))) Or
             ((LWL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) < Convert(float,Case IsNumeric(LWL) when 1 then LWL else '0.0' end))))
    Update @TestFreqInfo
      Set Force_Stub = 1
      Where (Force_Stub Is NULL) And
            (Extended_Test_Freq In (4,7)) And
            (PrevValue Is Not NULL) And
            (((URL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) > Convert(float,Case IsNumeric(URL) when 1 then URL else '0.0' end))) Or
             ((LRL Is Not NULL) And (Convert(float,Case IsNumeric(PrevValue) when 1 then PrevValue else '0.0' end) < Convert(float,Case IsNumeric(LRL) when 1 then LRL else '0.0' end))))
  End
Update @TestFreqInfo Set Test_Freq = 1 Where Force_Stub = 1
Select Var_Id = Var_Id,
       Test_Freq = Test_Freq
  From @TestFreqInfo
  Order by PU_Id,Var_Id
