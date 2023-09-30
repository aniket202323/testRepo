Create Procedure dbo.spAL_UDEColumnResults
  @Sheet_Desc nvarchar(50),
  @Result_On datetime
 AS
  Declare @PU_Id int,
 	   @EventSubtypeId Int
  Select @PU_Id = Master_Unit, @EventSubtypeId = Event_Subtype_Id From Sheets Where Sheet_Desc = @Sheet_Desc
  Select UDE_Id, 
 	   UDE_Desc = substring(UDE_Desc,1,50),
 	   Event_Status = coalesce(Event_Status,0),
 	   Conformance = coalesce(Conformance,0),
 	   Testing_Prct_Complete = coalesce(Testing_Prct_Complete,0),
 	   Acknowledged =  coalesce(Ack,0),
 	   TestingStatus  = coalesce(testing_status,1)
    From User_defined_Events 
      Where PU_Id = @PU_Id and End_Time = @Result_On and Event_Subtype_Id = @EventSubtypeId
