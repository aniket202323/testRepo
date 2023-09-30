
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_GetVersion]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-18
Version		:	1.0.0
Purpose		: 	Get the QSMT Application version from AppVersions table.
					PCMT Version 4.1.0
-------------------------------------------------------------------------------------------------
*/

AS
SET NOCOUNT ON

--Get the PCMT Application Version
SELECT App_Version FROM dbo.AppVersions WHERE App_Id = 73000

SET NOCOUNT OFF















