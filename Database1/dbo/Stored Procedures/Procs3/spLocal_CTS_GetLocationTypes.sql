--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetLocationTypes
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

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_GetLocationTypes] 


*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CTS_GetLocationTypes]

		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100),
@tfIdLocationType				int,
@TableIdProdUnits				int


SET @TableIdProdUnits	= (	SELECT tableId 
							FROM dbo.tables WITH(NOLOCK) 
							WHERE TableName = 'Prod_units'
							)

SET @tfIdLocationType	= (	SELECT table_field_id 
							FROM dbo.table_fields WITH(NOLOCK) 
							WHERE tableid = @TableIdProdUnits 
								AND Table_Field_Desc = 'CTS location type'
								)


SELECT DISTINCT tfv.value as 'LocationTypes'
FROM dbo.Prod_Units_Base pu			WITH(NOLOCK)
JOIN dbo.Table_Fields_Values tfv	WITH(NOLOCK)	ON pu.pu_id = tfv.KeyId AND tfv.Table_Field_Id =  @tfIdLocationType
WHERE pu.Equipment_Type = 'CTS Location'
ORDER BY tfv.value ASC



LaFin:

SET NOCOUNT OFF

RETURN
