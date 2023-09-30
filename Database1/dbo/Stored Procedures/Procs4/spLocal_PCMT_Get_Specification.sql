













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Specification]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner (System Technologies for Industry Inc)
Date			:	2008-04-09
Version		:	2.1.0
Purpose		: 	Now returns spec_desc_global
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2006-10-05
Version		:	2.0.0
Purpose		: 	Now returns prop_desc and prop_id
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
Purpose		: 	This sp returns specification infos.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intSpec_Id		integer

AS

SET NOCOUNT ON

SELECT 
	data_type_id, 
	spec_precision, 
	extended_info, 
	prop_desc,
	pp.prop_id,
	isnull(spec_desc_global, '') AS [spec_desc_global]
FROM 
	dbo.specifications s, dbo.product_properties pp 
WHERE 
	spec_id = @intSpec_Id
	AND s.prop_id = pp.prop_id

SET NOCOUNT OFF















