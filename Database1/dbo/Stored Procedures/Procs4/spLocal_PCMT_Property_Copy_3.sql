
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Copy_3]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-02
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	5-Feb-2004
Version		:	1.0.0
Purpose 		: 	Copy the current active_spec of a given property in the new porperty
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intPropId		integer,
@vcrPropDesc	varchar(50)

AS
SET NOCOUNT ON

DECLARE
@intNewPropId	integer

SELECT @intNewPropId = prop_id
FROM dbo.Product_Properties
WHERE prop_desc = @vcrPropDesc

--Copyt Active_Specs
INSERT dbo.Active_Specs (effective_date, expiration_date, 
                     	test_freq, spec_id, char_id, 
                     	l_entry, l_reject, l_warning, 
                     	l_user, target, u_user, 
                     	u_warning, u_reject, u_entry, is_defined)
SELECT a.effective_date, a.expiration_date, 
       a.test_freq, s2.spec_id, c2.char_id, 
       a.l_entry, a.l_reject, a.l_warning, 
       a.l_user, a.target, a.u_user, 
       a.u_warning, a.u_reject, a.u_entry, a.is_defined
FROM dbo.Active_Specs a
     join dbo.Specifications s1 on s1.spec_id = a.spec_id
     join dbo.Specifications s2 on s2.spec_desc = s1.spec_desc and 
                               	  s2.prop_id = @intNewPropId
     join dbo.Characteristics c1 on c1.char_id = a.char_id
     join dbo.Characteristics c2 on c2.char_desc = c1.char_desc and 
                                		c2.prop_id = @intNewPropId
WHERE s1.prop_id = @intPropId and
      c1.prop_id = @intPropId

SET NOCOUNT OFF















