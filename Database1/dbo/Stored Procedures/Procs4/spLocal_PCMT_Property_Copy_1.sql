
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Copy_1]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini - Arido 
Date		:	2014-08-04
Version		:	2.0
Purpose		: 	Compliant with PPA6.
				In Proficy 6 must use the fiel Product_Grp_Desc_Local in dbo.Product_Groups
				In Proficy 6 must use the fiel Char_Desc_Local in dbo.Characteristics
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-02
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Update can no longer be done in Prop_Desc and Char_Desc fields. Those fields are calculated in P4.
					Updates must be done in Prop_Desc_Local and Char_Desc_Local fields.
					Eliminated c_Char cursor. Replaced by @CharTable table variable.
					PCMT Version 5.0.3
---------------------------------------------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-05-31
Version		:	2.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Prop_Desc and Char_Desc fields. Those fields are calculated in P4.
					Updates must be done in Prop_Desc_Local and Char_Desc_Local fields.
					PCMT Version 3.0.0
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	5-Feb-2004
Version		:	1.0.0
Purpose		: 	Insert a new property and copy the char tree of the given property
					PCMT Version 2.1.0
-------------------------------------------------------------------------------------------------
TEST CODE 	:
exec spLocal_PCMT_Property_Copy_1 15, 'RZT FULL CUT EA1 050316_Z6'
-------------------------------------------------------------------------------------------------
*/
--declare
@intPropId		INT,
@vcrPropDesc	NVARCHAR(50)

AS
SET NOCOUNT ON

-- Test
--exec [dbo].[spLocal_PCMT_Property_Copy_1] 278,'Test JPG'	
--SELECT	@intPropId	= 278, @vcrPropDesc= 'Test JPG'	

DECLARE
@intNewPropId		INT,
@vcrCharDesc		NVARCHAR(50),
@intParentId		INT,
@intNewParentId		INT,
@AppVersion			NVARCHAR(30),				-- Used to retrieve the Proficy database Version
@FieldName			NVARCHAR(50),
@SQLCommand			NVARCHAR(500),
@RowNum				INT,
@NbrRows			INT

Declare @CharTable table
(
PKey						INT IDENTITY(1,1) PRIMARY Key NOT NULL,
Char_Desc				NVARCHAR(50),
Derived_From_Parent	INT
)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
SELECT @FieldName =
	CASE  
		WHEN @AppVersion LIKE '3%'	THEN 'Prop_Desc'		-- PPA3
		WHEN @AppVersion LIKE '4%'	THEN 'Prop_Desc_Local'	-- PPA4
		WHEN @AppVersion LIKE '5%'	THEN 'Prop_Desc_Local'	-- PPA5
		WHEN @AppVersion LIKE '6%'	THEN 'Prop_Desc_Local'	-- PPA6
	END

--SELECT @AppVersion AppVersion, @FieldName FieldName

-- Old
---- Description field is not the same for each Proficy version
--IF @AppVersion LIKE '4%'
--	SET @FieldName = 'Prop_Desc_Local'	-- P4
--ELSE
--	SET @FieldName = 'Prop_Desc'			-- P3

--SELECT @AppVersion AppVersion, @FieldName FieldName
--return

SET @SQLCommand = 'INSERT Product_Properties (' + @FieldName + ') VALUES (''' + @vcrPropDesc + ''')'
EXEC(@SQLCommand)

SELECT @intNewPropId = prop_id
FROM dbo.Product_Properties
WHERE prop_desc = @vcrPropDesc

-- Fill Characteristics
INSERT INTO @CharTable (Char_Desc, Derived_From_Parent)
SELECT char_desc, derived_from_parent
FROM dbo.Characteristics
WHERE prop_id = @intPropId
ORDER BY ISNULL(derived_from_parent,0)

-- Initialize variables
SET @NbrRows = (SELECT MAX(PKey) FROM @CharTable)
SET @RowNum = 1

--For each Characteristics
WHILE @RowNum <= @NbrRows
	BEGIN
		SET @intNewParentId = NULL
		SET @vcrCharDesc = (SELECT Char_Desc FROM @CharTable WHERE PKey = @RowNum)
		SET @intParentId = (SELECT Derived_From_Parent FROM @CharTable WHERE PKey = @RowNum)

		--If there is a parent char,  
    	--find the parent char in the new property
    	IF @intParentId IS NOT NULL
			BEGIN
			  SELECT @intNewParentId = char_id
			  FROM dbo.Characteristics
			  WHERE prop_id =  @intNewPropId and
			        char_desc = (SELECT char_desc

			                     FROM dbo.Characteristics
			                     WHERE char_id = @intParentId)      
			  
			  IF @intNewParentId IS NULL
			    BEGIN

					-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
					SELECT @FieldName =
						CASE  
							WHEN @AppVersion LIKE '3%'	THEN 'Char_Desc'		-- PPA3
							WHEN @AppVersion LIKE '4%'	THEN 'Char_Desc_Local'	-- PPA4
							WHEN @AppVersion LIKE '5%'	THEN 'Char_Desc_Local'	-- PPA5
							WHEN @AppVersion LIKE '6%'	THEN 'Char_Desc_Local'	-- PPA6
						END

					-- Old
					--IF @AppVersion LIKE '4%'
					--	SET @FieldName = 'Char_Desc_Local'	-- P4
					--ELSE
					--	SET @FieldName = 'Char_Desc'		-- P3
					
					SET @SQLCommand = 'INSERT dbo.Characteristics (' + @FieldName + ',Derived_From_Parent,Prop_Id) ' +
											'SELECT Char_Desc,NULL,' + convert(NVARCHAR,@intNewPropId) + ' FROM dbo.Characteristics ' +
											'WHERE char_id = ' + convert(NVARCHAR,@intParentId)
					exec sp_ExecuteSQL @SQLCommand

			      SELECT @intNewParentId = char_id
			      FROM dbo.Characteristics
			      WHERE (prop_id = @intNewPropId) AND (Char_Desc = 
																	(SELECT char_desc
																	 FROM Characteristics
																	 WHERE char_id = @intParentId))     
			    END
			END

	
		IF EXISTS(SELECT char_id FROM dbo.Characteristics WHERE (prop_id = @intNewPropId) and (char_desc = @vcrCharDesc))
			BEGIN
				-- If the new char exists, only update the parent
      		UPDATE dbo.Characteristics
      	 	SET derived_from_parent = @intNewParentId 
      		WHERE prop_id = @intNewPropId and
          	char_desc = @vcrCharDesc
			END
		ELSE
			BEGIN
				-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
				SELECT @FieldName =
					CASE  
						WHEN @AppVersion LIKE '4%'	THEN 'Char_Desc_Local'	-- PPA4
						WHEN @AppVersion LIKE '3%'	THEN 'Char_Desc'		-- PPA3
						WHEN @AppVersion LIKE '5%'	THEN 'Char_Desc_Local'	-- PPA5
						WHEN @AppVersion LIKE '6%'	THEN 'Char_Desc_Local'	-- PPA6
					END

				-- Old
				--IF @AppVersion LIKE '4%'
				--	SET @FieldName = 'Char_Desc_Local'
				--ELSE
				--	SET @FieldName = 'Char_Desc'
				
				--Add the new char with its parent 
				SET @SQLCommand =
				'INSERT dbo.Characteristics
				(' + 
				@FieldName + ',
				Derived_From_Parent,
				Prop_Id
				)
				VALUES
				(''' + 
				@vcrCharDesc + ''',' +
				convert(NVARCHAR,@intNewParentId) + ',' +
				convert(NVARCHAR,@intNewPropId) + '
				)'
				
				exec sp_ExecuteSQL @SQLCommand
			END

		SET @RowNum = @RowNum + 1
	END

SET NOCOUNT OFF
