













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Error]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-03
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	18-Dec-02	
Version		:	1.0.0
Purpose		:	This SP inserts error into table Local_PG_PCMT_Error
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@vcrDescription	varchar(500),
@vcrModule			varchar(50),
@vcrSub				varchar(50)

AS
SET NOCOUNT ON

INSERT INTO dbo.Local_PG_PCMT_Errors  
VALUES(getdate(), @vcrDescription, @vcrModule, @vcrSub)

SET NOCOUNT OFF















