














----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Add_Template_Variable]

/*
-------------------------------------------------------------------------------------------------
Stored Procedure		:	spLocal_PCMT_Add_Template_Variable
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
@PL_Id		INT,
@Var_Desc	varchar(50)

AS
SET NOCOUNT ON

DECLARE
@Var_Id			INT,
@AppVersion		varchar(30),		-- Used to retrieve the Proficy database Version
@SQLCommand		NVARCHAR(2000)

SET @Var_Id =	(
					SELECT	v.var_id
					FROM		dbo.Variables v
					JOIN		dbo.Prod_Units pu ON pu.PU_Id = v.PU_Id
					WHERE		v.Var_Desc = @Var_Desc
					AND		pu.PL_Id = @PL_Id
					)

IF @Var_Id IS NOT NULL
	BEGIN
		-- Get the Proficy Database Version
		SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

		-- Delete any existing reference of this variable into the Alarm Template
		DELETE FROM dbo.Alarm_Template_Var_Data WHERE (Var_Id = @Var_Id) AND (AT_Id = @AT_Id)
		
		-- Insert one row with a NULL reference to ATVRD_Id (Like Proficy Admin)
		INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id) VALUES(@AT_Id, @Var_Id)
		
		-- Execute this section for Proficy 4 only.
		IF @AppVersion LIKE '4%'
			BEGIN
				-- Create dynamic SQL because Alarm_Template_Variable_Rule_Data does not exists in P3
				SET @SQLCommand =	'INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id, ATVRD_Id)'
				SET @SQLCommand = @SQLCommand + ' SELECT '
				SET @SQLCommand = @SQLCommand + isnull(convert(NVARCHAR,@AT_Id),'NULL') + ','
				SET @SQLCommand = @SQLCommand + isnull(convert(NVARCHAR,@Var_Id),'NULL') + ', ATVRD_Id'
				SET @SQLCommand =	@SQLCommand + ' FROM	dbo.Alarm_Template_Variable_Rule_Data atvrd'
				SET @SQLCommand =	@SQLCommand + ' WHERE atvrd.AT_Id = '
				SET @SQLCommand = @SQLCommand + isnull(convert(NVARCHAR,@AT_Id),'NULL')

				EXEC sp_executesql @SQLCommand
			END
	END

SET NOCOUNT OFF















