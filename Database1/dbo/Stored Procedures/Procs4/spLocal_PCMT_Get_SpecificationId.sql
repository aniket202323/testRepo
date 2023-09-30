













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_SpecificationId]
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
Purpose		: 	This sp returns specification id if any.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@strSpec_Desc		varchar(50),
@intProp_Id			integer

AS

SET NOCOUNT ON

SELECT 
	spec_id 
FROM 
	dbo.specifications 
WHERE 
	spec_desc = @strSpec_Desc AND
	prop_id = @intProp_Id

SET NOCOUNT OFF















