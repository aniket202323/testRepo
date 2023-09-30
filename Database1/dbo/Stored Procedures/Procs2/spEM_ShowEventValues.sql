CREATE PROCEDURE dbo.spEM_ShowEventValues
 	 @EC_Id 	  	 Int,
 	 @StartTime  DateTime,
 	 @EndTime 	 DateTime,
 	 @Count     	 Int
  AS
Declare @PUId Int,
 	  	 @Event_Type Int
Create Table #T (TimeColumns nVarChar(100))
Select @PUId = PU_Id,@Event_Type = ET_Id From Event_Configuration where ec_Id = @EC_Id
Set Rowcount  @Count
IF @Event_Type = 1
  Begin
 	 Insert into #T(TimeColumns) Values ('Start Time')
 	 Insert into #T(TimeColumns) Values ('End Time')
 	 Insert into #T(TimeColumns) Values ('Entry On')
 	 Select * From #T
 	 Truncate Table #T
 	 If @Count = 0
 	   Begin
 	  	 Set Rowcount 500
 	     Select [Key] = Event_Id,[Event] = Event_Num,[Start Time] = Start_Time,[End Time] = Timestamp,[Status] = ProdStatus_Desc,[User] = Username, [Entry On] = Entry_On
 	      From Events e
 	      Left Join Users u  on u.user_Id = e.user_Id
 	      Join Production_Status p on e.Event_Status = p.ProdStatus_Id
 	      Where PU_Id = @PUId and TimeStamp Between @StartTime and @EndTime
         Order by TimeStamp asc
 	   End
 	 Else
 	  Select [Key] = Event_Id,[Event] = Event_Num,[Start Time] = Start_Time,[End Time] = Timestamp,[Status] = ProdStatus_Desc,[User] = Username, [Entry On] = Entry_On
 	   From Events e
 	   Left Join Users u  on u.user_Id = e.user_Id
 	   Join Production_Status p on e.Event_Status = p.ProdStatus_Id
 	   Where PU_Id = @PUId and TimeStamp < @StartTime
      Order by TimeStamp Desc
  End
Else IF @Event_Type = 2
  Begin
 	 Insert into #T(TimeColumns) Values ('Start Time')
 	 Insert into #T(TimeColumns) Values ('End Time')
 	 Select * From #T
 	 Truncate Table #T
 	 If @Count = 0
 	   Begin
 	  	 Set Rowcount 500
 	  	 Select [Key] = TEDet_Id,[Start Time] = t.Start_Time,[End Time] = t.End_Time, Duration ,[Fault] = TEFault_Name,[Level 1] = r1.Event_Reason_Name,[Level 2] = r2.Event_Reason_Name,[Level 3] = r3.Event_Reason_Name,[Level 4] = r4.Event_Reason_Name,[User] = Username
 	  	   From Timed_event_Details t
 	  	   Left Join Timed_Event_Fault f on f.TEFault_Id = t.TEFault_Id
 	  	   Left Join Users u  on u.user_Id = t.user_Id
 	  	   Left Join Event_Reasons r1 on r1.Event_Reason_Id = t.Reason_Level1
 	  	   Left Join Event_Reasons r2 on r2.Event_Reason_Id = t.Reason_Level2
 	  	   Left Join Event_Reasons r3 on r3.Event_Reason_Id = t.Reason_Level3
 	  	   Left Join Event_Reasons r4 on r4.Event_Reason_Id = t.Reason_Level4
 	  	   where t.PU_Id = @PUId and t.Start_Time Between @StartTime and @EndTime
 	  	   Order by t.Start_Time Desc
 	   End
 	 Else
 	   Select [Key] = TEDet_Id,[Start Time] = t.Start_Time,[End Time] = t.End_Time, Duration ,[Fault] = TEFault_Name,[Level 1] = r1.Event_Reason_Name,[Level 2] = r2.Event_Reason_Name,[Level 3] = r3.Event_Reason_Name,[Level 4] = r4.Event_Reason_Name,[User] = Username
 	    From Timed_event_Details t
 	    Left Join Timed_Event_Fault f on f.TEFault_Id = t.TEFault_Id
 	    Left Join Users u  on u.user_Id = t.user_Id
 	    Left Join Event_Reasons r1 on r1.Event_Reason_Id = t.Reason_Level1
 	    Left Join Event_Reasons r2 on r2.Event_Reason_Id = t.Reason_Level2
 	    Left Join Event_Reasons r3 on r3.Event_Reason_Id = t.Reason_Level3
 	    Left Join Event_Reasons r4 on r4.Event_Reason_Id = t.Reason_Level4
 	    where t.PU_Id = @PUId and t.Start_Time < @StartTime
       Order by t.Start_Time Desc
  End
Else IF @Event_Type = 3
  Begin
 	 Insert into #T(TimeColumns) Values ('TimeStamp')
 	 Select * From #T
 	 Truncate Table #T
 	 If @Count = 0
 	   Begin
 	  	 Set Rowcount 500
 	   Select [Key] = WED_Id,Coalesce(e.Event_Num,'<Time>'),w.TimeStamp,w.Amount
 	  	  From Waste_event_Details w
 	  	   Left Join Events e on e.event_Id = w.Event_Id
 	  	   where w.PU_Id = @PUId and w.TimeStamp Between @StartTime and @EndTime
 	  	   Order by w.TimeStamp Desc
 	   End
 	 Else
 	   Select [Key] = WED_Id,Coalesce(e.Event_Num,'<Time>'),w.TimeStamp,w.Amount
 	    From Waste_event_Details w
 	    Left Join Events e on e.event_Id = w.Event_Id
 	    where w.PU_Id = @PUId and w.TimeStamp < @StartTime
       Order by w.TimeStamp Desc
  End
Else IF @Event_Type = 4
  Begin
 	 Insert into #T(TimeColumns) Values ('Start Time')
 	 Insert into #T(TimeColumns) Values ('End Time')
 	 Select * From #T
 	 Truncate Table #T
 	 If @Count = 0
 	   Begin
 	  	 Set Rowcount 500
 	  	 Select [Key] = Start_Id,[Start Time] = ps.Start_Time,[End Time] = ps.End_Time,[Product] = p.Prod_Code
   	  	 From Production_Starts ps
 	  	 Join Products p on p.Prod_Id = ps.Prod_Id
 	  	 where ps.PU_Id = @PUId and ps.Start_Time Between @StartTime and @EndTime
 	  	 Order by ps.Start_Time Desc
 	   End
 	 Else
 	   Select [Key] = Start_Id,ps.Start_Time,ps.End_Time,p.Prod_Code
 	    From Production_Starts ps
 	    Join Products p on p.Prod_Id = ps.Prod_Id
 	    where ps.PU_Id = @PUId and ps.Start_Time < @StartTime
       Order by ps.Start_Time Desc
  End
Else IF @Event_Type = 14
  Begin
 	 Insert into #T(TimeColumns) Values ('Start Time')
 	 Insert into #T(TimeColumns) Values ('End Time')
 	 Select * From #T
 	 Truncate Table #T
 	 If @Count = 0
 	   Begin
 	  	 Set Rowcount 500
 	  	 Select  [Key] = UDE_Id,[Start Time] = u.Start_Time,[End Time] = u.End_Time,[Description] = UDE_Desc
 	  	 From User_Defined_Events u
 	  	 Join event_configuration e On e.Event_Subtype_Id = u.Event_Subtype_Id and e.ec_Id = @EC_Id
 	  	 where u.PU_Id = @PUId and u.Start_Time Between @StartTime and @EndTime
 	  	 Order by u.Start_Time Desc
 	   End
 	 Else
 	   Select  [Key] = UDE_Id,[Start Time] = u.Start_Time,[End Time] = u.End_Time,[Description] = UDE_Desc
 	    From User_Defined_Events u
 	  	  Join event_configuration e On e.Event_Subtype_Id = u.Event_Subtype_Id and e.ec_Id = @EC_Id
 	    where u.PU_Id = @PUId and u.Start_Time < @StartTime
       Order by u.Start_Time Desc
  End
Drop Table #T
Set Rowcount  0
