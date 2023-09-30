CREATE PROCEDURE [dbo].spLocal_Production_CreateSegmentRequirement
--DROP PROCEDURE  [dbo].[spLocal_Production_CreateSegmentRequirement]
--GO
--CREATE PROCEDURE [dbo].[spLocal_Production_CreateSegmentRequirement]
@WDS95Id	nvarchar(50),
@WRS95Id	nvarchar(50),
@Name		nvarchar(50),
@Order		int
AS

DECLARE @WRId		uniqueidentifier,
		@WDSId		uniqueidentifier,
		@WDSIsMaster	bit,
		@Level		smallint,
		@Rows		int,
		@duplicateCount int

DECLARE	@AddedSegmentRequirements TABLE (
	SegReqId		uniqueidentifier PRIMARY KEY NONCLUSTERED,
	S95Id			nvarchar(50))	

DECLARE	@SegmentRequirements TABLE (
	Name			nvarchar(50),
	SegReqId		uniqueidentifier,
	ProdSegId		uniqueidentifier PRIMARY KEY NONCLUSTERED,
	TopOfHierarchy	bit DEFAULT 0)	

DECLARE	@Hierarchy TABLE (
	ParentProdSegId	uniqueidentifier,
	ChildProdSegId	uniqueidentifier,
	Name			nvarchar(50),
	Version			bigint DEFAULT 1,
	r_Order			int DEFAULT 0,
	Level			smallint DEFAULT 0,
	PRIMARY KEY (ParentProdSegId, ChildProdSegId))

DECLARE @EquipmentSpec TABLE (
	EquipmentSpecId			uniqueidentifier,
	SegReqId				uniqueidentifier,
	S95Id					nvarchar(50),
	S95Type					nvarchar(50),
	Description				nvarchar(255),
	QuantityUnitOfMeasure	nvarchar(50),
	Quantity				float,
	ESVersion				bigint,
	SpecificationType		nvarchar(255),
	EquipmentClassName		nvarchar(200),
	EquipmentId				uniqueidentifier,
	SEVersion				bigint)

DECLARE @MaterialSpec TABLE (
	MaterialSpecId			uniqueidentifier,
	SegReqId				uniqueidentifier,
	S95Id					nvarchar(50),
	S95Type					nvarchar(50),
	Description				nvarchar(255),
	r_Use					nvarchar(255),
	QuantityUnitOfMeasure	nvarchar(50),
	Quantity				float,
	MSVersion				bigint,
	SpecificationType		nvarchar(255),
	MaterialClassName		nvarchar(200),
	MaterialId				uniqueidentifier,
	MaterialLotId			uniqueidentifier,
	MaterialSublotId		uniqueidentifier,
	SMVersion				bigint)

DECLARE @PersonnelSpec TABLE (
	PersonnelSpecId			uniqueidentifier,
	SegReqId				uniqueidentifier,
	S95Id					nvarchar(50),
	S95Type					nvarchar(50),
	Description				nvarchar(255),
	QuantityUnitOfMeasure	nvarchar(50),
	Quantity				float,
	PSVersion				bigint,
	SpecificationType		nvarchar(255),
	PersonnelClassName		nvarchar(200),
	PersonnelId				uniqueidentifier,
	SPVersion				bigint)
	
DECLARE @Parameters TABLE (
	SegmentParameterId	uniqueidentifier,
	Name				nvarchar(255),
	Description			nvarchar(255),
	UnitOfMeasure		nvarchar(50),
	ValidationPattern	nvarchar(255),
	DataType			int,
	Version				bigint,
	r_Order				int,
	Value				sql_variant,
	Quality				smallint,
	Timestamp			datetime,
	SegReqId			uniqueidentifier)

/**********************************************
* Initialization
***********************************************/
SELECT	--@NewWDId		= NEWID(),
		--@NewMasterSegId	= NEWID(),
		@Rows			= 0,
		@Level			= 0

/**********************************************
* Error checking
**********************************************
1. Ensure that the provided work definition segment is valid
2. Ensure that the provided work definition segment is not a master segment
3. Ensure that the provided work request exists
4. Ensure that there is no pre-existing segment requirement of the same name on the associated work request object

Each error message is prefixed with an identification number: 50005, 50006, 50007, 50008
This allows us differentiate  the error in code

**********************************************/

SELECT	@WDSId = pds.ProdSegId
FROM dbo.ProdSeg pds
WHERE pds.S95Id = @WDS95Id

IF @WDSId IS NULL
BEGIN
	RAISERROR ('50005: Work Definition Segment with id: %s could not be found.', 11, 1, @WDS95Id)
	RETURN 1
END

SELECT @WDSIsMaster= pds.IsMaster
FROM dbo.ProdSeg pds
WHERE pds.S95Id = @WDS95Id

IF @WDSIsMaster=1
BEGIN
	RAISERROR ('50006: The given segment "%s" is a Master Segment.', 11, 1, @WDS95Id)
	RETURN 1
END

SELECT	@WRId = wr.WorkRequestId
FROM dbo.WorkRequest wr
WHERE wr.S95Id = @WRS95Id

IF @WRId IS NULL
BEGIN
	RAISERROR ('50007: Error: Could not find WorkRequest with S95Id "%s"', 11, 1, @WRS95Id)
	RETURN 1
END


SELECT @duplicateCount = COUNT(*)  
FROM dbo.SegReq sgr
WHERE sgr.S95Id = @Name and sgr.WorkRequestId = @WRId


IF @duplicateCount > 0
BEGIN
	RAISERROR ('50008: A Segment Requirement association with name: "%s" already exists.', 11, 1, @Name)
	RETURN 1
END


/**********************************************
 Build Hierarchy Table
***********************************************/

-- Add first level of product segments
INSERT @Hierarchy (
	ParentProdSegId,
	ChildProdSegId,
	Name,
	Version,
	r_Order)
SELECT	scp.ParentSegmentProdSegId,
		scp.ChildSegmentProdSegId,
		scp.Name,
		scp.Version,
		scp.r_Order
FROM dbo.SegmentIsComposedOf_ProdSeg scp
WHERE scp.ParentSegmentProdSegId = @WDSId

WHILE @@ROWCOUNT > 0
	BEGIN
	SELECT @Level = @Level + 1
	INSERT @Hierarchy(
		ParentProdSegId,
		ChildProdSegId,
		Name,
		Version,
		r_Order,
		Level)
	SELECT	scp.ParentSegmentProdSegId,
			scp.ChildSegmentProdSegId,
			scp.Name,
			scp.Version,
			scp.r_Order,
			@Level
	FROM dbo.SegmentIsComposedOf_ProdSeg scp 
		INNER JOIN @Hierarchy h ON h.ChildProdSegId = scp.ParentSegmentProdSegId 
	WHERE h.Level = @Level-1
	END

/**********************************************
* Build Segment Requirements table with new ids
***********************************************/
INSERT @SegmentRequirements (
	SegReqId,
	ProdSegId,
	TopOfHierarchy)
VALUES (
	NEWID(),
	@WDSId,
	1)
	
INSERT @SegmentRequirements (
	Name,
	SegReqId,
	ProdSegId)
SELECT
	h.Name,
	NEWID(),
	h.ChildProdSegId
FROM @Hierarchy h

/**********************************************
* Create Work Request Segment Hierarchy
***********************************************/
INSERT dbo.SegReq (
	SegReqId,
	ProductSegmentS95Id,
	ProcessSegmentS95Id,
	ProcessSegmentVersion,
	S95Id,
	r_Order,
	IsTopOfHierarchy,
	Duration,
	WorkType,
	Description,
	S95Type,
	Version,
	WorkRequestId,
	ProcSegId,
	IsMaster)
OUTPUT INSERTED.SegReqId, INSERTED.S95Id INTO @AddedSegmentRequirements
SELECT	psr.SegReqId,
		pds.S95Id,
		pcs.S95Id,
		pcs.Version,
		CASE psr.TopOfHierarchy
			WHEN 1 THEN @Name
			ELSE psr.Name
			END,
		0,
		psr.TopOfHierarchy,
		pds.Duration,
		pds.WorkType,
		pds.Description,
		'SegmentRequirement',
		pds.Version,
		@WRId,
		pcs.ProcSegId,
		pds.IsMaster
FROM @SegmentRequirements psr
	JOIN dbo.ProdSeg pds ON psr.ProdSegId = pds.ProdSegId
	JOIN dbo.ProductToProcess p2p ON psr.ProdSegId = p2p.ProdSegId
	JOIN dbo.ProcSeg pcs ON pcs.ProcSegId = p2p.ProcSegId

INSERT dbo.SegmentIsComposedOf_SegReq (
	Name,
	r_Order,
	Version,
	ParentSegmentSegReqId,
	ParentSegmentWorkRequestId,
	ChildSegmentSegReqId,
	ChildSegmentWorkRequestId)
SELECT	h.Name,
		h.r_Order,
		h.Version,
		ppsr.SegReqId,
		@WRId,
		cpsr.SegReqId,
		@WRId	
FROM @Hierarchy h
	JOIN @SegmentRequirements cpsr ON cpsr.ProdSegId = h.ChildProdSegId
	JOIN @SegmentRequirements ppsr ON ppsr.ProdSegId = h.ParentProdSegId


-- ...Equipment Specifications...
INSERT @EquipmentSpec (
	EquipmentSpecId,
	SegReqId,
	S95Id,
	S95Type,
	Description,
	QuantityUnitOfMeasure,
	Quantity,
	ESVersion,
	SpecificationType,
	EquipmentClassName,
	EquipmentId,
	SEVersion)
SELECT
	NEWID(),
	psr.SegReqId,
	eps.S95Id,
	eps.S95Type,
	eps.Description,
	eps.QuantityUnitOfMeasure,
	eps.Quantity,
	eps.Version,
	esp.SpecificationType,
	esp.EquipmentClassName,
	esp.EquipmentId,
	esp.Version
FROM dbo.SpecEquipment_EquipmentSpec_ProcSeg esp
	INNER JOIN dbo.EquipmentSpec_ProcSeg eps ON eps.EquipmentSpec_ProcSegId = esp.EquipmentSpec_ProcSegId
	INNER JOIN dbo.ProductToProcess p2p ON p2p.ProcSegId = eps.ProcSegId
	INNER JOIN @SegmentRequirements psr ON psr.ProdSegId = p2p.ProdSegId

INSERT dbo.EquipmentSpec_SegReq (
	EquipmentSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	S95Id,
	S95Type,
	Description,
	QuantityUnitOfMeasure,
	Quantity,
	Version)
SELECT
	es.EquipmentSpecId,
	es.SegReqId,
	@WRId,
	es.S95Id,
	es.S95Type,
	es.Description,
	es.QuantityUnitOfMeasure,
	es.Quantity,
	es.ESVersion
FROM @EquipmentSpec es

INSERT dbo.SpecEquipment_EquipmentSpec_SegReq (
	SpecEquipment_EquipmentSpec_SegReqId,
	EquipmentSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	SpecificationType,
	EquipmentClassName,
	EquipmentId,
	Version)
SELECT
	NEWID(),
	es.EquipmentSpecId,
	es.SegReqId,
	@WRId,
	es.SpecificationType,
	es.EquipmentClassName,
	es.EquipmentId,
	es.SEVersion	
FROM @EquipmentSpec es

-- ...Material Specifications...
INSERT @MaterialSpec (
	MaterialSpecId,
	SegReqId,
	S95Id,
	S95Type,
	Description,
	r_Use,
	QuantityUnitOfMeasure,
	Quantity,
	MSVersion,
	SpecificationType,
	MaterialClassName,
	MaterialId,
	MaterialLotId,
	MaterialSublotId,
	SMVersion)
SELECT
	NEWID(),
	psr.SegReqId,
	mps.S95Id,
	mps.S95Type,
	mps.Description,
	mps.r_Use,
	mps.QuantityUnitOfMeasure,
	mps.Quantity,
	mps.Version,
	msp.SpecificationType,
	msp.MaterialClassName,
	msp.MaterialDefinitionId,
	msp.MaterialLotId,
	msp.MaterialSublotId,
	msp.Version
FROM dbo.SpecMaterial_MaterialSpec_ProcSeg msp
	INNER JOIN dbo.MaterialSpec_ProcSeg mps ON mps.MaterialSpec_ProcSegId = msp.MaterialSpec_ProcSegId
	INNER JOIN dbo.ProductToProcess p2p ON p2p.ProcSegId = mps.ProcSegId
	INNER JOIN @SegmentRequirements psr ON psr.ProdSegId = p2p.ProdSegId

INSERT dbo.MaterialSpec_SegReq (
	MaterialSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	S95Id,
	S95Type,
	Description,
	r_Use,
	QuantityUnitOfMeasure,
	Quantity,
	Version)
SELECT
	ms.MaterialSpecId,
	ms.SegReqId,
	@WRId,
	ms.S95Id,
	ms.S95Type,
	ms.Description,
	ms.r_Use,
	ms.QuantityUnitOfMeasure,
	ms.Quantity,
	ms.MSVersion
FROM @MaterialSpec ms

INSERT dbo.SpecMaterial_MaterialSpec_SegReq (
	SpecMaterial_MaterialSpec_SegReqId,
	MaterialSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	SpecificationType,
	MaterialClassName,
	MaterialDefinitionId,
	MaterialLotId,
	MaterialSublotId,
	Version)
SELECT
	NEWID(),
	ms.MaterialSpecId,
	ms.SegReqId,
	@WRId,
	ms.SpecificationType,
	ms.MaterialClassName,
	ms.MaterialId,
	ms.MaterialLotId,
	ms.MaterialSublotId,
	ms.SMVersion	
FROM @MaterialSpec ms

-- ...Personnel Specifications...
INSERT @PersonnelSpec (
	PersonnelSpecId,
	SegReqId,
	S95Id,
	S95Type,
	Description,
	QuantityUnitOfMeasure,
	Quantity,
	PSVersion,
	SpecificationType,
	PersonnelClassName,
	PersonnelId,
	SPVersion)
SELECT
	NEWID(),
	psr.SegReqId,
	pps.S95Id,
	pps.S95Type,
	pps.Description,
	pps.QuantityUnitOfMeasure,
	pps.Quantity,
	pps.Version,
	psp.SpecificationType,
	psp.PersonnelClassName,
	psp.PersonId,
	psp.Version
FROM dbo.SpecPersonnel_PersonnelSpec_ProcSeg psp
	INNER JOIN dbo.PersonnelSpec_ProcSeg pps ON pps.PersonnelSpec_ProcSegId = psp.PersonnelSpec_ProcSegId
	INNER JOIN dbo.ProductToProcess p2p ON p2p.ProcSegId = pps.ProcSegId
	INNER JOIN @SegmentRequirements psr ON psr.ProdSegId = p2p.ProdSegId

INSERT dbo.PersonnelSpec_SegReq (
	PersonnelSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	S95Id,
	S95Type,
	Description,
	QuantityUnitOfMeasure,
	Quantity,
	Version)
SELECT
	ps.PersonnelSpecId,
	ps.SegReqId,
	@WRId,
	ps.S95Id,
	ps.S95Type,
	ps.Description,
	ps.QuantityUnitOfMeasure,
	ps.Quantity,
	ps.PSVersion
FROM @PersonnelSpec ps

INSERT dbo.SpecPersonnel_PersonnelSpec_SegReq (
	SpecPersonnel_PersonnelSpec_SegReqId,
	PersonnelSpec_SegReqId,
	SegReqId,
	WorkRequestId,
	SpecificationType,
	PersonnelClassName,
	PersonId,
	Version)
SELECT
	NEWID(),
	ps.PersonnelSpecId,
	ps.SegReqId,
	@WRId,
	ps.SpecificationType,
	ps.PersonnelClassName,
	ps.PersonnelId,
	ps.SPVersion	
FROM @PersonnelSpec ps

/**********************************************
* Create Parameters
***********************************************/
INSERT @Parameters (
	SegmentParameterId,
	[Name],
	Description,
	UnitOfMeasure,
	ValidationPattern,
	DataType,
	Version,
	r_Order,
	[Value],
	Quality,
	[Timestamp],
	SegReqId)
SELECT	NEWID(),
		pcs.S95Id+'.'+sp.[Name],
		sp.Description,
		sp.UnitOfMeasure,
		sp.ValidationPattern,
		sp.DataType,
		sp.Version,
		ISNULL(pss.r_Order, psp.r_Order),
		ISNULL(pss.Value,psp.Value),
		ISNULL(pss.Quality,psp.Quality),
		ISNULL(pss.TimeStamp,psp.TimeStamp),
		psr.SegReqId
FROM @SegmentRequirements psr
	INNER JOIN dbo.ProductToProcess p2p                ON p2p.ProdSegId = psr.ProdSegId
	INNER JOIN dbo.ProcSeg                         pcs ON pcs.ProcSegId = p2p.ProcSegId
	INNER JOIN dbo.ProcessSegment_SegmentParameter psp ON psp.ProcSegId = p2p.ProcSegId
	LEFT  JOIN dbo.SyncParameter_ProductToProcess_ProdSeg_ProcSeg pss ON	
                   pss.ProcSegId = p2p.ProcSegId 
               AND pss.ProdSegId = p2p.ProdSegId 
               AND pss.SegmentParameterPropertyId = psp.SegmentParameterPropertyId
 	LEFT JOIN dbo.SegmentParameter sp ON sp.SegmentParameterPropertyId = psp.SegmentParameterPropertyId

INSERT @Parameters (
	SegmentParameterId,
	[Name],
	Description,
	UnitOfMeasure,
	ValidationPattern,
	DataType,
	Version,
	r_Order,
	[Value],
	Quality,
	[Timestamp],
	SegReqId)
SELECT	NEWID(),
		sp.[Name],
		sp.Description,
		sp.UnitOfMeasure,
		sp.ValidationPattern,
		sp.DataType,
		sp.Version,
		pdp.r_Order,
		pdp.[Value],
		pdp.Quality,
		pdp.[TimeStamp],
		psr.SegReqId
FROM dbo.SegmentParameter sp
	INNER JOIN dbo.ProductSegment_SegmentParameter pdp ON pdp.SegmentParameterPropertyId = sp.SegmentParameterPropertyId
	INNER JOIN @SegmentRequirements psr ON psr.ProdSegId = pdp.ProdSegId

INSERT INTO dbo.SegmentParameter (
	SegmentParameterPropertyId,
	[Name],
	Description,
	S95Type,
	UnitOfMeasure,
	PublishName,
	ValidationPattern,
	DataType,
	Version)
SELECT	p.SegmentParameterId,
		p.[Name],
		p.Description,
		'WorkParameter',
		p.UnitOfMeasure,
		p.SegmentParameterId,
		p.ValidationPattern,
		p.DataType,
		p.Version
FROM @Parameters p

INSERT INTO dbo.SegmentRequirement_SegmentParameter (
	SegReqId,
	WorkRequestId,
	SegmentParameterPropertyId,
	Value,
	TimeStamp,
	Quality,
	r_Order,
	Version)
SELECT	p.SegReqId,
		@WRId,
		p.SegmentParameterId,
		p.Value,
		p.Timestamp,
		p.Quality,
		p.r_Order,
		p.Version
FROM @Parameters p

-- return the new segment requirement id
SELECT SegReqId
  FROM @AddedSegmentRequirements
 WHERE S95Id = @Name