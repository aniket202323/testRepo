

--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_GetLocationStatuses
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre, Symasol
-- Date created			: 2021-10-19
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application
-- Description			: Return all possible Location Statuses to fill comboBox 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--



--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-19		U.Lapierre				Initial Release 
-- 1.1		2022-06-02		F.Bergeron				Remove union to a virtual status; Active cleaning

--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

exec [dbo].[spLocal_CTS_GetLocationStatuses] 


*/

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_GetLocationStatuses]

		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON

DECLARE
@SPName							varchar(100)


--Use custom datatype
SELECT 'Dirty' as 'LocationStatuses'
UNION
SELECT 'Clean'
UNION
SELECT 'In use'

LaFin:

SET NOCOUNT OFF

RETURN
