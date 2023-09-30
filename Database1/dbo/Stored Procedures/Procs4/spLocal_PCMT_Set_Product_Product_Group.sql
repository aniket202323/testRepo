















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Set_Product_Product_Group]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner (System Technologies for Industry Inc)
Date			:	2008-04-11
Version		:	1.1.1
Purpose		: 	Returns GroupId when type = 3 and group is created
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-11
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Update can no longer be done in Product_Grp_Desc field. This field is calculated in P4.
					Updates must be done in Product_Grp_Desc_Local in P4 and Product_Grp_Desc in P3.
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

@intType			INT,
@intUserId		INTEGER,
@intProdId		INT,
@intGroupId		INT = NULL,
@vcrGroupDesc	varchar(50) = NULL

AS
SET NOCOUNT ON

DECLARE
@AppVersion			varchar(30),	-- Used to retrieve the Proficy database Version
@FieldName			varchar(50),
@SQLCommand			NVARCHAR(2000)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

IF @AppVersion LIKE '4%'
	BEGIN
		SET @FieldName = 'Product_Grp_Desc_Local'	-- P4
	END
ELSE
	BEGIN
		SET @FieldName = 'Product_Grp_Desc'			-- P3
	END

IF @intType = 1
	BEGIN
		SELECT product_grp_id FROM dbo.Product_Group_Data WHERE Prod_Id = @intProdId
	END
ELSE
	BEGIN
		IF @intType = 2
			BEGIN
				DELETE FROM dbo.Product_Group_Data WHERE Prod_Id = @intProdId
				--EXECUTE spEM_...
			END
		ELSE
			BEGIN
				IF @intType = 3 
					BEGIN
						IF @intGroupId IS NOT NULL
							BEGIN
								--INSERT	dbo.Product_Group_Data (Prod_Id,Product_Grp_Id)
								--VALUES	(@intProdId,@intGroupId)
								EXECUTE spEM_CreateProdGroupData @intGroupId, @intProdId, @intUserId, NULL
								SELECT 	@intGroupId
							END
						ELSE
							BEGIN
								IF @vcrGroupDesc <> '' 
									BEGIN
	
--										SET @SQLCommand =	'INSERT dbo.Product_Groups (' + @FieldName + ') '
--										SET @SQLCommand = @SQLCommand + 'VALUES('
--										SET @SQLCommand = @SQLCommand + isnull('''' + @vcrGroupDesc + '''','NULL') + ')'	 -- Product_Grp_Desc(_Local)
--										EXEC sp_executesql @SQLCommand		
										
										EXECUTE spEM_CreateProdGroup @vcrGroupDesc, @intUserId, @intGroupId OUTPUT									
	
--										SELECT	@intGroupId = Product_Grp_Id
--										FROM		dbo.Product_Groups
--										WHERE		Product_Grp_Desc = @vcrGroupDesc

										--INSERT	dbo.Product_Group_Data (Prod_Id,Product_Grp_Id)
										--VALUES	(@intProdId,@intGroupId)

										EXECUTE spEM_CreateProdGroupData @intGroupId, @intProdId, @intUserId, NULL
										SELECT 	@intGroupId
									END
							END
					END
			END
	END

SET NOCOUNT OFF

















