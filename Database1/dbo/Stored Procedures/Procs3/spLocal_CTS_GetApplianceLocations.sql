

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetApplianceLocations
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
-- 1.2		2022-03-22		F.Bergeron				Add parameter to filter by location type
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_GetApplianceLocations] 8463


*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_GetApplianceLocations]
@destination_location_PUId	integer = NULL,
@location_type				varchar(25) = NULL			
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100)

DECLARE @output TABLE
(
pu_id		integer,
pu_desc		varchar(50),
type		varchar(25)
)


INSERT INTO @output 
(
	pu_Id, 
	pu_desc,
	type
)
SELECT DISTINCT	puB.pu_id, 
				puB.pu_desc,
				TFV.Value
FROM			dbo.Prod_Units_Base puA	WITH(NOLOCK)
				JOIN dbo.prdExec_input_Sources peis	WITH(NOLOCK) 
					ON puA.pu_id = peis.pu_id
				JOIN dbo.prdExec_inputs	pei	WITH(NOLOCK) 
					ON peis.pei_id = pei.pei_id
				JOIN dbo.prod_units_Base puB WITH(NOLOCK) 
					ON pei.pu_id = puB.pu_id
				LEFT JOIN dbo.table_fields_values TFV WITH(NOLOCK)
					ON TFV.keyId = PUB.Pu_Id
				LEFT JOIN dbo.table_fields TF WITH(NOLOCK) 
					ON TF.Table_field_id = TFV.table_field_Id
				LEFT JOIN dbo.tables T WITH(NOLOCK)
					ON T.tableId = TF.tableId
WHERE			T.TableName = 'Prod_units' 
				AND TF.Table_Field_Desc = 'CTS location Type'
				AND puA.Equipment_Type = 'CTS Appliance'


-- REMOVE ALL LOCATION THAT CAN FEED DESTINATION
IF @destination_location_PUId IS NOT NULL
BEGIN
	DELETE	@output 
	WHERE	pu_id NOT IN	(
							SELECT DISTINCT	puA.pu_id
							FROM			dbo.Prod_Units_Base puA	WITH(NOLOCK)
											JOIN dbo.prdExec_input_Sources peis	WITH(NOLOCK) 
												ON puA.pu_id = peis.pu_id
											JOIN dbo.prdExec_inputs	pei	WITH(NOLOCK) 
												ON peis.pei_id = pei.pei_id
											JOIN dbo.prod_units_Base puB WITH(NOLOCK) 
												ON pei.pu_id = puB.pu_id
							WHERE			pei.Input_Name = 'CTS Location Transition'
											AND pei.pu_id = @destination_location_PUId
							)
	IF @location_type IS NOT NULL
		DELETE	@output 
		WHERE	type != @location_type

END

SELECT 	pu_Id, 
		pu_desc
FROM	@output
LaFin:

SET NOCOUNT OFF

RETURN
