













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Delete_4]
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
Purpose		: 	Delete active specs, transactions and proexec_inputs for a given property
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intPropId	integer

AS
SET NOCOUNT ON

--Remove active specs
DELETE
FROM dbo.Active_Specs
WHERE spec_id IN (SELECT spec_id 
                  FROM dbo.Specifications
                  WHERE prop_id = @intPropId)

--Remove property transactions
DELETE 
FROM dbo.Trans_Properties
WHERE spec_id IN (SELECT spec_id 
                  FROM dbo.Specifications
                  WHERE prop_id = @intPropId)

DELETE
FROM dbo.PrdExec_Inputs
WHERE primary_spec_id IN (SELECT spec_id 
                          FROM dbo.Specifications
                          WHERE prop_id = @intPropId)

DELETE
FROM dbo.PrdExec_Inputs
WHERE alternate_spec_id IN (SELECT spec_id 
                            FROM dbo.Specifications
                            WHERE prop_id = @intPropId)

--Delete Char transactions
DELETE 
FROM dbo.Trans_Characteristics
WHERE prop_id = @intPropId

DELETE 
FROM dbo.Trans_Char_Links
WHERE from_char_id IN (SELECT char_id 
                       FROM dbo.Characteristics
                       WHERE prop_id = @intPropId)

DELETE 
FROM dbo.Trans_Char_Links
WHERE to_char_id IN (SELECT char_id 
                       FROM dbo.Characteristics
                       WHERE prop_id = @intPropId)

SET NOCOUNT OFF















