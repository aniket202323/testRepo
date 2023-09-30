












-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Extended_Infos]
/*
-------------------------------------------------------------------------------------------------
Stored procedure: spLocal_PCMT_Get_Extended_Infos
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date created	:	13-Nov-2002	
Version			: 	1.0.0
SP Type			: 	function
Called by		: 	Excel file
Description		: 	This sp return all the engineering units that have been insert
               	on the Process Audit unit.
						PCMT Version 2.1.0 and 3.0.0
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
*/
@vcrPUDesc 	VARCHAR(100),
@vcrPUGDesc VARCHAR(100)

AS

SET NOCOUNT ON

SELECT DISTINCT v.extended_info 
FROM 
	dbo.variables v
	LEFT JOIN dbo.prod_units pu ON (v.pu_id = pu.pu_id AND (pu_desc LIKE '%' + @vcrPUDesc + '%' OR pu_desc = @vcrPUDesc)) 
	LEFT JOIN dbo.pu_groups pug ON (v.pug_id = pug.pug_id AND pug_desc = @vcrPUGDesc)
WHERE 
	v.extended_info IS NOT NULL 
	AND v.extended_info <> ''
	AND LTRIM(RTRIM(v.extended_info)) <> ''

SET NOCOUNT OFF













