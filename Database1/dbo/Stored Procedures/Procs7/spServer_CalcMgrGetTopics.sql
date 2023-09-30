CREATE PROCEDURE dbo.spServer_CalcMgrGetTopics
 AS
Declare
  @ProdDayMinutes int ,
  @ShiftInterval int ,
  @ShiftOffset int 
Execute spServer_CmnGetLocalInfo @ProdDayMinutes output, @ShiftInterval output, @ShiftOffset output
select 	 Topic_Id, 
 	  	 Topic_Desc, 
 	  	 calculation_id, 
 	  	 Sampling_Interval, 
 	  	 Sampling_Offset, 
 	  	 Sampling_Window,
 	  	 ProdDayMinutes = @ProdDayMinutes,
 	  	 ShiftInterval = @ShiftInterval,
 	  	 ShiftOffset = @ShiftOffset,
 	  	 ''
from Topics where Event_type = 0
