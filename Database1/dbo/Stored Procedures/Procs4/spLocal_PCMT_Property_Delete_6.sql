﻿













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Delete_6]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-03
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	5-Feb-2004
Version		:	1.0.0
Purpose		: 	Delete characteristics and groups for a given property
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intPropId	integer

AS
SET NOCOUNT ON

--Delete char groups members
DELETE
FROM dbo.Characteristic_Group_Data
WHERE characteristic_grp_id IN (SELECT characteristic_grp_id
                                FROM dbo.Characteristic_Groups
                                WHERE prop_id = @intPropId)
--Delete char groups
DELETE
FROM dbo.Characteristic_Groups
WHERE prop_id = @intPropId

--Delete Characterisitics
DELETE 
FROM dbo.Characteristics
WHERE prop_id = @intPropId

SET NOCOUNT OFF














