CREATE PROCEDURE dbo.spServer_CmnGetWEInfo
@WED_Id int,
@PU_Id int OUTPUT,
@Event_Id int OUTPUT,
@WET_Id int OUTPUT,
@WEMT_Id int OUTPUT,
@Amount real OUTPUT,
@Source_PU_Id int OUTPUT,
@Reason_Level1 int OUTPUT,
@Reason_Level2 int OUTPUT,
@Reason_Level3 int OUTPUT,
@Reason_Level4 int OUTPUT,
@Marker1 real OUTPUT,
@Marker2 real OUTPUT,
@User_Id int OUTPUT,
@EndTime datetime OUTPUT,
@Master_Unit int OUTPUT,
@StartTime datetime OUTPUT
AS
Select @PU_Id = PU_Id,
       @Event_Id = COALESCE(Event_Id,0),
       @WET_Id = COALESCE(WET_Id,0),
       @WEMT_Id = COALESCE(WEMT_Id,0),
       @Amount = COALESCE(Amount,0),
       @Source_PU_Id = COALESCE(Source_PU_Id,0),
       @Reason_Level1 = COALESCE(Reason_Level1,0),
       @Reason_Level2 = COALESCE(Reason_Level2,0),
       @Reason_Level3 = COALESCE(Reason_Level3,0),
       @Reason_Level4 = COALESCE(Reason_Level4,0),
       @User_Id = COALESCE(User_Id,0),
       @EndTime = Timestamp
  From Waste_Event_Details
  Where (WED_Id = @WED_Id)
If (@PU_Id Is NULL)
 	 Begin
 	  	 Select @PU_Id = 0
 	  	 return
 	 End
 	 
Select @Master_Unit = Master_Unit From Prod_Units_Base Where (PU_Id = @PU_Id)
If @Master_Unit Is Null
  Select @Master_Unit = 0
Select @StartTime = NULL
Select @StartTime = Timestamp From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp = (Select Max(TimeStamp) From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp < @EndTime)))
If (@StartTime Is NULL)
 	 Select @StartTime = dateadd(hour,-1,@EndTime)
