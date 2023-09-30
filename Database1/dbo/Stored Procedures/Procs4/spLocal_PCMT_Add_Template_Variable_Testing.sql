




----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Add_Template_Variable_Testing]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure		:	spLocal_PCMT_Add_Template_Variable_Testing
Author					:	Rick Perreault (System Technologies for Industry Inc)
Date Created			:	15-Apr-2004
SP Type					:						
Called By				:	PCMT
Editor Tab Spacing	:	3
Version					:	1.0.0

Description:
===========
This sp add a variable to an alarm display.


CALLED BY				:  PCMT


Revision 		Date				Who							What
========			===========		==================		=================================================================================
1.1.0				31-Oct-2005		Normand Carbonneau		Compliant with Proficy 3 and 4.
																		Added [dbo] template when referencing objects.
																		Added registration of SP Version into AppVersions table.
																		Use with PCMT Version 4.0.0 and higher.
					
1.1.1				23-Aug-2006		Normand Carbonneau		Added code for new Alarm_Template_Variable_Rule_Data and Alarm_Variable_Rules
																		Proficy 4 tables.
																		Also, now delete existing reference to a variable in the Alarm Template
																		before adding it. This avoids duplicates in Alarm_Template_Var_Data table.



*/

@AT_Id		INT,
@VarDesc		VARCHAR(255),
@PLDesc		VARCHAR(255),
@PUDesc		VARCHAR(255)

AS

SET NOCOUNT ON

DECLARE
@Var_Id		INT

SET @Var_Id = (	SELECT Var_Id
						FROM 
							dbo.Variables V
							LEFT JOIN dbo.Prod_Units PU ON (PU.PU_Id = V.PU_Id)
							LEFT JOIN dbo.Prod_Lines PL ON (PL.PL_Id = PU.PL_Id)
						WHERE 
							V.Var_Desc = @VarDesc
							AND PU.PU_Desc = @PUDesc
							AND PL.PL_Desc = @PLDesc)

--Delete any existing reference of this variable into the Alarm Template
DELETE FROM dbo.Alarm_Template_Var_Data WHERE (Var_Id = @Var_Id) AND (AT_Id = @AT_Id)
		
--Insert one row with a NULL reference to ATVRD_Id (Like Proficy Admin)
INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id) VALUES(@AT_Id, @Var_Id)
		
INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id, ATVRD_Id)
SELECT
	@AT_Id ,@Var_Id, ATVRD_Id
FROM	dbo.Alarm_Template_Variable_Rule_Data atvrd
WHERE 
	atvrd.AT_Id = @AT_Id

SET NOCOUNT OFF





