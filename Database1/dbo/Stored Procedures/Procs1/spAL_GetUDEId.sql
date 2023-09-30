Create Procedure dbo.spAL_GetUDEId
  @Sheet_Desc nvarchar(50),
  @Result_On datetime
 AS
  Declare @PU_Id int
  Declare @EventSubtype Int
  Select @PU_Id = Master_Unit,@EventSubtype = Event_Subtype_Id  From Sheets Where Sheet_Desc = @Sheet_Desc
  Select UDE_Id from User_Defined_Events where
    PU_Id = @PU_Id and  End_Time = @Result_On and Event_Subtype_Id = @EventSubtype
