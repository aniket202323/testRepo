







----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Display_Template_Variable_Testing]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure		:	spLocal_PCMT_Get_Display_Template_Variable
Author					:	Rick Perreault (System Technologies for Industry Inc)
Date Created			:	15-Apr-2004
SP Type					:						
Called By				:	PCMT
Editor Tab Spacing	:	3
Version					:	1.0.0

Description:
===========
This sp return the display or template variables.
1=Alarm Template
2=Alarm Display	
3=Autolog Display


CALLED BY				:  PCMT


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1.0				31-Oct-2005		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		Use with PCMT Version 4.0.0 and higher.

1.1.1				23-Aug-2006		Normand Carbonneau		Added DISTINCT while retrieving variables in a template because
																		each variable will have several rows in Alarm_Template_Var_Data
																		in Proficy 4.
																		This won't affect Proficy 3.

1.1.2				2008-07-31		Stephane Turner, STI		Made sure no NULL is returned

*/

@SearchType		INT, 
@keyid			INT

AS
SET NOCOUNT ON

DECLARE @tmp TABLE(
	[id] 		INT IDENTITY, 
	var_desc VARCHAR(50), 
	pl_desc 	VARCHAR(50), 
	pu_desc 	VARCHAR(50), 
	pug_desc VARCHAR(50),
	var_id	INT)

IF @SearchType = 1
BEGIN
	--get the alarm template list
	INSERT INTO @tmp(var_desc, pl_desc, pu_desc, pug_desc, var_id)
	SELECT	DISTINCT	v.var_desc, pl.pl_desc, pu.pu_desc, pug.pug_desc, v.var_id
	FROM		dbo.alarm_template_var_data atvd JOIN 
				dbo.variables v ON atvd.var_id = v.var_id JOIN 
				dbo.pu_groups pug ON v.pug_id = pug.pug_id JOIN	
				dbo.prod_units pu ON v.pu_id = pu.pu_id JOIN 
				dbo.prod_lines pl ON pu.pl_id = pl.pl_id
	WHERE		atvd.at_id = @keyid
	ORDER BY v.var_desc
END
ELSE IF @searchtype = 2
BEGIN
	--get the alarm display  list
	INSERT INTO @tmp(var_desc, pl_desc, pu_desc, pug_desc, var_id)
	SELECT	v.var_desc, pl.pl_desc, pu.pu_desc, pug.pug_desc, v.var_id
	FROM		dbo.sheet_variables sv JOIN 
				dbo.variables v ON sv.var_id = v.var_id JOIN 
				dbo.pu_groups pug ON v.pug_id = pug.pug_id JOIN	
				dbo.prod_units pu ON v.pu_id = pu.pu_id JOIN	
				dbo.prod_lines pl ON pu.pl_id = pl.pl_id
	WHERE		sv.sheet_id = @keyid
	ORDER BY v.var_desc
END
ELSE IF @searchtype = 3
BEGIN
	--get the alarm display list
	INSERT INTO @tmp(var_desc, pl_desc, pu_desc, pug_desc, var_id)
	SELECT	var_desc = CASE WHEN sv.var_id IS NULL THEN sv.title
						ELSE v.var_desc END, 
				pl.pl_desc, 
				pu.pu_desc, 
				pug.pug_desc,
				CASE WHEN v.var_id IS NULL THEN sv.var_order ELSE v.var_id END
	FROM		dbo.sheet_variables sv LEFT JOIN
				dbo.variables v ON sv.var_id = v.var_id LEFT JOIN
				dbo.pu_groups pug ON v.pug_id = pug.pug_id LEFT JOIN
				dbo.prod_units pu ON v.pu_id = pu.pu_id LEFT JOIN
				dbo.prod_lines pl ON pu.pl_id = pl.pl_id
	WHERE		sv.sheet_id = @keyid
	ORDER BY	sv.var_order
END

SELECT 	ISNULL(var_desc, ''), 
			ISNULL(pl_desc, ''), 
			ISNULL(pu_desc, ''), 
			ISNULL(pug_desc, ''),
			ISNULL(var_id, '')
FROM 		@tmp
ORDER BY [id]

SET NOCOUNT OFF











