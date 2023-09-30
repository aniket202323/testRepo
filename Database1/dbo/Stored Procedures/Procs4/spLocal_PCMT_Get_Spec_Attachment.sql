













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Spec_Attachment]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	17-Dec-2002	
Version		: 	1.0.0
Purpose		: 	This sp verifies if the spec is attached to at least one variable.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intSpec_Id		integer

AS
SET NOCOUNT ON

SELECT TOP 1 
	spec_id 
FROM
	dbo.variables 
WHERE 
	spec_id = @intSpec_Id
ORDER BY
	spec_id ASC

SET NOCOUNT OFF















