






-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Variable]
/*
-------------------------------------------------------------------------------------------------
											
-------------------------------------------------------------------------------------------------
Author			:	Rick Perreault, Solutions et Technologies Industrielles Inc.
Date created	:	12-Nov-02	
Version			:	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		:	This sp return the variable informations
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
Updated By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	1-Mar-04
Version		:	1.0.1
Purpose		:	Return the external_link
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-06-09
Version		:	2.0.0
Purpose		: 	Now also returns var_desc_global
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2007-10-06
Version		:	2.0.1
Purpose		: 	Return the event subtype of the event configuration if the variable is Production 
					Event and the subtype null
-------------------------------------------------------------------------------------------------
Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-22
Version		:	1.1.0  => Compatible with PCMT version 1.7 and higher
Purpose		: 	Modified the final result set
					This has been done to be able to add and edit child variables without SPC calculation.
					1- Modified the child count of section the spc calculation managemenent
						--> Added by PDD
						IF EXISTS(SELECT Calculation_Id FROM dbo.variables WHERE pvar_id = @intVar_id AND Calculation_Id IS NULL)
							BEGIN
								SET @intSPCDataTypeId = -1
							END
					2- Modified the the result set 
						CASE --> Added by PDD
								WHEN @intSPCDataTypeId = -1 
								THEN -1
								ELSE v.spc_calculation_type_id END AS spc_calculation_type_id,
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-05-08
Version		:	1.1.1
Purpose		: 	Fix for the previous version. Remove some code from PDD.
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-05-11
Version		:	1.1.2
Purpose		: 	Add code at the top of SP to make sure PCMT plays with a variable that have both 
					local and global description.
-------------------------------------------------------------------------------------------------

*/

@intVar_id	integer

AS

SET NOCOUNT ON

DECLARE
@intChildCount		INTEGER,
@intChildDSId		INTEGER,
@intSPCDataTypeId	INTEGER,
@vcrVarDesc			VARCHAR(255)


--Making sure we get a variable with a global description
UPDATE dbo.Variables 
	SET Var_Desc_Global = Var_Desc_Local
	WHERE Var_Desc_Global IS NULL
	AND (Var_Id = @intVar_id OR PVar_Id = @intVar_id)


SET @intChildCount = (SELECT COUNT(var_id) FROM dbo.variables WHERE pvar_id = @intVar_id AND var_id IS NOT NULL AND ds_id <> 16)
IF @intChildCount > 0 BEGIN
	SET @intChildDSId = (SELECT TOP 1 ds_id FROM dbo.variables WHERE pvar_id = @intVar_id AND var_id IS NOT NULL AND ds_id <> 16)
END


SET @intSPCDataTypeId = -1
IF @intChildCount > 0 BEGIN

	SET @vcrVarDesc = (SELECT var_desc FROM dbo.variables WHERE var_id = @intVar_id)
	SET @intSPCDataTypeId = (SELECT Data_Type_Id FROM dbo.variables WHERE pvar_id = @intVar_id and var_desc = @vcrVarDesc + '-01')

/*
	--> Added by PDD
	IF EXISTS(SELECT Calculation_Id FROM dbo.variables WHERE pvar_id = @intVar_id AND Calculation_Id IS NULL)
		BEGIN
			SET @intSPCDataTypeId = -1
		END
*/

END


SELECT v.var_id, v.Repeat_Backtime, 
	    CASE 
				WHEN @intSPCDataTypeId = -1 
				THEN v.Data_Type_Id
				ELSE @intSPCDataTypeId END	AS [Data_Type_Id],
		 CASE
		 		WHEN spc_calculation_type_id IS NOT NULL
				THEN @intChildDSId
				ELSE v.DS_Id END AS [DS_Id], 

		 v.Spec_Id,

		 CASE 
		 		WHEN master.pu_id IS NULL 
				THEN RTRIM(LTRIM(REPLACE(REPLACE(pu.pu_desc, pl.pl_desc, ''), '  ', ' '))) 
				ELSE RTRIM(LTRIM(REPLACE(REPLACE(master.pu_desc, pl.pl_desc, ''), '  ', ' '))) END  AS [pu_desc],

		 CASE 
		 		WHEN master.pu_id IS NULL 
				THEN NULL 
				ELSE RTRIM(LTRIM(REPLACE(REPLACE(pu.pu_desc, pl.pl_desc, ''), '  ', ' '))) END  AS [slave_desc],
		  
		 v.PUG_Id, v.Sampling_Interval,
       v.Sampling_Offset, v.Repeating, v.Repeat_Backtime, v.SA_Id, v.Event_Type, v.Var_Precision, v.Var_Desc_Global, 
       v.Eng_Units, v.Output_Tag, 
		 v.DQ_Tag,
		 v.Comparison_Operator_Id,
		 v.Comparison_Value,
		 v.Extended_Info, v.spec_id, pp.prop_desc + '\' + s.spec_desc AS spec_desc, 
       pug.pug_desc, v.sampling_type, v.calculation_id, v.external_link, 
		 CASE WHEN v.event_type = 1 THEN COALESCE(v.event_subtype_id, c.event_subtype_id) ELSE v.event_subtype_id END AS event_subtype, 
		 v.var_desc_local, v.test_name, v.User_Defined1, v.User_Defined2, v.User_Defined3, v.extended_info, @intChildCount AS [SG_Size],
		 
		 CASE WHEN v.spc_calculation_type_id IS NULL THEN -1 ELSE v.spc_calculation_type_id END AS [spc_calculation_type_id],

/*
		 CASE --> Added by PDD
				WHEN @intSPCDataTypeId = -1 AND  @intChildCount > 0
				THEN -1
				ELSE v.spc_calculation_type_id END AS spc_calculation_type_id,
*/

		 cid.default_value,
		 v.Force_Sign_Entry

FROM dbo.variables v
     JOIN dbo.pu_groups pug ON (pug.pug_id = v.pug_id)
     LEFT JOIN dbo.specifications s ON (s.spec_id = v.spec_id)
     LEFT JOIN dbo.product_properties pp ON (pp.prop_id = s.prop_id)
	  JOIN dbo.prod_units pu ON pu.pu_id = v.pu_id
	  LEFT JOIN dbo.prod_units master ON (pu.master_unit = master.pu_id)
	  JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id)
	  LEFT JOIN dbo.calculation_input_data cid ON (v.var_id = cid.result_var_id AND calc_input_id = 25) 
	  LEFT JOIN dbo.event_configuration c ON pu.pu_id = c.pu_id AND c.et_id = 1

--     left join dbo.variables v2 on (v2.var_id = v.base_var_id)
WHERE v.var_id = @intVar_id

SET NOCOUNT OFF







