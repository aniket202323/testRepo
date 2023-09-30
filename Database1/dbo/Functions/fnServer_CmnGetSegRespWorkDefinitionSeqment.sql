CREATE FUNCTION dbo.fnServer_CmnGetSegRespWorkDefinitionSeqment(
@SegRespId uniqueidentifier
) 
 	 RETURNS uniqueidentifier
AS 
begin
IF @SegRespId IS Null
      RETURN Null
Declare @WDSId uniqueidentifier
Declare @ProcSegId uniqueidentifier
Declare 	 @WorkResponseId uniqueidentifier
 	 
Select @WDSId = NULL
Select @ProcSegId = NULL
Select @WorkResponseId = NULL
Select @ProcSegId = ProcSegId, @WorkResponseId = WorkResponseId 
 	 From SegmentResponse 
 	 Where (SegmentResponseId = @SegRespId)
If ((@ProcSegId Is NULL) Or (@WorkResponseId Is NULL))
 	 Return NULL
Select @WDSId = pds.ProdSegId
  from SegmentResponse segr
  join ProcSeg psg on psg.ProcSegId = segr.ProcSegId 
  join ProductToProcess p2p on p2p.ProcSegId = segr.ProcSegId
  join WorkResponse wrsp on wrsp.WorkResponseId = segr.WorkResponseId
  join WorkRequest wr on wr.WorkRequestId = wrsp.WorkRequestId
  join WorkDefinition wd on wd.WorkDefinitionId = wr.WorkDefinitionId
  join SegmentSpecification ss on ss.WorkDefinitionId = wd.WorkDefinitionId
  join ProdSeg pds on pds.ProdSegId = p2p.ProdSegId and pds.ProdSegId = ss.ProdSegId 
where (SegmentResponseId = @SegRespId)
return @WDSId
 	 
end
