
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Set_Product_Group]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini - Arido 
Date		:	2014-08-04
Version		:	2.0
Purpose		: 	Compliant with PPA6.
				IN Proficy 6 must use the fiel Product_Grp_Desc_Local in dbo.Product_Groups
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-11
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Update can no longer be done in Product_Grp_Desc field. This field is calculated in P4.
					Updates must be done in Product_Grp_Desc_Local in P3 and Product_Grp_Desc in P3.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of properties for a given unit name
-------------------------------------------------------------------------------------------------
*/
--declare
@intType		INT,
@intGroupId		INT,
@vcrGroupDesc	NVARCHAR(50) = NULL

AS
SET NOCOUNT ON

-- Test
--	EXEC [dbo].[spLocal_PCMT_Set_Product_Group] 2, 80, 'test_pcmt JPG'
--select	@intType		= 2, 
--		@intGroupId		= 80, 
--		@vcrGroupDesc	= 'test_pcmt JPG'


DECLARE
@AppVersion			NVARCHAR(30),	-- Used to retrieve the Proficy database Version
@FieldName			NVARCHAR(50),
@SQLCommand			NVARCHAR(2000)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
SELECT @FieldName =
	CASE  
		WHEN @AppVersion LIKE '3%'	THEN 'Product_Grp_Desc'			-- PPA3
		WHEN @AppVersion LIKE '4%'	THEN 'Product_Grp_Desc_Local'	-- PPA4
		WHEN @AppVersion LIKE '5%'	THEN 'Product_Grp_Desc_Local'	-- PPA5
		WHEN @AppVersion LIKE '6%'	THEN 'Product_Grp_Desc_Local'	-- PPA6
	END

--SELECT @AppVersion AppVersion, @FieldName FieldName

-- Old
--IF @AppVersion LIKE '4%'
--	BEGIN
--		SET @FieldName = 'Product_Grp_Desc_Local'	-- P4
--	END
--ELSE
--	BEGIN
--		SET @FieldName = 'Product_Grp_Desc'			-- P3
--	END
	
IF @intType = 1
	BEGIN
		SET @SQLCommand =	'INSERT dbo.Product_Groups (' + @FieldName + ') '
		SET @SQLCommand = @SQLCommand + 'VALUES('
		SET @SQLCommand = @SQLCommand + ISNULL('''' + @vcrGroupDesc + '''','NULL') + ')'	 -- Product_Grp_Desc(_Local)

		EXEC sp_executesql @SQLCommand								
	END
ELSE
  	IF @intType = 2
  		BEGIN
  			SET @SQLCommand =	'UPDATE dbo.Product_Groups '
			SET @SQLCommand = @SQLCommand + 'SET ' + @FieldName + ' = ' + ISNULL('''' + @vcrGroupDesc + '''','NULL') + ' '
			SET @SQLCommand = @SQLCommand + 'WHERE Product_Grp_Id = ' + CONVERT(NVARCHAR,@intGroupId)

			EXEC sp_executesql @SQLCommand
  		END
  	ELSE
    	IF @intType = 3
      	BEGIN
        		DELETE FROM dbo.Product_Group_Data WHERE product_grp_id = @intGroupId
     
        		DELETE FROM dbo.Product_Groups WHERE product_grp_Id = @intGroupId
      	END


SET NOCOUNT OFF
