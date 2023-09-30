
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Delete_2]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini - Arido 
Date		:	2014-08-04
Version		:	2.0
Purpose		: 	Compliant with PPA6.
				In dbo.Var_Specs the old index Var_Specs_By_AS_Id doesn't exist
-------------------------------------------------------------------------------------------------
Modified by	:	Marc Charest, Solutions et Technologies Industrielles Inc.
On			:	2009-01-12
Version		:	1.1.0
Purpose 		: 	Added an additional UPDATE statement to make sure all links between Active_Specs
					and Var_Specs tables are broken. This fix prevents to have SQL error 
					(constraint violation) while running subsequent spLocal_PCMT_Property_Delete_4
					The fix addresses problem tickets 58563 & 58247.
-------------------------------------------------------------------------------------------------
Modified by	:	Alexandre Turgeon, Solutions et Technologies Industrielles Inc.
On			:	4-Aug-2006
Version		:	1.0.1
Purpose 	: 	Improved performance by using a join on variables and specifications to use 
				var_spec index on var_id and as_id
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date		:	2005-11-02
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
				Added [dbo] template when referencing objects.
				Added registration of SP Version into AppVersions table.
				PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On			:	5-Feb-2004
Version		:	1.0.0
Purpose 	: 	Close var_specs for a given property
				PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/
--DECLARE
@intPropId	integer

AS
SET NOCOUNT ON

-- TEST
--exec [dbo].[spLocal_PCMT_Property_Delete_2] 282
--SELECT @intPropId = 282

--Close var_specs		(Marc Charest 2009-01-12)
UPDATE 
	dbo.Var_Specs
SET 
	Expiration_Date = ISNULL(Expiration_Date, GETDATE()), 
	AS_Id = NULL
FROM 
	dbo.var_specs vs
	JOIN dbo.variables		v ON v.var_id = vs.var_id
	JOIN dbo.specifications s ON s.spec_id = v.spec_id
WHERE 
	vs.as_id IS NOT NULL 
	AND s.prop_id = @intPropId

--Close var_specs
UPDATE 
	dbo.Var_Specs
SET
	Expiration_Date = ISNULL(VS.Expiration_Date, GETDATE()),
	AS_Id = NULL
FROM 
	-- Old
	--dbo.Var_Specs			VS	WITH(INDEX(Var_Specs_By_AS_Id)) 
	dbo.Var_Specs			VS	
	JOIN dbo.Active_Specs	A	ON (A.AS_Id = VS.AS_Id)
	JOIN dbo.Specifications S	ON (S.Spec_Id = A.Spec_Id)
WHERE
	S.Prop_Id = @intPropId

   
SET NOCOUNT OFF
