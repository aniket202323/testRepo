Create Procedure dbo.[spWDGetWasteDetailsTest_Bak_177]
@pPU_Id int,
@pStartTime datetime,
@pEndTime datetime
AS
DECLARE @ESignature Int
DECLARE @AllEvents Table(Event_Id Int,Event_Num nVarChar(25),[TimeStamp] DateTime,Event_Status Int,Applied_Product Int)
DECLARE @WasteRecords Table(
 	  	  	  	  	  	  	 Event_Id 	  	  	 Int,
 	  	  	  	  	  	  	 Event_Num 	  	  	 nVarChar(25),
 	  	  	  	  	  	  	 ETimestamp 	  	  	 DateTime,
  	    	    	    	    	    	    	  Event_Status  	    	  Int,
 	  	  	  	  	  	  	 WED_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 DTimeStamp 	  	  	 DateTime,
 	  	  	  	  	  	  	 Source_PU_Id 	  	 Int,
 	  	  	  	  	  	  	 WET_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 WEMT_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 WEFault_Id 	  	  	 Int,
 	  	  	  	  	  	  	 Reason_Level1 	  	 Int,
 	  	  	  	  	  	  	 Reason_Level2 	  	 Int,
 	  	  	  	  	  	  	 Reason_Level3 	  	 Int,
 	  	  	  	  	  	  	 Reason_Level4 	  	 Int,
 	  	  	  	  	  	  	 Action_Level1 	  	  Int,
 	  	  	  	  	  	  	 Action_Level2 	  	 Int,
 	  	  	  	  	  	  	 Action_Level3 	  	 Int,
 	  	  	  	  	  	  	 Action_Level4 	  	 Int,
 	  	  	  	  	  	  	 Amount 	  	  	  	 Float,
 	  	  	  	  	  	  	 Prod_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 Action_Comment_Id 	 Int,
 	  	  	  	  	  	  	 Cause_Comment_Id 	 Int,
 	  	  	  	  	  	  	 Research_Comment_Id 	 Int,
 	  	  	  	  	  	  	 EC_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 timeorder 	  	  	 DateTime
)
Insert Into @AllEvents(Event_Id, Event_Num, Timestamp, Event_Status, Applied_Product)
select Event_Id, Event_Num, Timestamp, Event_Status, Applied_Product
  from events 
  where pu_id = @pPu_Id and
        timestamp >= @pstarttime and
        timestamp <= @pendtime and
        event_status > 2
/* Event Based */
INSERT INTO @WasteRecords(Event_Id,
 	  	  	  	  	  	  	 Event_Num,
 	  	  	  	  	  	  	 ETimestamp,
 	  	  	  	  	  	  	 Event_Status,
 	  	  	  	  	  	  	 WED_Id,
 	  	  	  	  	  	  	 DTimeStamp,
 	  	  	  	  	  	  	 Source_PU_Id,
 	  	  	  	  	  	  	 WET_Id,
 	  	  	  	  	  	  	 WEMT_Id,
 	  	  	  	  	  	  	 WEFault_Id,
 	  	  	  	  	  	  	 Reason_Level1,
 	  	  	  	  	  	  	 Reason_Level2,
 	  	  	  	  	  	  	 Reason_Level3,
 	  	  	  	  	  	  	 Reason_Level4,
 	  	  	  	  	  	  	 Action_Level1,
 	  	  	  	  	  	  	 Action_Level2,
 	  	  	  	  	  	  	 Action_Level3,
 	  	  	  	  	  	  	 Action_Level4,
 	  	  	  	  	  	  	 Amount,
 	  	  	  	  	  	  	 Prod_Id,
 	  	  	  	  	  	  	 Action_Comment_Id,
 	  	  	  	  	  	  	 Cause_Comment_Id,
 	  	  	  	  	  	  	 Research_Comment_Id,
 	  	  	  	  	  	  	 EC_Id,
 	  	  	  	  	  	  	 timeorder)
select E.Event_Id, E.Event_Num, E.Timestamp , E.Event_Status,  
       D.WED_Id, D.Timestamp, D.Source_PU_Id, 
       D.WET_Id, D.WEMT_Id, WEFault_Id, 
       D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, 
       D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, 
       D.Amount, e.Applied_Product,
       D.Action_Comment_Id, D.Cause_Comment_Id, D.Research_Comment_Id, D.EC_Id, Coalesce(D.Timestamp, E.Timestamp)
from waste_event_details d WITH(INDEX(WEvent_Details_IDX_EventId))
right join @AllEvents e on e.event_id = d.event_id
/* Time Based */ 
INSERT INTO @WasteRecords(Event_Id,
 	  	  	  	  	  	  	 Event_Num,
 	  	  	  	  	  	  	 ETimestamp,
 	  	  	  	  	  	  	 Event_Status,
 	  	  	  	  	  	  	 WED_Id,
 	  	  	  	  	  	  	 DTimeStamp,
 	  	  	  	  	  	  	 Source_PU_Id,
 	  	  	  	  	  	  	 WET_Id,
 	  	  	  	  	  	  	 WEMT_Id,
 	  	  	  	  	  	  	 WEFault_Id,
 	  	  	  	  	  	  	 Reason_Level1,
 	  	  	  	  	  	  	 Reason_Level2,
 	  	  	  	  	  	  	 Reason_Level3,
 	  	  	  	  	  	  	 Reason_Level4,
 	  	  	  	  	  	  	 Action_Level1,
 	  	  	  	  	  	  	 Action_Level2,
 	  	  	  	  	  	  	 Action_Level3,
 	  	  	  	  	  	  	 Action_Level4,
 	  	  	  	  	  	  	 Amount,
 	  	  	  	  	  	  	 Action_Comment_Id,
 	  	  	  	  	  	  	 Cause_Comment_Id,
 	  	  	  	  	  	  	 Research_Comment_Id,
 	  	  	  	  	  	  	 EC_Id,
 	  	  	  	  	  	  	 timeorder)
 select null, null, null,null,  
       D.WED_Id, D.Timestamp, D.Source_PU_Id, 
       D.WET_Id, D.WEMT_Id, WEFault_Id, 
       D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, 
       D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, 
       D.Amount, D.Action_Comment_Id, D.Cause_Comment_Id, D.Research_Comment_Id, D.EC_Id,D.Timestamp
from waste_event_details d WITH(INDEX(WEvent_Details_IDX_PUIdTime))
  where d.pu_id = @pPu_Id and 
        d.event_id is null and
        d.timestamp >= @pstarttime and
        d.timestamp <= @pendtime
UPDATE @WasteRecords  Set Prod_Id  = p.Prod_Id
 	 FROM @WasteRecords a 
 	 join production_starts p 
    on (p.pu_id = @pPu_Id) and (timeorder >= p.start_time) and   ((timeorder < p.end_time) or (p.end_time is null))   
 	 WHERE a.Prod_Id is null
SELECT @ESignature = Max(Coalesce(ec.ESignature_Level,0))
FROM Event_Configuration ec 
WHERE ec.PU_Id = @pPU_Id and ec.et_id = 3
SELECT DISTINCT d.*, p.prod_code, ESignature_Level = @ESignature
from  @WasteRecords d
join products p on p.prod_id = d.prod_id
order by timeorder asc 
RETURN(100)
