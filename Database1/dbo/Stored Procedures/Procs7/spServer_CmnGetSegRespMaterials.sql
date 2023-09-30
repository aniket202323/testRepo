CREATE PROCEDURE dbo.spServer_CmnGetSegRespMaterials 
@SegRespId uniqueidentifier
AS
Declare @ProcSegId uniqueidentifier
Declare 	 @WorkResponseId uniqueidentifier
 	 
Select @ProcSegId = NULL
Select @WorkResponseId = NULL
Select @ProcSegId = ProcSegId, @WorkResponseId = WorkResponseId 
 	 From SegmentResponse 
 	 Where (SegmentResponseId = @SegRespId)
If ((@ProcSegId Is NULL) Or (@WorkResponseId Is NULL))
 	 Return NULL
 	 
select md.MaterialDefinitionId
from WorkRequest wr join SegReq sr on wr.WorkRequestId = sr.WorkRequestId  
join MaterialSpec_SegReq mssr on mssr.SegReqId = sr.SegReqId
join SpecMaterial_MaterialSpec_SegReq smssq on smssq.MaterialSpec_SegReqId = mssr.MaterialSpec_SegReqId 
join MaterialDefinition md on md.MaterialDefinitionId = smssq.MaterialDefinitionId 
join ProcSeg psg on psg.ProcSegId = sr.ProcSegId 
join WorkResponse wrsp on wrsp.WorkRequestId = wr.WorkRequestId
where (r_use='Produced') And
 	  	  	 (wrsp.WorkResponseId = @WorkResponseId) And
 	  	  	 (psg.ProcSegId = @ProcSegId)
