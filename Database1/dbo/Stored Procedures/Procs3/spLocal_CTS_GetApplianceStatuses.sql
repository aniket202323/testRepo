--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetApplianceStatuses
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-19
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Return all possible Appliance statuses  to fill comboBox 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-19		U.Lapierre				Initial Release 
-- 1.1		2022-01-11		F.Bergeron				Add parameter to filter location based on destination location 
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_GetApplianceStatuses] 8451


*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CTS_GetApplianceStatuses]
@destination_location_PUId integer = NULL
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100),
@tfIdLocationType				int,
@TableIdProdUnits				int

--DECLARE @output TABLE

SET @TableIdProdUnits	= (	SELECT tableId 
							FROM dbo.tables WITH(NOLOCK) 
							WHERE TableName = 'Prod_units'
							)

SET @tfIdLocationType	= (	SELECT table_field_id 
							FROM dbo.table_fields WITH(NOLOCK) 
							WHERE tableid = @TableIdProdUnits 
								AND Table_Field_Desc = 'CTS Appliance type'
						)

IF @destination_location_PUId IS NOT NULL
BEGIN
	SELECT 
	DISTINCT	PS.ProdStatus_Id, 
				PS.ProdStatus_Desc
	FROM		dbo.prdExec_Input_sources PEIS WITH(NOLOCK)
				JOIN dbo.prdExec_Inputs PEI WITH(NOLOCK) 
					ON PEI.pei_id = PEIS.pei_id
				JOIN dbo.prdexec_input_source_data PEISD WITH(NOLOCK)
					ON PEISD.peis_id = PEIS.peis_id
				JOIN dbo.production_status PS WITH(NOLOCK)
					ON PS.prodstatus_id = PEISD.valid_status
				JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK)	
					ON tfv.keyid = PEIS.PU_Id 
				--AND tfv.Table_Field_Id =  @tfIdLocationType
	WHERE		PEI.Input_name ='CTS location transition' 
				AND PEI.PU_ID = @destination_location_PUId
END
ELSE
BEGIN
	SELECT DISTINCT ps.ProdStatus_Id, ps.ProdStatus_Desc
	FROM dbo.Prod_Units_Base pu			WITH(NOLOCK)
	JOIN dbo.PrdExec_Status pes			WITH(NOLOCK)	ON pu.pu_id = pes.pu_id
	JOIN dbo.Production_Status ps		WITH(NOLOCK)	ON pes.Valid_Status = ps.ProdStatus_Id
	WHERE pu.Equipment_Type = 'CTS Location'
	ORDER BY ps.ProdStatus_Desc ASC
END

LaFin:

SET NOCOUNT OFF

RETURN
