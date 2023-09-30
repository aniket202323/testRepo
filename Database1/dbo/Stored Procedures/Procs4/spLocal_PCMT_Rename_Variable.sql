
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE	PROCEDURE [dbo].[spLocal_PCMT_Rename_Variable]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 2.1 (PPA 6)
-------------------------------------------------------------------------------------------------
Updated By  : Juan Pablo Galanzini - Arido Software
Date        : 2015-01-16
Version     : 2.1
Description	: This SP is used to rename one variable
Editor tab spacing: 4
-------------------------------------------------------------------------------------------------
*/
--declare
@intVarId			INTEGER,
@vcrVarDesc			NVARCHAR(50)
AS

-- TEST: 
--SELECT @intVarId = 10000, @vcrVarDesc = 'NW Acquisition Layer Orientierung'
--	EXEC [dbo].[spLocal_PCMT_Rename_Variable] @intVarId = 10000, @vcrVarDesc = 'NW Acquisition Layer Orientierung'
--	EXEC [dbo].[spLocal_PCMT_Rename_Variable] @intVarId = 10000, @vcrVarDesc = 'NW Acquisition Layer Orientierung NEW'

DECLARE	@intPuId	INTEGER,
		@intUpdate	INTEGER

SET NOCOUNT ON

SET @vcrVarDesc = LTRIM(RTRIM(@vcrVarDesc))
SET @intUpdate = 0
--SELECT Var_Id, Var_Desc,Var_Desc_Global FROM dbo.Variables_Base WHERE Var_Id = @intVarId

-------------------------------------------------------------------------------------------------
-- Search Unit
-------------------------------------------------------------------------------------------------
SELECT @intPuId = v.PU_Id
	FROM dbo.Variables_Base v
	WHERE Var_Id = @intVarId	

-------------------------------------------------------------------------------------------------
-- Check data invalid
-------------------------------------------------------------------------------------------------
IF (ISNULL(@intVarId,0) <> 0 AND LEN(@vcrVarDesc) > 0)
BEGIN
	-------------------------------------------------------------------------------------------------
	-- Check if doesn't exist other variable with the same description
	-------------------------------------------------------------------------------------------------
	IF (NOT EXISTS(
		SELECT * FROM dbo.Variables_Base
			WHERE Var_Id <> @intVarId	
				AND pu_id = @intPuId
				AND (Var_Desc = @vcrVarDesc
					OR Var_Desc_Global = @vcrVarDesc)))
	BEGIN
		-------------------------------------------------------------------------------------------------
		-- Update Property_Equipment_EquipmentClass
		-------------------------------------------------------------------------------------------------
		UPDATE b
			SET b.Name = @vcrVarDesc
			FROM dbo.Variables_Base							a
			JOIN dbo.Variables_Aspect_EquipmentProperty		e	ON e.Var_Id = a.Var_Id 
			JOIN dbo.Property_Equipment_EquipmentClass		b	ON b.EquipmentId = e.Origin1EquipmentId 
																AND b.Name = e.Origin1Name
			WHERE a.Var_Id = @intVarId

		-------------------------------------------------------------------------------------------------
		-- Update Variable_Base
		-------------------------------------------------------------------------------------------------
		UPDATE dbo.Variables_Base 
			SET Var_Desc = @vcrVarDesc
			WHERE Var_Id = @intVarId

		--UPDATE dbo.Variables_Base 
		--	SET Var_Desc_Global = @vcrVarDesc
		--	WHERE Var_Id = @intVarId

		SET @intUpdate = 1

		--SELECT Var_Id, Var_Desc, Var_Desc_Global FROM dbo.Variables_Base WHERE Var_Id = @intVarId
	END
END

-------------------------------------------------------------------------------------------------
-- Output
-------------------------------------------------------------------------------------------------
SELECT @intUpdate AS wasUpdated, Var_Id, Var_Desc, Var_Desc_local, Var_Desc_Global 
	FROM dbo.Variables 
	WHERE Var_Id = @intVarId


SET NOCOUNT OFF
