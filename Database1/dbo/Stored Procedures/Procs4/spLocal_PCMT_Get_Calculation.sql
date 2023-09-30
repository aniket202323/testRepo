













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Calculation]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	: 	Marc Charest, Solutions et Technologies Industrielles Inc.
On				: 	29-Nov-2002	
Version		: 	1.0.0
Purpose		: 	Gets all Proficy's calculations
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

AS

SET NOCOUNT ON

SELECT 
  calculation_id, calculation_name 
FROM 
  dbo.calculations 
ORDER BY 
  calculation_name ASC

SET NOCOUNT OFF















