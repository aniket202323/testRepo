CREATE PROCEDURE dbo.spServer_CmnGetWorkRespMaterials 
@WorkRespId uniqueidentifier
AS
 	 
select md.MaterialDefinitionId
from WorkResponse r
join WorkRequest wr on wr.WorkRequestId = r.WorkRequestId  
join SegReq sr on wr.WorkRequestId = sr.WorkRequestId  
left join MaterialSpec_SegReq mssr on mssr.SegReqId = sr.SegReqId
join SpecMaterial_MaterialSpec_SegReq smssq on smssq.MaterialSpec_SegReqId = mssr.MaterialSpec_SegReqId 
join MaterialDefinition md on md.MaterialDefinitionId = smssq.MaterialDefinitionId 
where (mssr.r_use='Produced') And
 	   (r.WorkResponseId = @WorkRespId) And
 	   (sr.IsMaster = 1)
