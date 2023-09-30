Create Procedure dbo.spEX_WasteByEvent
@Event_Id int
AS
select E.Event_Id, E.Event_Num, E.Timestamp as ETimestamp, E.Event_Status,  
       D.WED_Id, D.Timestamp as DTimeStamp, D.Source_PU_Id, 
       D.WET_Id, D.WEMT_Id, D.Reason_Level1, D.Reason_Level2, 
       D.Reason_Level3, D.Reason_Level4, D.Amount, Prod_Id = NUll, Prod_Code = NULL,
       D.Action_Comment_Id, D.Cause_Comment_Id, D.Research_Comment_Id, EC.ESignature_Level
from waste_event_details d
Join Events E On E.Event_Id = @Event_Id and E.Event_Id = D.Event_Id
Join Event_Configuration EC on EC.EC_Id = d.EC_Id
Where D.Event_Id = @Event_Id
ORDER BY dTimestamp asc
RETURN(100)
