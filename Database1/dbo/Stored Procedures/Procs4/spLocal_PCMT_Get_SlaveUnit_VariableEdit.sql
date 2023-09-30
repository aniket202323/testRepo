

-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_SlaveUnit_VariableEdit]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_SlaveUnit_VariableEdit

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alberto Ledesma - Arido Software
Date ALTERd		:	2010-11-04
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp returns the specific lines as slave unit selected
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
*/

--@VarId			INT,
@Lines			VARCHAR(100),
@pu_desc		varchar(50)


AS
SET NOCOUNT ON

SET @pu_desc 	= ISNULL(@pu_desc,'')
SET @pu_desc 	= LTRIM(RTRIM(@pu_desc))
SET @pu_desc	= CASE WHEN @pu_desc = '[Enter unit filter]' THEN '' ELSE @pu_desc END

CREATE TABLE #Temp_LinesParam(
	RecId	INT,
	Pl_ID	INT
)


Insert INTO #Temp_LinesParam 
Exec SPCMN_ReportCollectionParsing @PRMCollectionString = @Lines, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',', @PRMDataType01 = 'NVARCHAR(200)'


--set @pu_desc = 'divert'
--set @pug_desc = ''


SELECT  distinct pu.pu_desc--, pu.pu_id, pl.pl_desc, pum.pu_desc, pl.pl_id
FROM prod_units pu
	JOIN prod_lines pl ON pl.pl_id=pu.pl_id
	JOIN prod_units pum ON pum.pu_id=pu.master_unit
WHERE pu.master_unit IS NOT NULL
	AND pu.pl_id IN (SELECT pl_id FROM #Temp_LinesParam)
	AND pum.pu_desc LIKE '%' + @pu_desc + '%'
	AND pu.pu_desc NOT LIKE 'z_obs%'



DROP TABLE #Temp_LinesParam

SET NOCOUNT OFF
