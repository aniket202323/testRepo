











CREATE PROCEDURE [dbo].[spLocal_PCMT_GetTemplateDisplayData]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetTemplateDisplayData
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
@Var_Desc		VARCHAR(255),
@Item_Desc		VARCHAR(510),
@Type				INTEGER=1			--1=alarm template, 2=alarm display, 3=autolog display

AS

SET NOCOUNT ON

DECLARE
@PU_Desc			VARCHAR(255),
@PL_Desc			VARCHAR(255)

SET @PU_Desc = RIGHT(@Item_Desc, LEN(@Item_Desc) - CHARINDEX('/', @Item_Desc)) 
SET @PL_Desc = LEFT(@Item_Desc, CHARINDEX('/', @Item_Desc) - 1)

IF @Type = 1 BEGIN
	SELECT TOP 1 ALT.AT_Id AS [ID], AT_Desc AS [Description], 0 AS [ORDER] 
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
END

IF @Type = 2 BEGIN
	SELECT TOP 1 S.Sheet_Id AS [ID], Sheet_Desc AS [Description], Var_Order AS [ORDER] 
	FROM 
		dbo.Variables V
		JOIN dbo.Prod_Units PU ON (V.PU_Id = PU.PU_Id)
		JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
		JOIN dbo.Sheet_Variables SV ON (SV.Var_Id = V.Var_Id)
		JOIN dbo.Sheets S ON (S.Sheet_Id = SV.Sheet_Id)
	WHERE
		Var_Desc = @Var_Desc
		AND PU_Desc = @PU_Desc
		AND PL_Desc = @PL_Desc
		AND S.Sheet_Type = 11
END

IF @Type = 3 BEGIN
	SELECT TOP 1 S.Sheet_Id AS [ID], Sheet_Desc AS [Description], Var_Order AS [ORDER] 
	FROM 
		dbo.Variables V
		JOIN dbo.Prod_Units PU ON (V.PU_Id = PU.PU_Id)
		JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
		JOIN dbo.Sheet_Variables SV ON (SV.Var_Id = V.Var_Id)
		JOIN dbo.Sheets S ON (S.Sheet_Id = SV.Sheet_Id)
	WHERE
		Var_Desc = @Var_Desc
		AND PU_Desc = @PU_Desc
		AND PL_Desc = @PL_Desc 
		AND S.Sheet_Type <> 11
END

SET NOCOUNT OFF











