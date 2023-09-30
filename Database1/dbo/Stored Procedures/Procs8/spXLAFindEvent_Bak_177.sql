Create Procedure dbo.[spXLAFindEvent_Bak_177]
  @PU_Id int,
  @Result_On datetime  
, @InTimeZone 	 varchar(200) = null
AS
SELECT @Result_On = dbo.fnServer_CmnConvertToDBTime(@Result_On,@InTimeZone)
  SELECT e.Event_Num, ps.ProdStatus_Desc 
        FROM Events e WITH (index(Event_By_PU_And_TimeStamp))
        LEFT OUTER JOIN Production_Status ps on e.event_status = ps.prodstatus_id
        WHERE (e.PU_Id = @PU_Id) AND (e.TimeStamp = @Result_On)
