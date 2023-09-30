Create Procedure [dbo].[spRS_ListDisplays]
@IsEventBased int = 0
AS
/*--***************************
-- For Testing
--***************************
Select @IsEventBased = 0
--***************************/
Select distinct DisplayId = s.Sheet_Id, DisplayDescription = s.Sheet_Desc
  From Sheet_Variables sv 
  Join sheets s on s.sheet_id = sv.sheet_id and ((s.event_type = @IsEventBased) or (s.event_type Is Null) or (s.event_type > 0 and  @IsEventBased > 0)) 
  order by DisplayDescription
