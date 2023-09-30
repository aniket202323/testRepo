








-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_DataSource]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Tim Rogers
Date			:	2007-11-20
Version		:	1.1.2
Purpose		: 	changed the code so it will not focus on the exact text, but show any custom data source.
-------------------------------------------------------------------------------------------------
Updated By	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2007-10-29
Version		:	1.1.1
Purpose		: 	Add the QFactors
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	This sp return the possible data source for PCMT.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

AS
SET NOCOUNT ON

SELECT ds_id, ds_desc
FROM dbo.Data_Source
WHERE ds_desc IN ('Autolog','Base Unit','Base Variable','Historian','Undefined')
or ds_id > 50000

SET NOCOUNT OFF

















