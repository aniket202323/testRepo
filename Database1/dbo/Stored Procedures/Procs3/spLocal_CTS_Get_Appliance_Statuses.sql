
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetApplianceLocations
--------------------------------------------------------------------------------------------------
-- Author				: F.Bergeron, Symasol
-- Date created			: 2022-03-22
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
-- 1.0		2022-03-22		F.Bergeron				Initial Release 
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_Get_Appliance_Statuses]

*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_Appliance_Statuses]
	
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100)

DECLARE @output TABLE
(
status_id integer,
status_desc varchar(25)
)


INSERT INTO @output 
(
	status_id,
	status_desc
)
SELECT DISTINCT ps.ProdStatus_Id, ps.ProdStatus_Desc
	FROM dbo.Prod_Units_Base pu			WITH(NOLOCK)
	JOIN dbo.PrdExec_Status pes			WITH(NOLOCK)	ON pu.pu_id = pes.pu_id
	JOIN dbo.Production_Status ps		WITH(NOLOCK)	ON pes.Valid_Status = ps.ProdStatus_Id
	WHERE pu.Equipment_Type = 'CTS Appliance'
	ORDER BY ps.ProdStatus_Desc ASC

SELECT 	status_id,
		status_desc
FROM	@output
LaFin:

SET NOCOUNT OFF

RETURN
