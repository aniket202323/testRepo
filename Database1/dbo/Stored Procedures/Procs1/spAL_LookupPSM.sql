Create Procedure dbo.spAL_LookupPSM
  @UnitId int,
  @StartTime datetime AS
  Select a.start_id, a.pu_id, a.start_time, a.end_time, a.prod_id, b.prod_code, b.prod_desc, b.comment_id,  b.external_link, Event_Esignature_Level = Coalesce(b.Event_Esignature_Level, 0), Product_Change_Esignature_Level = Coalesce(b.Product_Change_Esignature_Level, 0)
    from production_starts a
    join products b on b.prod_id = a.prod_id
    where (a.pu_id = @UnitID)  
      and (a.start_time <= @StartTime)
      and ((a.end_time > @StartTime) OR (a.end_time IS NULL))
