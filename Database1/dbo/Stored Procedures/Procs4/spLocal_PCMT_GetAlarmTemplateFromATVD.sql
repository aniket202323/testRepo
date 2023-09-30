








CREATE PROCEDURE [dbo].[spLocal_PCMT_GetAlarmTemplateFromATVD]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetAlarmTemplateFromATVD
Author:					Marc Charest (STI)
Date Created:			2009-05-04
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
@Var_Desc		INTEGER,
@PU_Desc			VARCHAR(255),
@PL_Desc			VARCHAR(255)

AS

SET NOCOUNT ON


SELECT TOP 1 AT_Desc 
FROM 
	dbo.Variables V
	JOIN dbo.Prod_Units PU ON (V.PU_Id = PU.PU_Id)
	JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
	JOIN dbo.Alarm_Template_Var_Data ATVD ON (ATVD.Var_Id = V.Var_Id)
	JOIN dbo.Alarm_Templates ALT ON (ALT.AT_Id = ATVD.AT_Id)
WHERE
	Var_Desc = @Var_Desc
	AND PU_Desc = @PU_Desc
	AND PL_Desc = @PL_Desc 


SET NOCOUNT OFF













