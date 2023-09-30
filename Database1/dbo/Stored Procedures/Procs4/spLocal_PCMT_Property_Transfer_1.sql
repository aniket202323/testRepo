













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Transfer_1]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 5.0.0 (P3 and P4)
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_Property_Transfer_1
Author:					Rick Perreault(STI)
Date Created:			05-Feb-04
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
Attach product to characteistics of the new property for the unit of the given production groups.
PCMT Version 2.1.0 and 3.0.0

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who								What
========	===========	==========================	===============================================================
1.2.0		23-May-06	Marc Charest (STI)			RTT groups are now split across multiple units.
																We revisited the SP to take care of these changes.
1.1.1		11-May-06	Eric Perron (STI)				Delete rows from pu_characteristics before inserting 
																for avoiding constraint failure.
1.1.0		03-Nov-05	Normand Carbonneau (STI)	Compliant with Proficy 3 and 4.
																Added [dbo] template when referencing objects.
																Added registration of SP Version into AppVersions table.
																Eliminated c_Char cursor and replaced by @Char_Table 
																table variable.
																PCMT Version 5.0.3
*/
@intPropId		integer,
@intPugId		integer

AS

SET NOCOUNT ON

DECLARE
@vcrCharDesc	varchar(50),
@intPuId			integer,
@intProdId		integer,
@intCharId		integer,
@RowNum			integer,
@NbrRows			integer

DECLARE @Char_Table TABLE
( 
PKey			integer IDENTITY(1,1) PRIMARY KEY NOT NULL,
PU_Id			integer,
Prod_Id		integer,
Char_Desc	varchar(50)
)

-- Fill Characteristics informations
INSERT @Char_Table (PU_Id,Prod_Id,Char_Desc)
	SELECT DISTINCT puc.pu_id, puc.prod_id, c.char_desc
	FROM dbo.Variables v
	    JOIN dbo.Specifications s ON s.spec_id = v.spec_id
		 JOIN dbo.Prod_Units pu ON v.pu_id = pu.pu_id
	    JOIN dbo.PU_Characteristics puc ON puc.pu_id = ISNULL(pu.master_unit, pu.pu_id) AND
	                                       puc.prop_id = s.prop_id
	    JOIN dbo.Characteristics c ON c.char_id = puc.char_id
	WHERE v.pug_id = @intPugId


-- Initialize loop variables
SET @NbrRows = (SELECT MAX(PKey) FROM @Char_Table WHERE PKey IS NOT NULL)
SET @RowNum = 1

-- For each links in a pug
WHILE @RowNum <= @NbrRows
	BEGIN
		SET @intCharId = NULL
		SET @intPuId = NULL
		SET @intProdId = NULL
		SET @vcrCharDesc = NULL

		-- Fetching values
		SELECT @intPuId = PU_Id, @intProdId = Prod_Id, @vcrCharDesc = Char_Desc
		FROM @Char_Table WHERE PKey = @RowNum
		
		SELECT @intCharId = char_id
		FROM dbo.Characteristics
		WHERE prop_id = @intPropId AND
		    char_desc = @vcrCharDesc
		
		IF @intCharId IS NOT NULL
			BEGIN
			--If the char exist in the new property
			IF EXISTS(SELECT prop_id
			              FROM dbo.Pu_Characteristics
			              WHERE pu_id = @intPuId AND prod_id = @intProdId AND
			                    prop_id = @intPropId)
				BEGIN
					DELETE FROM dbo.Pu_Characteristics 
						WHERE 	pu_id = @intPuId AND 
									prod_id = @intProdId AND
			                  prop_id = @intPropId
				END

				--If the links is not there, add it
				INSERT dbo.Pu_Characteristics(pu_id, prod_id, prop_id, char_id)
				VALUES(@intPuId, @intProdId, @intPropId, @intCharId)
			END
		
		SET @RowNum = @RowNum + 1
	END

SET NOCOUNT OFF















