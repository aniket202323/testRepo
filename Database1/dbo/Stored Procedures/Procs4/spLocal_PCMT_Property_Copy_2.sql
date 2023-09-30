
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Copy_2]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini - Arido 
Date		:	2014-08-04
Version		:	2.0
Purpose		: 	Compliant with PPA6.
				In Proficy 6 must use the field Spec_Desc_Local in dbo.Specifications
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-02
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-05-31
Version		:	2.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Spec_Desc field. This field is calculated in P4.
					Updates must be done in Spec_Desc_Local field.
					PCMT Version 3.0.0
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	5-Feb-2004
Version		:	1.0.0
Purpose 		: 	Copy the specifications of a given property in the new property
					PCMT Version 2.1.0
-------------------------------------------------------------------------------------------------
*/
--declare 
@intPropId		integer,
@vcrPropDesc	varchar(50)

AS
SET NOCOUNT ON

-- Test
--exec [dbo].[spLocal_PCMT_Property_Copy_1] 278,'Test JPG'	
--SELECT	@intPropId	= 278, @vcrPropDesc= 'Test JPG'	

DECLARE
@intNewPropId	integer,
@AppVersion		varchar(30),	-- Used to retrieve the Proficy database Version
@FieldName		varchar(50),	-- Desc field is not the same for P3 and P4
@SQLCommand		nvarchar(500)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

SELECT @intNewPropId = prop_id
FROM dbo.Product_Properties
WHERE prop_desc = @vcrPropDesc

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
SELECT @FieldName =
	CASE  
		WHEN @AppVersion LIKE '3%'	THEN 'Spec_Desc'		-- PPA3
		WHEN @AppVersion LIKE '4%'	THEN 'Spec_Desc_Local'	-- PPA4
		WHEN @AppVersion LIKE '5%'	THEN 'Spec_Desc_Local'	-- PPA5
		WHEN @AppVersion LIKE '6%'	THEN 'Spec_Desc_Local'	-- PPA6
	END

-- old
-- Description field is not the same for each Proficy version
--IF @AppVersion LIKE '4%'
--	SET @FieldName = 'Spec_Desc_Local'	-- P4
--ELSE
--	SET @FieldName = 'Spec_Desc'			-- P3

--SELECT @AppVersion AppVersion, @FieldName FieldName

--Copy Specifications
SET @SQLCommand = 'INSERT Specifications (' + @FieldName + ',Data_Type_Id,Spec_Precision,Prop_Id) ' +
						'SELECT Spec_Desc,Data_Type_Id,Spec_Precision,' + convert(nvarchar,@intNewPropID) + ' ' +
						'FROM Specifications WHERE Prop_Id = ' + convert(nvarchar,@intPropId)
EXEC sp_ExecuteSQL @SQLCommand

SET NOCOUNT OFF
