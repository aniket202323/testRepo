Create Procedure dbo.spXLAFindEvent
  @PU_Id int,
  @Result_On datetime  
, @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Result_On =  @Result_On  at time zone @InTimeZone at time zone @DBTz
  SELECT e.Event_Num, ps.ProdStatus_Desc 
        FROM Events e WITH (index(Event_By_PU_And_TimeStamp))
        LEFT OUTER JOIN Production_Status ps on e.event_status = ps.prodstatus_id
        WHERE (e.PU_Id = @PU_Id) AND (e.TimeStamp = @Result_On)
