Create Procedure dbo.spGE_GetSiblingEvent
 	 @PU_Id 	  	 Int,
 	 @Event_Id 	 Int,
 	 @Transaction 	 tinyint,
 	 @EventNum 	 nvarchar(25)
 AS
DECLARE @TimeStamp 	 Datetime,
 	 @LAC 	  	 Int,
 	 @MAC 	  	 Int,
 	 @HAC 	  	 Int,
 	 @EndTs 	  	 DateTime,
 	 @StartTs 	 DateTime,
 	 @Now 	  	 DateTime,
 	 @NextId 	  	 Int,
 	 @PrevId 	  	 Int,
 	 @PrevId1 	 Int,
 	 @LAC1 	  	 Int,
 	 @MAC1 	  	 Int,
 	 @HAC1 	  	 Int
Select @Now = DateAdd(Day,100,GetUtcDate())
Select @TimeStamp = Timestamp From events Where Event_Id = @Event_Id
Select @NextId = Null
Select @PrevId = Null
If @Transaction = 1
 Begin
  Select @EndTs = @TimeStamp
  Select @StartTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @TimeStamp)
  Select @NextId = @Event_Id
  Select @Event_Id = Event_Id From events Where Pu_ID = @PU_Id and Timestamp = @StartTs
  Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
  Select @EndTs = @StartTs
  Select @StartTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Select @PrevId1 = Event_Id From events Where Pu_ID = @PU_Id and Timestamp = @StartTs
  Select @PrevId = Event_Id From Events where pu_Id = @PU_Id and Timestamp < @StartTs  and Timestamp > '1/1/1970'
  Execute spCmn_AlarmCounts @LAC1 Output,@MAC1 Output,@HAC1 Output,@StartTs,@EndTs,@PU_Id
 End
Else If @Transaction = 2
 Begin
  Select @StartTs = @TimeStamp
  Select @EndTs = Min(Timestamp)  from Events Where   Pu_ID = @PU_Id   and (Timestamp > @TimeStamp  and Timestamp < @Now)
  Select @PrevId1 = Event_Id From events Where Pu_ID = @PU_Id and Timestamp = @EndTs
  Select @NextId = Event_Id From Events where pu_Id = @PU_Id and Timestamp > @EndTs  and Timestamp < @Now
  Execute spCmn_AlarmCounts @LAC1 Output,@MAC1 Output,@HAC1 Output,@StartTs,@EndTs,@PU_Id
  Select @EndTs = @StartTs
  Select @PrevId = Event_Id From Events where pu_Id = @PU_Id and Timestamp < @StartTs  and Timestamp > '1/1/1970'
  Select @StartTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
 End
Else If @Transaction = 3
 Begin
  Select @EndTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @Now)
  Select @StartTs = Max(TimeStamp) from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Select @PrevId1 = Event_Id From events Where Pu_ID = @PU_Id and Timestamp = @EndTs
  Select @Event_Id = Event_Id From Events where Pu_Id = @PU_Id and Timestamp  = @StartTs
  Execute spCmn_AlarmCounts @LAC1 Output,@MAC1 Output,@HAC1 Output,@StartTs,@EndTs,@PU_Id
  Select @NextId = Null
  Select @EndTs = @StartTs
  Select @PrevId = Event_Id From Events where pu_Id = @PU_Id and Timestamp < @StartTs  and Timestamp > '1/1/1970'
  Select @StartTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
 End
Else If  @Transaction = 4  
 Begin
  Select @Event_Id = Null
  Select @Event_Id = Event_Id,@EndTs = Timestamp
     From events WITH (index(Event_By_PU_And_Event_Number))
     Where Pu_ID = @PU_Id and Event_Num  = Ltrim(rtrim(@EventNum))
  If @Event_Id is null
   Begin
     Select [Event Not Found] = 1
     Return(1)
   End
  Select @StartTs = Max(TimeStamp) from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Select @NextId = Event_Id From Events where pu_Id = @PU_Id and Timestamp  > @EndTs  and Timestamp < @Now
  Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
  Select @EndTs = @StartTs
  Select @StartTs = Max(Timestamp)  from Events Where  @PU_Id = Pu_ID and(Timestamp > '1/1/1970' and  Timestamp < @EndTs)
  Select @PrevId1 = Event_Id From events Where Pu_ID = @PU_Id and Timestamp = @EndTs
  Select @PrevId = Event_Id From Events where pu_Id = @PU_Id and Timestamp  = @StartTs
  Execute spCmn_AlarmCounts @LAC1 Output,@MAC1 Output,@HAC1 Output,@StartTs,@EndTs,@PU_Id
 End
  SELECT   DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
 	   e.Event_Id,e.Event_num,e.Event_Status ,prod_code,LAC =@LAC1,HAC = @HAC1,MAC = @MAC1,[Process_Order] = Coalesce(p.Process_Order,p2.Process_Order,'N/A'),e.timestamp,NextId = @NextId,PrevId = @PrevId,
 	   [Customer_Order] =  Coalesce(co.Customer_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0)
    FROM Events e
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Left Join Production_Plan p on p.pp_Id = ed.pp_Id
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = @PU_Id
 	  Left Join  	  Production_Plan_starts pps on pps.Start_Time <= e.timestamp and  (pps.End_time > e.timestamp or  pps.End_time is null)  and pps.pu_id = @PU_Id
    Left Join Production_Plan p2 on p2.pp_Id = pps.pp_Id
    Join  Products pp on pp.prod_id = coalesce(e.Applied_Product,s.prod_id)
    where e.Event_Id =  @PrevId1
  SELECT   DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
 	   e.Event_Id,e.Event_num,e.Event_Status ,prod_code,LAC =@LAC,HAC = @HAC,MAC = @MAC,[Process_Order] = Coalesce(p.Process_Order,p2.Process_Order,'N/A'),e.timestamp,NextId = @NextId,PrevId = @PrevId,
 	   [Customer_Order] =  Coalesce(co.Customer_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0)
    FROM Events e
    Left Join Event_Details ed On ed.Event_Id = e.Event_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Left Join Production_Plan p on p.pp_Id = ed.pp_Id
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = @PU_Id
  	  Left Join  	  Production_Plan_starts pps on pps.Start_Time <= e.timestamp and  (pps.End_time > e.timestamp or  pps.End_time is null)  and pps.pu_id = @PU_Id
    Left Join Production_Plan p2 on p2.pp_Id = pps.pp_Id
   Join  Products pp on pp.prod_id = coalesce(e.Applied_Product,s.prod_id)
    where e.Event_Id =  @Event_Id
Return (0)
