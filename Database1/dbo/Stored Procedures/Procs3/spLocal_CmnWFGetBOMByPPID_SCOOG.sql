



--------------------------------------------------------------------------------------------------
-- Stored Procedure		: [spLocal_CmnWFGetBOMByPPID]
--------------------------------------------------------------------------------------------------
-- Author				:	Ugo Lapierre
-- Date created			:	2014-09-23
-- Version 				:	Version 1.0
-- SP Type				:	Workflow
-- Caller				:	Workflow PE:ValidateProcessOrder
-- Description			:

-- This SP retrieve the latest PO downloaded


-- Editor tab spacing	: 4 
---------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
---------------------------------------------------------------------------------------------------
-- 1.0			2014-09-23		Ugo Lapierre		Initial Release
-- 1.1			2015-09-11		Ugo Lapierre		Include the Alternate product in the output
-- 1.2			2015-10-24		BalaMurugan Rajendran (TCS) Update OG to NULL for Alt Mat and keep value as YES for Alt mat
-- 1.3			2016-08-23      BalaMurugan Rajendran (TCS) Unit does not exist -- PO in Error
--															Unit exist, Proficy Manged False then dont run validation

---------------------------------------------------------------------------------------------------		

---------------------------------------------------------------------------------------------------
-- TEST CODE
---------------------------------------------------------------------------------------------------
/*
EXEC		[spLocal_CmnWFGetBOMByPPID] 6361
*/
---------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------

CREATE PROCEDURE  [dbo].[spLocal_CmnWFGetBOMByPPID_SCOOG]
@PPID							int


AS
SET NOCOUNT ON 
-------------------------------------------------------------------------------
-- TASK 1 Declare variables
-------------------------------------------------------------------------------
DECLARE 
@OGTableField					int,
@TableId						int,
@max							int,
@min							int,
@value							SQL_Variant,
@OGvalue							Varchar(100),
@ProficyManaged						Varchar(20),
@PrdInputTableid					Int,
@OriginGroupid						Int,
@pathid								Int
					
DECLARE @PrdexInputs Table(
ID			Int Identity(1,1),
puid		Int,
Peiid		Int)




DECLARE @BOM	TABLE (
ID Int Identity(1,1),
BomfiId									int,
prodId									int,
prodCode								varchar(50),
prodDesc								varchar(200),
OG										varchar(30),
UOM										varchar(30),
Quantity								float,
AltProdId								int,
AltProdCode								varchar(50),
AltProdDesc								varchar(100),
AltUOM									varchar(30),
puid									int,
pudesc									varchar(50),
equipmentId								UniqueIdentifier,
EquipmentType							varchar(50),
Alternate                               Varchar(10),
ProficyManaged							INT
)



----------------------------------------------------------------------------------
--Get the tabel_field ID
----------------------------------------------------------------------------------
SET @TableId		= (	SELECT tableid			FROM dbo.tables		WHERE tablename = 'Bill_Of_Material_Formulation_Item')
SET @PrdInputTableid= (	SELECT tableid			FROM dbo.tables		WHERE tablename = 'Prdexec_Inputs')
SET @OGTableField	= (	SELECT table_field_id	FROM dbo.table_fields	WHERE tableid = @TableId AND table_field_desc = 'MaterialOriginGroup')
SET @ProficyManaged = ( SELECT PropertyName FROM dbo.Property_EquipmentClass With (NOLOCK) WHERE PropertyName like 'Proficy Managed')
SET @OriginGroupid	= (	SELECT table_field_id	FROM dbo.table_fields	WHERE tableid = @PrdInputTableid AND table_field_desc = 'Origin Group')
SET @pathid			= (SELECT Path_id FROM dbo.Production_plan WITH (NOLOCK) WHERE Pp_id = @PPID)




----------------------------------------------------------------------------------
--Get BOM
----------------------------------------------------------------------------------
INSERT @BOM(
BomfiId,
prodId,
prodCode,
prodDesc,
OG,
UOM	,
Quantity,
AltProdId,
AltProdCode,
AltProdDesc	,
AltUOM,
puid,
pudesc,
equipmentId,
EquipmentType,
Alternate,
ProficyManaged)
SELECT	bomfi.BOM_Formulation_Item_Id,
		bomfi.Prod_Id, 
		p.Prod_Code, 
		p.Prod_Desc,
		tfv.value,
		eu.Eng_Unit_Desc,
		bomfi.Quantity,
		bomfs.Prod_Id,
		p_sub.Prod_Code,
		p_sub.prod_Desc,
		eu_sub.Eng_Unit_Desc,
		pu.PU_Id,
		pu.PU_Desc,
		pa.Origin1EquipmentId,
		pu.Equipment_Type,
		'NO',
		COALESCE (Convert(int,PEE.Value),0)

FROM		dbo.production_plan pp
JOIN		dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK) ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
JOIN		dbo.Products p								WITH(NOLOCK) ON p.Prod_Id = bomfi.Prod_Id
JOIN		dbo.Engineering_Unit eu						WITH(NOLOCK) ON eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id
LEFT JOIN	dbo.Products p_sub							WITH(NOLOCK) ON p_sub.Prod_Id = bomfs.Prod_Id
LEFT JOIN	dbo.Engineering_Unit eu_sub					WITH(NOLOCK) ON eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id
LEFT JOIN	dbo.Prod_Units pu								WITH(NOLOCK) ON bomfi.PU_Id = pu.PU_Id
LEFT JOIN	dbo.PAEquipment_Aspect_SOAEquipment pa		WITH(NOLOCK) ON pu.pu_id = pa.pu_id
LEFT JOIN dbo.Property_Equipment_Equipmentclass PEE WITH(NOLOCK) ON PEE.EquipmentID = pa.Origin1EquipmentId
AND PEE.Name like @ProficyManaged
LEFT JOIN	dbo.table_fields_values tfv						WITH(NOLOCK) ON tfv.keyid = bomfi.BOM_Formulation_Item_Id
																				AND tfv.table_field_id = @OGTableField
WHERE	pp.pp_id = @ppid


Select 'Austin', * From @BOM
/*
For each alternate material add a new line in the temp table if 
the alternate is not a primary of another BOMFI
*/
INSERT @BOM(
	BomfiId,
	prodId,
	prodCode,
	prodDesc,
	OG,
	UOM	,
	Quantity,
	puid,
	pudesc,
	equipmentId,
	EquipmentType,
	Alternate,
	ProficyManaged)
SELECT 	NULL,
		AltProdId,
		AltProdCode,
		AltProdDesc,
		NULL,
		COALESCE(AltUOM,UOM),
		Quantity,
		puid,
		pudesc,
		equipmentId,
		EquipmentType,
		'YES',
		ProficyManaged
FROM @BOM
WHERE	AltProdId IS NOT NULL
		AND NOT EXISTS (SELECT prodid FROM @BOM WHERE prodid = altprodid)


SELECT @max = (SELECT COUNT(*) FROM @BOM)
SELECT @min = 1


WHILE (@min <=@max)
BEGIN		
SELECT @value = ( Select VALUE from dbo.Property_MaterialDefinition_MaterialClass PMM 
JOIN MaterialDefinition MD ON MD.MaterialDefinitionId = PMM.MaterialDefinitionId
JOIN @BOM B on MD.S95Id LIKE '%'+B.prodCode+'%'
AND B.ID = @min
WHERE Name LIKE 'ORIGIN GROUP')

SELECT @OGvalue = CONVERT(Varchar,@Value)

IF (LEN(@OGValue) > 1)
BEGIN
UPDATE @BOM 
SET Alternate = 'NO'
FROM @BOM B
WHERE B.ID = @min
END
ELSE
BEGIN
UPDATE @BOM
SET Alternate = 'YES'
FROM @BOM B
WHERE B.ID = @min
AND B.BomfiId IS  NULL
END
SET @min = @min + 1
END

Select 'Austin123', * From @BOM

DELETE FROM @BOM
WHERE ProficyManaged = 0
AND  equipmentId IS NOT NULL

----------------------------------------------------------------------------------
--Send output 
----------------------------------------------------------------------------------
SELECT 
ID,
BomfiId,
prodId,
prodCode,
prodDesc,
OG,
UOM,
Quantity,
AltProdId,
AltProdCode,
AltProdDesc,
AltUOM,
puid,
pudesc,
equipmentId,
EquipmentType,
Alternate,
ProficyManaged
FROM @BOM




		
	