Create Procedure dbo.spGBAFindEvent
  @PU_Id int,
  @Result_On datetime   AS
  SELECT e.Event_Num, ps.ProdStatus_Desc 
        FROM Events e WITH (index(Event_By_PU_And_TimeStamp))
        LEFT OUTER JOIN Production_Status ps on e.event_status = ps.prodstatus_id
        WHERE (e.PU_Id = @PU_Id) AND (e.TimeStamp = @Result_On)
