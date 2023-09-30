













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_Variable_List]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreailt, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets variables list from Local_PG_PCMT_log_variables
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@dtmStartTime	datetime = NULL,
@dtmEndTime		datetime = NULL,
@intUserId		integer = NULL,
@intVarId		integer = NULL

AS
SET NOCOUNT ON

SELECT DISTINCT l.var_id, pl.pl_desc + '\' + l.var_desc AS var_desc
FROM dbo.Local_PG_PCMT_Log_Variables l
     JOIN dbo.Prod_Units pu ON (pu.pu_id = l.pu_id)
     JOIN dbo.Prod_Lines pl ON (pl.pl_id = pu.pl_id)
ORDER BY pl.pl_desc + '\' + l.var_desc

SET NOCOUNT OFF















