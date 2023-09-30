CREATE PROCEDURE dbo.spGE_GetProductionPlanDetail
 	 @Id int,
 	 @IsCurrent Bit
 AS
 Declare @PPID  	  	  	 Int,
 	  	 @PPSetupId 	  	 Int,
 	  	 @StartTime  	  	 DateTime,
 	  	 @PPStart 	  	 DateTime, 
 	  	 @CountDetail    	 Real,
 	  	 @ParentRollSize 	 Real,
 	  	 @PUID 	  	  	 Int,
 	  	 @SizeError 	  	 Int,
 	  	 @Now 	  	  	 DateTime
SELECT @Now = dbo.fnServer_CmnGetDate(GetUTCDate())
If @IsCurrent = 1
  Begin
    Select @PPID = PP_Id,@StartTime = Start_Time
     From Production_Plan_Starts
 	 Where Start_Time < @Now and End_Time is Null  
                    and PU_Id = @Id
   Select @PPSetupId = PP_Setup_Id
    From Production_Setup
    Where PP_Id = @PPID and pp_status_id = 3 --Active
  Select @CountDetail = sum(convert(real,coalesce(Target_Dimension_Z,0))) 
    From Production_Setup_Detail
    Where PP_Setup_Id = @PPSetupId
  If @CountDetail = 0 Select @CountDetail = 1
  Select SizeError =0,EventId = PP_Setup_Detail_Id * -1, PercentofTrim = 0,
 	 PercentofTotal = convert(real,coalesce(Target_Dimension_Z,0))/@CountDetail,Status = Element_Status,
 	 Process_Order = Target_Dimension_z,TimeStamp = @StartTime,PU_Id = @PUID,Event_Num = 'None', DimA = coalesce(Target_Dimension_A,0),
 	 DimX = coalesce(Target_Dimension_X,0),DimY = coalesce(Target_Dimension_Y,0),DimZ = coalesce(Target_Dimension_Z,0),Customer_Order = Target_Dimension_z,Comment_Id = 0,Applied_Product = 0
    From Production_Setup_Detail
    Where PP_Setup_Id = @PPSetupId
    Order by Element_Number
  End
Else
 Begin
-- select * from Production_Setup_Detail
-- Need to change Have to have parent in event_details
-- status not currently updated in event_Details
  Select @PUID = PU_ID  From Events where Event_Id = @Id
  Select @ParentRollSize =  convert(real,coalesce(Final_Dimension_Z,30))
 	 From event_Details Where Event_Id = @Id
  Select @CountDetail = sum(convert(real,coalesce(ed.Final_Dimension_Z,0)))
 	 From Event_Components ec
 	 Left Join Event_Details ed On ec.Event_Id = ed.event_Id  
 	   Where Source_Event_Id = @Id
  If @CountDetail = 0 Select @CountDetail = 1
  select @SizeError = 0
  if (@ParentRollSize is null) or (@ParentRollSize < @CountDetail)
    Begin
      Select @ParentRollSize = @CountDetail
      Select @SizeError = 1
    End
  Select TrimWidth = convert(int,(@ParentRollSize - @CountDetail) / 2) ,SizeError = @SizeError,EventId = ec.Event_Id, PercentofTrim = (@ParentRollSize - @CountDetail)/@ParentRollSize,
                   PercentofTotal = convert(real,coalesce(ed.Final_Dimension_Z,0))/@ParentRollSize,
 	  	    [Event_Num] = e.Event_Num,[Process_Order] = Coalesce(p.Process_Order,p2.Process_Order,'N/A'),Status = e.Event_Status,E.TimeStamp,e.PU_Id,
 	  	    DimA = coalesce(ed.final_dimension_A,0),DimX = coalesce(ed.final_dimension_X,0),DimY = coalesce(ed.final_dimension_Y,0),DimZ = coalesce(ed.final_dimension_z,0),
 	  	  	 [Customer_Order] =  Coalesce(co.Customer_Order_Number,'N/A'),Comment_Id = coalesce(e.Comment_Id,0),Applied_Product = Coalesce(e.Applied_Product,0)
    from Event_Components ec
    Left Join Event_Details ed On ed.Event_Id = ec.Event_Id
    Left Join Production_Plan p on p.pp_Id = ed.pp_Id
    Left Join Events e on e.event_Id = ed.Event_Id
 	  Left Join  	  Production_Plan_starts pps on pps.Start_Time <= e.timestamp and  (pps.End_time > e.timestamp or  pps.End_time is null)  and pps.pu_id = e.PU_Id
    Left Join Production_Plan p2 on p2.pp_Id = pps.pp_Id
    Left Join Customer_Order_Line_Items col On ed.Order_Line_Id = col.Order_Line_Id
    Left Join Customer_Orders co on col.Order_Id = co.Order_Id
    Where ec.Source_Event_Id = @Id
End
