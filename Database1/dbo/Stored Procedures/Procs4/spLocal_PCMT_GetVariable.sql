





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetVariable]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetVariable
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtVarId		VARCHAR(4000)

AS

SET NOCOUNT ON

DECLARE
@vcrVarId			VARCHAR(4000),
@intVarId			INTEGER,
@vcrPUDesc			VARCHAR(50),
@intPUId				INTEGER,
@vcrPUGDesc			VARCHAR(50),
@intPUGId			INTEGER,
@intSGSize			INTEGER,
@intSPCDataTypeId	INTEGER,
@vcrVarDesc			VARCHAR(255)


SET @vcrVarId	= @txtVarId

SET @intVarId = (SELECT	CASE 
								WHEN CHARINDEX('[REC]',@vcrVarId,1) > 0 
								THEN CAST(SUBSTRING(@vcrVarId,1,CHARINDEX('[REC]',@vcrVarId,1)-1) AS INTEGER)
								ELSE CAST(@vcrVarId AS INTEGER) END)

SET @intSPCDataTypeId = -1
SET @intSGSize = (SELECT COUNT(var_id) FROM dbo.variables v WHERE v.pvar_id = @intVarId)
IF @intSGSize = 1 BEGIN
	SET @intSGSize = 0 END
ELSE BEGIN
	SET @vcrVarDesc = (SELECT var_desc FROM dbo.variables WHERE var_id = @intVarId)
	SET @intSPCDataTypeId = (SELECT Data_Type_Id FROM dbo.variables WHERE pvar_id = @intVarId and var_desc = @vcrVarDesc + '-01')
END

SET @vcrPUDesc = (SELECT RTRIM(LTRIM(REPLACE(REPLACE(pu.pu_desc, pl.pl_desc, ''), '  ', ' '))) 
						FROM 
							dbo.variables v 
							JOIN dbo.prod_units pu ON (v.pu_id = pu.pu_id AND v.var_id = @intVarId)
							JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id))
SET @intPUId = (	SELECT TOP 1 MIN(pu_id) 
						FROM dbo.prod_units pu LEFT JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id) 
						WHERE pu_desc LIKE '%' + @vcrPUDesc + '%'
						GROUP BY RTRIM(LTRIM(REPLACE(REPLACE(pu.pu_desc, pl.pl_desc, ''), '  ', ' ')))
						ORDER BY MIN(pu_id) ASC)

SET @vcrPUGDesc = (SELECT pug_desc FROM dbo.variables v JOIN dbo.pu_groups pug ON (v.pug_id = pug.pug_id AND v.var_id = @intVarId))
--SET @intPUGId = (SELECT MIN(pug_id) FROM dbo.pu_groups pug JOIN dbo.prod_units pu ON (pug.pu_id = pu.pu_id AND pug_desc = @vcrPUGDesc))
SET @intPUGId = (SELECT pug_id FROM dbo.variables WHERE var_id = @txtVarId)

SELECT 
	v.var_id									AS [txtVarId], 
	v.Var_Desc 								AS [txtNewVariableName], 
	v.Var_Desc 								AS [txtFromVariable], 
	v.Var_Desc 								AS [txtVariable], 
	v.Var_Desc 								AS [txtLocal], 
	v.test_name								AS [txtTestName],
	v.event_type							AS [cboEventType],
	v.event_subtype_id					AS [cboEventSubtype],
	CASE 
		WHEN v.Output_Tag IS NOT NULL 
		THEN 1
		ELSE 0
		END									AS [chkOutputTag],
	v.DS_Id 									AS [cboDataSource], 
	v.sampling_type 						AS [cboSamplingType], 
	CASE 
		WHEN v.DS_Id = 16 
		THEN 1
		ELSE 0
		END									AS [chkCalculation],
	v.calculation_Id						AS [cboCalculation],
	CASE 
		WHEN @intSPCDataTypeId = -1 
		THEN v.Data_Type_Id
		ELSE @intSPCDataTypeId
		END									AS [cboDataType],
	CASE 
		WHEN v.Var_Precision IS NULL
		THEN 0
		ELSE 	v.Var_Precision			
		END									AS [cboPrecision], 
	v.Eng_Units 							AS [cboEngUnits], 
	v.external_link 						AS [txtExternalLink], 
	CASE 
		WHEN v.event_type = 1
		THEN v.Sampling_Interval
		ELSE 0								
		END									AS [txtTestFreq],
	CASE 
		WHEN v.event_type = 1
		THEN 0
		ELSE v.Sampling_Interval		
		END									AS [cboSamplingInterval],
	v.Sampling_Offset 					AS [cboSamplingOffset], 
	CASE 
		WHEN v.Repeating = 1 
		THEN 1
		ELSE 0
		END									AS [chkRepeatingValue],
	v.Repeating								AS [chkRepeatingValue], 
	v.Repeat_Backtime						AS [txtRepeatingBackTime], 
	v.Spec_Id								AS [txtSpecId],
	pp.prop_desc + '\' + s.spec_desc	AS [txtSpecVar], 
	v.SA_Id 									AS [cboSpecAct], 
	v.Extended_Info						AS [txtEI],
	v.user_defined1						AS [txtUserDef1],
	v.user_defined2						AS [txtUserDef2],
	v.user_defined3						AS [txtUserDef3],
	@intPUId									AS [cboProductionUnit],
	@intPUGId								AS [cboProductionGroup],
	@intSGSize								AS [cboSubgroupSize]

FROM dbo.variables v
     JOIN dbo.pu_groups pug ON (pug.pug_id = v.pug_id)
     LEFT JOIN dbo.specifications s ON (s.spec_id = v.spec_id)
     LEFT JOIN dbo.product_properties pp ON (pp.prop_id = s.prop_id)
--     left join dbo.variables v2 on (v2.var_id = v.base_var_id)
WHERE 
	v.var_id = @intVarId

SET NOCOUNT OFF































