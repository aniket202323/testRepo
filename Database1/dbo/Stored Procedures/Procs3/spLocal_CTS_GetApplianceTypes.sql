

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetApplianceTypes
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-19
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Return all possible Location Types to fill comboBox 
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

exec [dbo].[spLocal_CTS_GetApplianceTypes]


*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_GetApplianceTypes]
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
	DISTINCT	tfv.value as 'ApplianceTypes' 
	FROM		dbo.prdExec_Input_sources PEIS WITH(NOLOCK)
				JOIN dbo.prdExec_Inputs PEI WITH(NOLOCK) 
					ON PEI.pei_id = PEI.pei_id
				JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK)	
					ON tfv.keyid = PEIS.PU_Id 
				AND tfv.Table_Field_Id =  @tfIdLocationType
	WHERE		PEI.Input_name = 'CTS Appliance' 
				AND PEI.PU_ID = @destination_location_PUId	
END
ELSE
BEGIN
	SELECT DISTINCT tfv.value as 'ApplianceTypes'
	FROM dbo.Table_Fields_Values tfv WITH(NOLOCK)	
	WHERE tfv.Table_Field_Id =  @tfIdLocationType
	ORDER BY tfv.value ASC
END

LaFin:

SET NOCOUNT OFF

RETURN
