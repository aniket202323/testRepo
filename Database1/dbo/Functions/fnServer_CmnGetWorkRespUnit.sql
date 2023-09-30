CREATE FUNCTION dbo.fnServer_CmnGetWorkRespUnit(
@WorkRespId uniqueidentifier
) 
     RETURNS int
AS 
begin
IF @WorkRespId IS Null
      RETURN Null
declare @PUId int
set @PUId = NULL
select @PUId = a.PU_Id
  from WorkResponse r
  join PAEquipment_Aspect_SOAEquipment a on a.Origin1EquipmentId = r.EquipmentId
  where r.WorkResponseId = @WorkRespId
    and r.EquipmentId is not null
return @PUId
end
