Create Procedure dbo.spGE_GetLoadedInventory
 	 @Event_Id 	 Int,
        @SheetId  Int = Null
 AS
  DECLARE @PU_Id 	 Int,
 	 @MasterPU_Id 	 Int,
 	 @TimeStamp 	 Datetime,
 	 @LAC 	  	 Int,
 	 @MAC 	  	 Int,
 	 @HAC 	  	 Int,
 	 @EndTs 	 DateTime,
 	 @StartTs 	 DateTime,
 	 @PrevEventId 	 Int,
        @DisplayAlarms  	 Int
  If @SheetId is Not Null
    Begin
      Select @DisplayAlarms = convert(int,value)
 	 From Sheet_Display_Options s
 	 Join Display_Options d on s.Display_Option_Id = d.Display_Option_Id and d.Display_Option_Desc = 'DisplayTreeViewAlarms'
 	 Where Sheet_Id = @SheetId
    End
  Select @DisplayAlarms = isnull(@DisplayAlarms,1)
  Select @PU_Id = Pu_ID,@EndTs = Timestamp  from Events Where Event_Id = @Event_Id
  Select  @StartTs = Max(Timestamp)  from Events Where Timestamp < @EndTs and  @PU_Id = Pu_ID
  Select @StartTs = coalesce(@StartTs,@EndTs)
  Select @PrevEventId = Event_Id from Events Where Timestamp = @StartTs and  @PU_Id = Pu_ID
If @DisplayAlarms = 1
  Begin
    Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
  End
Else
  Select @LAC= 0, @MAC = 0, @HAC = 0
--  Execute spCmn_AlarmCounts @LAC Output,@MAC Output,@HAC Output,@StartTs,@EndTs,@PU_Id
  SELECT @MasterPU_Id  = coalesce((select master_unit from prod_units where pu_id = @PU_Id),@PU_Id)
  --
  SELECT  DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
        Event_num,e.Event_Status ,[Prod_Code] = Coalesce(p1.prod_code,pp.prod_code),LAC =@LAC,HAC = @HAC,MAC = @MAC,[Process_Order] = Coalesce(p.Process_Order,p2.Process_Order,'N/A'),e.timestamp, e.PU_Id,
 	 [Customer_Order] =  Coalesce(co.Customer_Order_Number,'N/A'),Prev_Event_Id = @PrevEventId,Prev_TimeStamp = @StartTs,e.Comment_Id,Applied_Product = coalesce(e.Applied_Product,0),
 	 [Order] = Coalesce(co.Customer_Order_Number,'N/A'),PU_Desc
    FROM Events e
 	 Join Prod_Units pu on pu.PU_Id = e.PU_Id
    Left Join Event_Details ed on ed.event_Id = e.event_Id
    Join Production_Starts s on (s.Start_Time <= e.timestamp and  (s.End_time > e.Timestamp or  s.End_time is null))  and s.pu_id = @MasterPU_Id
    Join  Products pp on pp.prod_id = s.prod_id
    left Join  Products p1 on p1.prod_id = e.Applied_Product
    Left Join Production_Plan p on p.pp_Id = ed.pp_Id
 	  Left Join  	  Production_Plan_starts pps on pps.Start_Time <= e.timestamp and  (pps.End_time > e.timestamp or  pps.End_time is null)  and pps.pu_id = @PU_Id
    Left Join Production_Plan p2 on p2.pp_Id = pps.pp_Id
    Left Join Customer_Order_Line_Items col on col.Order_Line_Id = ed.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    where e.Event_Id =  @Event_Id
  If @DisplayAlarms = 1
    Begin
  Select AP_id = Coalesce(Case When r.AP_Id is not Null Then r.AP_Id Else vrd.AP_Id End, atp.AP_Id), v.Var_Id,a.Alarm_Id,a.Start_Time,a.End_Time
      from Alarms a
     Join Alarm_Template_Var_Data atd  on atd.ATD_Id = a.ATD_Id
     Join Variables v on v.Var_Id = atd.Var_Id
     Join Alarm_Templates atp On atp.AT_Id =  atd.AT_Id
     Left outer Join Alarm_Template_SPC_Rule_Data r on r.AT_Id = atd.AT_Id and r.ATSRD_Id = a.ATSRD_Id
     Left outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.AT_Id = atd.AT_Id and vrd.ATVRD_Id = a.ATVRD_Id
      Where (Start_Time <=  @EndTs) and (End_Time >  @StartTs or End_Time Is Null)
       And v.PU_Id = @PU_Id
    End
  Else
    Begin
       Declare @nullTable table (AP_id int, Var_Id int, Alarm_Id int, Start_Time datetime, End_Time datetime) 
       select * from @nullTable 
    End
