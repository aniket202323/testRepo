
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
-- 1.0			2014-09-23		Ugo Lapierre				Initial Release
-- 1.1			2015-09-11		Ugo Lapierre				Include the Alternate product in the output
-- 1.2			2015-10-24		BalaMurugan Rajendran		(TCS) Update OG to NULL for Alt Mat and keep value as YES for Alt mat
-- 1.3			2016-08-23      BalaMurugan Rajendran		(TCS) Unit does not exist -- PO in Error
--															Unit exist, Proficy Manged False then dont run validation
-- 1.4			2017-04-05		BalaMurugan Rajendran		(TCS) Modified for SCO download
-- 1.5			2017-10-24		BalaMurugan Rajendran		(TCS) Only raise BOM OG Errors based On Path UDP.
-- 1.6			2018-06-28		Ugo Lapierre				New output column: MatType (RTCIS = 1, SI = 2, Profycy Managed FALSE = 3)
-- 1.7			2018-07-12		U. Lapierre					use RMI instead of SOA property to figure out MatType (FO-03436)
-- 1.8			2018-09-12		Julien B. Ethier			Use PE_WMS_System UDP
-- 1.9			2018-09-14		Julien B. Ethier			Remove Proficy Managed
-- 1.10			2018-11-20		U.Lapierre					Fix bugs introduced in 1.8 and 1.9
-- 1.11			2019-11-18		U.lapierre					FO-04238 Fix Table_fields issue
---------------------------------------------------------------------------------------------------		
---------------------------------------------------------------------------------------------------
-- TEST CODE
---------------------------------------------------------------------------------------------------
/*
Declare @ErrorMsg Varchar(3000) 
 Declare @ErrorMsg1 Varchar(3000)
 Declare @scoline int 
EXEC		[spLocal_CmnWFGetBOMByPPID] 12023, @ErrorMsg,@ErrorMsg1,@scoline


*/
---------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
CREATE PROCEDURE  [dbo].[spLocal_CmnWFGetBOMByPPID_ORIG]
--Declare
@PPID							int,
@ErrorMsg						Varchar(3000) OUTPUT,
@ErrorMsg1						Varchar(3000) OUTPUT,
@ISSCOLINE						Int OUTPUT


AS
--SELECT
--@PPID = 6917
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
@OGvalue						Varchar(100),
@pathid                         Int,
@PrdInputtableid				Int,
@isBomDownloadfieldid			Int,
@BOMMax							Int,
@BOMMin							Int,
@BOMOriginGroupid				Int,
@BOMOG							Varchar(10),
@ProcessOrder					Varchar(12),
@downloadableCount				Int,
@SCOTableFieldid				Int,
@ProdunitsTable					Int,
@NOBOMFieldid					Int,
@NOBOMRaiseError				Int,
@PEMultipleBOMFieldid			Int,
@MultipleBOMRaiseError			Int,
@TableIdRMI						int,		--V1.6
@OGUDPId						int,		--V1.7
@WMSSystemUDPId					int

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
SIManaged								int,
MatType									int
)


DECLARE @Prdexecpaths TABLE
(ID				Int Identity(1,1),
PUid			Int,
pathid			Int,
peiid			Int,
OG				varchar(10),
WMS_System		varchar(50)
)


Declare @EquipmentPuid TABLE
(ID				Int Identity(1,1),
PUid			Int,
ULINPUID		Int)


DECLARE @BomDownloadable TABLE
(ID          Int Identity(1,1),
isDownload bit,
peiid      int,
puid      int,
BOMOrigingGroup Varchar(10)
)


----------------------------------------------------------------------------------
--Get the tabel_field ID
----------------------------------------------------------------------------------
SET @TableId				= (	SELECT tableid			FROM dbo.tables			WITH (NOLOCK) 	WHERE tablename = 'Bill_Of_Material_Formulation_Item')
SET @OGTableField			= (	SELECT table_field_id	FROM dbo.table_fields	WITH (NOLOCK) 	WHERE tableid = @TableId AND table_field_desc = 'MaterialOriginGroup')
SET @PrdInputtableid		= (	SELECT tableid			FROM dbo.tables			WITH (NOLOCK) 	WHERE tablename = 'prdexec_Inputs')
SET @isBomDownloadfieldid	= (	SELECT table_field_id	FROM dbo.table_fields	WITH (NOLOCK) 	WHERE tableid = @PrdInputtableid AND table_field_desc = 'IsBomPLCDownload')
SET @BOMOriginGroupid		= (	SELECT table_field_id	FROM dbo.table_fields	WITH (NOLOCK) 	WHERE tableid = @PrdInputtableid AND table_field_desc = 'Origin Group')
SET @ProcessOrder			= ( SELECT Process_Order	FROM dbo.Production_Plan WITH (NOLOCK)	WHERE PP_Id = @PPID)
SET @ProdunitsTable			= (SELECT Tableid			FROM dbo.Tables			WITH (NOLOCK)	WHERE tablename like 'Prod_Units_Base')
SET @PathID					= (SELECT PATH_ID			FROM dbo.Production_Plan WITH (NOLOCK)	WHERE PP_Id = @PPId)
SET @SCOTableFieldid		= (SELECT TABLE_FIELD_ID	FROM dbo.Table_Fields	WITH (NOLOCK)	WHERE Table_Field_Desc like 'PE_General_IsSCOLine')
SET @NOBOMFieldid			= (SELECT TABLE_FIELD_ID	FROM dbo.Table_Fields	WITH (NOLOCK)	WHERE Table_Field_Desc like 'PENOBOMDownloadOG')
SET @PEMultipleBOMFieldid  =  (SELECT TABLE_FIELD_ID	FROM dbo.Table_Fields	WITH (NOLOCK)	WHERE Table_Field_Desc like 'PEMultipleBOMDownload')


--Get SI_Managed UDP  --V1.6
SET @TableIdRMI			= (	SELECT tableid			FROM dbo.tables	WITH (NOLOCK) 	WHERE tablename = 'prdExec_inputs')
SET @OGUDPId			= ( SELECT table_field_id FROM dbo.Table_Fields WITH (NOLOCK) WHERE Table_Field_Desc = 'Origin Group' AND tableid = @TableIdRMI)		--V1.7		
SET @WMSSystemUDPId		= ( SELECT table_field_id FROM dbo.Table_Fields WITH (NOLOCK) WHERE Table_Field_Desc = 'PE_WMS_System' AND tableid = @TableIdRMI)

IF EXISTS (SELECT tfv.Value 
					FROM Table_fields_VAlues tfv  WITH(NOLOCK)
					WHERE tfv.Table_Field_Id = @NOBOMFieldid and tfv.Keyid = @PathID)

BEGIN
SET @NOBOMRaiseError = (SELECT coalesce(Convert(int,tfv.Value),0) 
					FROM Table_fields_VAlues tfv  WITH(NOLOCK)
					WHERE tfv.Table_Field_Id = @NOBOMFieldid and tfv.Keyid = @PathID)
END
ELSE
BEGIN
SET @NOBOMRaiseError = 0
END


IF EXISTS (	SELECT tfv.Value 
			FROM Table_fields_VAlues tfv WITH(NOLOCK) 
			WHERE tfv.Table_Field_Id = @PEMultipleBOMFieldid and tfv.Keyid = @PathID)

BEGIN
SET @MultipleBOMRaiseError = (	SELECT coalesce(Convert(int,tfv.Value),0) 
								FROM Table_fields_VAlues tfv  WITH(NOLOCK)
								WHERE tfv.Table_Field_Id = @PEMultipleBOMFieldid and tfv.Keyid = @PathID)
END
ELSE
BEGIN
SET @MultipleBOMRaiseError = 0
END

IF EXISTS (	SELECT tfv.Value 
			FROM Table_fields_VAlues tfv WITH(NOLOCK) 
			WHERE tfv.Table_Field_Id = @SCOTableFieldid and tfv.Keyid = @PathID)

BEGIN
SET @ISSCOLINE = (SELECT coalesce(Convert(int,Value),0) 
					FROM Table_fields_VAlues tfv WITH(NOLOCK) 
					WHERE tfv.Table_Field_Id = @SCOTableFieldid and tfv.Keyid = @PathID)
END
ELSE
BEGIN
SET @ISSCOLINE = 0
END

INSERT @Prdexecpaths ( pathid,PUid,peiid)
(SELECT path_id,pei.pu_id,pei.Pei_Id FROM dbo.PrdExec_Path_Units ppu WITH (NOLOCK) 
JOIN dbo.prdexec_Inputs pei WITH (NOLOCK) ON Pei.pu_id = ppu.pu_id
WHERE Path_Id = @pathid)


INSERT @BomDownloadable(peiid,isDownload,puid,BOMOrigingGroup)
(	SELECT tfv.keyid,tfv.Value,pxp.PUid,tfv1.Value
	FROM dbo.Table_Fields_Values tfv WITH (NOLOCK) 
	JOIN @Prdexecpaths pxp ON pxp.peiid = tfv.KeyId
	JOIN Table_Fields_Values tfv1 WITH (NOLOCK)  ON tfv1.keyid = pxp.peiid 
													AND tfv1.Table_Field_Id = @BOMOriginGroupid
	WHERE tfv.TableId = @PrdInputtableid 
		AND tfv.Table_Field_Id = @isBomDownloadfieldid	AND tfv.Value = '1')

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
Alternate
)
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
		'NO'
		
FROM		dbo.production_plan pp
JOIN		dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK) ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
JOIN		dbo.Products p								WITH(NOLOCK) ON p.Prod_Id = bomfi.Prod_Id
JOIN		dbo.Engineering_Unit eu						WITH(NOLOCK) ON eu.Eng_Unit_Id = bomfi.Eng_Unit_Id
LEFT JOIN	dbo.Bill_Of_Material_Substitution bomfs		WITH(NOLOCK) ON bomfs.BOM_Formulation_Item_Id = bomfi.BOM_Formulation_Item_Id
LEFT JOIN	dbo.Products p_sub							WITH(NOLOCK) ON p_sub.Prod_Id = bomfs.Prod_Id
LEFT JOIN	dbo.Engineering_Unit eu_sub					WITH(NOLOCK) ON eu_sub.Eng_Unit_Id = bomfs.Eng_Unit_Id
LEFT JOIN	dbo.Prod_Units pu								WITH(NOLOCK) ON bomfi.PU_Id = pu.PU_Id
LEFT JOIN	dbo.PAEquipment_Aspect_SOAEquipment pa		WITH(NOLOCK) ON pu.pu_id = pa.pu_id
LEFT JOIN	dbo.table_fields_values tfv						WITH(NOLOCK) ON tfv.keyid = bomfi.BOM_Formulation_Item_Id
																				AND tfv.table_field_id = @OGTableField
WHERE	pp.pp_id = @ppid





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
	Alternate)
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
		'YES'
FROM @BOM
WHERE	AltProdId IS NOT NULL
		AND NOT EXISTS (SELECT prodid FROM @BOM WHERE prodid = altprodid)
SELECT @max = (SELECT COUNT(*) FROM @BOM)
SELECT @min = 1
WHILE (@min <=@max)
BEGIN		
SET @value = (	Select PMM.VALUE from dbo.Property_MaterialDefinition_MaterialClass PMM WITH (NOLOCK)
				JOIN [dbo].[Products_Aspect_MaterialDefinition] a WITH(NOLOCK) ON PMM.[MaterialDefinitionId] = a.[Origin1MaterialDefinitionId]
				JOIN @BOM B on a.prod_id = B.prodId
				AND B.ID = @min
				WHERE PMM.Name LIKE 'ORIGIN GROUP')
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



--Set the OG, SI_Managed and RTCIS_managed
UPDATE RMI
SET OG = CONVERT(varchar(50),tfv1.value),
	WMS_System = CONVERT(varchar(50),tfv2.value)
FROM @Prdexecpaths RMI
JOIN dbo.Table_Fields_Values tfv1 WITH(NOLOCK) ON RMI.peiid = tfv1.keyid
												AND tfv1.tableid = @TableIdRMI
												AND tfv1.Table_Field_Id = @OGUDPId
LEFT JOIN dbo.Table_Fields_Values tfv2 WITH(NOLOCK) ON RMI.peiid = tfv2.keyid
														AND tfv2.tableid = @TableIdRMI
														AND tfv2.Table_Field_Id = @WMSSystemUDPId




--V1.7  Set SI_managed,Set RTCIS_managed
UPDATE b
SET SIManaged = 1
FROM @BOM b
JOIN @Prdexecpaths rmi ON b.OG = rmi.OG
WHERE UPPER(rmi.WMS_System) = 'WAMAS'



--V1.7  Set SI_managed,Set RTCIS_managed
UPDATE b
SET MatType = (CASE	WHEN WMS_System = 'RTCIS' THEN 1 
						WHEN WMS_System = 'PrIME' THEN 1
						WHEN WMS_System = 'WAMAS' THEN 2
						ELSE 3
					END )
FROM @BOM b
JOIN @Prdexecpaths rmi ON b.OG = rmi.OG






SET @ErrorMsg = ''
SET @ErrorMsg1 = ''





SET @BOMMax = (SELECT COUNT(*) FROM @BomDownloadable)
SET @BOMMin = 1

WHILE (@BOMMin <= @BOMMax)



BEGIN
SET @BOMOG = (SELECT BOMOrigingGroup FROM @BomDownloadable bd Where bd.id = @BOMMin)
SET @downloadableCount = ( SELECT COUNT(*) FROM @BOM WHERE OG = @BOMOG)

IF (@downloadableCount = 0)
BEGIN
IF (@NOBOMRaiseError = 1)
BEGIN

IF (@ErrorMsg <> '')
BEGIN
SELECT @ErrorMsg = @Errormsg + ','+ @BOMOG 
END
ELSE
BEGIN
SELECT @ErrorMsg = @BOMOG 
END
END

END

IF (@downloadableCount > 1)
BEGIN

IF ( @MultipleBOMRaiseError = 1)
BEGIN

IF (@ErrorMsg1 <> '')
BEGIN
SELECT @ErrorMsg1 = @ErrorMsg1 + ','+ @BOMOG 
END
ELSE
BEGIN
SELECT @ErrorMsg1 = @BOMOG 
END
END
END

SET @BOMMin = @BOMMin + 1
END


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
SIManaged,
MatType
FROM @BOM

SELECT @ErrorMsg
SELECT @ErrorMsg1
SELECT @ISSCOLINE

RETURN

SET NOCOUNT OFF
