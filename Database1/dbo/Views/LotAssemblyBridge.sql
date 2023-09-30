CREATE VIEW dbo.LotAssemblyBridge AS 
WITH LotAssemblies (AncestorLotId, ParentLotId, DescendantLotId, Depth, AncestorHash)
AS
(
	-- Select every material lot to start with.
	SELECT
		ml.MaterialLotId AS AncestorLotId,
		ml.MaterialLotId AS ParentLotId, 
		ml.MaterialLotId AS DescendantLotId,
		0 AS Depth,
		CAST('00000000-0000-0000-0000-000000000000' AS UNIQUEIDENTIFIER) AS AncestorHash
	FROM dbo.MaterialLot AS ml	
	UNION ALL
	-- For each material lot, select all of the children material lots as defined by MaterialLotAssembly	
	SELECT
		la.AncestorLotId,
		mla.ParentMaterialLotId AS ParentLotId, 
		mla.ChildMaterialLotId AS DescendantLotId,
		Depth + 1,
		CAST( 
			CAST( CAST(substring(CAST(la.AncestorHash AS binary(16)),1,8) as binary(8)) ^ CAST(substring(CAST(mla.ParentMaterialLotId AS binary(16)),1,8) as bigint) as binary(8)) + 
			CAST( CAST(substring(CAST(la.AncestorHash AS binary(16)),9,8) as binary(8)) ^ CAST(substring(CAST(mla.ParentMaterialLotId AS binary(16)),9,8) as bigint) as binary(8))
		AS UNIQUEIDENTIFIER) AS AncestorHash
	FROM LotAssemblies AS la	
	INNER JOIN dbo.MaterialLotAssembly AS mla ON la.DescendantLotId = mla.ParentMaterialLotId	
)

SELECT
	la.Depth,
	la.AncestorLotId,
	la.ParentLotId, 
	el.S95Id AS Descendant,
	la.DescendantLotId,
	md.S95Id AS DescendantMaterial,
	el.MaterialLotId AS DescendantMaterialId,
	la.AncestorHash
FROM LotAssemblies AS la
INNER JOIN dbo.MaterialLot el ON la.DescendantLotId = el.MaterialLotId
INNER JOIN dbo.MaterialDefinition md ON el.MaterialDefinitionId = md.MaterialDefinitionId