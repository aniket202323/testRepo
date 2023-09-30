
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Line_Variable_Edit]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_Line_Variable_Edit

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alberto Ledesma, Arido Software
Date created	:	20-Oct-2010
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Edit Variable
Description		: 	This sp return the specific line of the variable selected to edit

Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
*/

@intVar_id			integer


AS

SET NOCOUNT ON


SELECT pl.pl_id, pu.pu_id, pu.pu_desc, null, v.var_id, 
		  bvpl.pl_desc + '\' + bvpu.pu_desc + '\' + bvpug.pug_desc + '\' + v.var_desc_global AS base_var_desc,		  
		v.input_tag, v.output_tag, pl.pl_desc, v.dq_tag
 FROM dbo.Prod_Lines pl
	  JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
	  JOIN dbo.variables v ON (v.pu_id = pu.pu_id)
	  LEFT JOIN dbo.Pu_Groups pug ON (pug.pug_id = v.pug_id)
	  LEFT JOIN dbo.pu_groups bvpug ON (bvpug.pug_id = v.pug_id)
	  LEFT JOIN dbo.prod_units bvpu ON (bvpu.pu_id = v.pu_id)
	  LEFT JOIN dbo.prod_lines bvpl ON (bvpl.pl_id = bvpu.pl_id)     
  WHERE v.var_id = @intVar_id
		AND pl.pl_id != 0							
 

SET NOCOUNT OFF
