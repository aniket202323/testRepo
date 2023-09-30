Create Procedure dbo.spGBAEventData
  @Var_Id int,
  @PU_Id int,
  @Event_ID nvarchar(20)   AS
  DECLARE @MasterUnit int
  SELECT @MasterUnit = Master_Unit
        FROM Prod_Units 
        WHERE PU_Id = @PU_Id
  IF @MasterUnit Is NULL 
    BEGIN      
      SELECT @MasterUnit = @PU_Id
    END  
  SELECT T.Result_On, T.Entry_On, T.Result, T.canceled, T.Comment_Id, PS.prod_id
        FROM Events Ev WITH (index(Event_By_PU_And_Event_Number))
             left outer join Tests T on (T.result_on = Ev.timestamp) and (T.var_id = @Var_Id),  
             Production_Starts PS WITH (index(Production_Starts_By_PU_Start))
        WHERE (Ev.PU_Id = @MasterUnit) AND 
              (Ev.Event_Num = @Event_ID) AND
              (PS.PU_Id = @MasterUnit) AND
              (PS.Start_Time <= Ev.TimeStamp) AND
              ((PS.End_Time >= Ev.TimeStamp) OR (PS.End_Time Is NULL))
