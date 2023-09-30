-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppGetPossibleStorageLocForPath]
@pathCode				varchar(50)


	
AS
SET NOCOUNT ON

DECLARE 
		--Generic
		@SPName						varchar(255),

		--Path/PO
		@pathId						int,
		@TableId					int,	--V1.3
		@PE_WMS_SYSTEM_Id			int		--V1.3



SELECT	@SPName		= 	'spLocal_CmnMobileAppGetPossibleStorageLocForPath'


INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0000 - SP triggered',
		@pathCode)



--Get the Path_id
SET @pathId = (SELECT path_id FROM dbo.prdExec_Paths WITH(NOLOCK) WHERE path_code = @pathCode)
IF @pathId IS NULL
BEGIN
	INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
	VALUES (getdate(),
		@SPName,	
		'0015 - Invalid Path code',
		@pathCode)

	SELECT 0,'Invalid Path code'
	RETURN
END

--V1.3
SET @TableId			=	(SELECT TableID FROM dbo.Tables WITH(NOLOCK) WHERE tableName = 'PRDExec_inputs')
SET @PE_WMS_SYSTEM_Id	=	(SELECT Table_Field_Id 	FROM dbo.Table_Fields 	WITH(NOLOCK)	WHERE Table_Field_Desc = 'PE_WMS_System' AND tableid = @TableId)	



----Remove in V1.3
----Retrieve the storage location based on path
--SELECT DISTINCT		peis.pu_id as 'pu_id', 
--					pu.pu_desc as 'Location'
--FROM dbo.prdExec_path_units pepu				WITH(NOLOCK)
--JOIN dbo.prdExec_inputs pei						WITH(NOLOCK) ON pepu.pu_id = pei.pu_id
--JOIN dbo.prdExec_input_sources peis				WITH(NOLOCK) ON pei.pei_id = peis.pei_id
--JOIN dbo.prod_units_base pu						WITH(NOLOCK) ON peis.pu_id = pu.pu_id
--JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON pu.PU_ID = a.PU_ID 
--JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId
--WHERE	pepu.path_id = @pathId
--AND		peec.class = 'Order Materials'
--AND		Name= 'Proficy Managed'
--AND		Value = 1


--Retrieve the storage location based on path  V1.3
SELECT DISTINCT		peis.pu_id as 'pu_id', 
					pu.pu_desc as 'Location',
					peec.Value AS 'PrIMELocationId'
FROM dbo.prdExec_path_units pepu				WITH(NOLOCK)
JOIN dbo.prdExec_inputs pei						WITH(NOLOCK) ON pepu.pu_id = pei.pu_id
JOIN dbo.prdExec_input_sources peis				WITH(NOLOCK) ON pei.pei_id = peis.pei_id
JOIN dbo.prod_units_base pu						WITH(NOLOCK) ON peis.pu_id = pu.pu_id
JOIN dbo.table_fields_values	tfv				WITH(NOLOCK) ON pei.pei_id = tfv.keyid
																AND tfv.table_field_id = @PE_WMS_SYSTEM_Id
																AND tfv.tableid = @TableId
LEFT JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON pu.Pu_ID = a.PU_Id
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId AND  peec.class = 'PE:PrIME_WMS' AND peec.name = 'LocationId'
WHERE	pepu.path_id = @pathId
	AND tfv.value IN ('PrIME', 'RTCIS')
	--AND peec.class = 'PE:PrIME_WMS'
	--AND peec.name = 'LocationId'	



SET NOCOUNT OFF
RETURN