CREATE FUNCTION dbo.fnServer_CmnGetSegRespUnit(
@SegRespId uniqueidentifier
) 
     RETURNS int
AS 
begin
IF @SegRespId IS Null
      RETURN Null
declare @PUId int
set @PUId = NULL
select @PUId = a.PU_Id
  from SegmentResponse r
  join PAEquipment_Aspect_SOAEquipment a on a.Origin1EquipmentId = r.EquipmentId
  where r.SegmentResponseId = @SegRespId
    and r.EquipmentId is not null
return @PUId
end
