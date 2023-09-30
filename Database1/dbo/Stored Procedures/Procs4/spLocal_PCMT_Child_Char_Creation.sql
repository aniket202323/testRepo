










-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Child_Char_Creation]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-12-29
Version		:	1.2.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Update can no longer be done in Char_Desc field. This field is calculated in P4.
					Updates must be done in Char_Desc_Local field in P4 and Char_Desc in P3.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified By	:	Ugo Lapierre, Solutions et Technologies Industrielles Inc.
On				:	31-Jul-03	
Version		:	1.1.0
Purpose		: 	When a child characteristics get its spec from a parent, the field is_defined
					should be null until some spec has been overide.  So I remove the field
					is_defined from the insertion into active spec when we copy specs from parent
-------------------------------------------------------------------------------------------------
Created By	:	Clement Morin, Solutions et Technologies Industrielles Inc.
On				:	24 JUL 03
Version		:	1.0.0
Purpose		:	This SP create a characteristic that have parent Characteristics.
					Create the characteristic into table "characteristics", bring all the
					information defined into the parent char. to the new char. in table
					"Active_specs"
-------------------------------------------------------------------------------------------------
*/

@CharPID			INT,	
@property_id 	INT,
@Char_desc		varchar(50)	

AS
SET NOCOUNT ON

Declare
@CharCID			INTEGER,
@AppVersion		VARCHAR(30),		-- Used to retrieve the Proficy database Version
@FieldName		VARCHAR(50),
@SQLCommand		NVARCHAR(2000)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

-- Description field is not the same for each Proficy version
IF @AppVersion LIKE '4%'
	SET @FieldName = 'Char_Desc_Local'	-- P4
ELSE
	SET @FieldName = 'Char_Desc'			-- P3

-- Create dynamic SQL to be able to refer to correct field for P3 and P4
SET @SQLCommand =	'INSERT dbo.Characteristics (Derived_From_Parent,Prop_Id,' + @FieldName + ') '
SET @SQLCommand = @SQLCommand + 'VALUES('
SET @SQLCommand = @SQLCommand + isnull(convert(NVARCHAR,@CharPID),'NULL') + ','			-- Derived_From_Parent
SET @SQLCommand = @SQLCommand + isnull(convert(NVARCHAR,@property_id),'NULL') + ','		-- Prop_Id
SET @SQLCommand = @SQLCommand + isnull('''' + @Char_desc + '''','NULL') + ')'				-- Char_Desc(_Local)

-- Characteristic Creation
EXEC sp_executesql @SQLCommand

-- Get the New Char_id
SET @CharCID = (SELECT Char_Id FROM dbo.Characteristics WHERE (Char_Desc = @Char_desc) AND (Prop_Id = @property_id))

-- Insert in the child characteristic
INSERT INTO	dbo.Active_Specs
				(
				Effective_Date, Expiration_Date, Test_Freq, Defined_By, Spec_Id, Deviation_From, Char_Id, Comment_Id,
				Is_OverRidable, Is_Deviation, Is_L_Rejectable, Is_U_Rejectable, L_Warning, L_Reject, L_Entry, U_User,
				Target, L_User, U_Entry, U_Reject, U_Warning
				)
	SELECT	getdate() AS Effective_Date, NULL AS Expiration_Date, Test_Freq, Defined_By, Spec_Id, Deviation_From,
				@CharCID, Comment_Id, Is_OverRidable, Is_Deviation, Is_L_Rejectable, Is_U_Rejectable, L_Warning,
				L_Reject, L_Entry, U_User, Target, L_User, U_Entry, U_Reject, U_Warning
	FROM		dbo.Active_Specs
	WHERE		(Char_Id = @CharPID) AND (Expiration_Date IS NULL)

SELECT @CharCID

SET NOCOUNT OFF












