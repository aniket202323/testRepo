

-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_DropProperty]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 1.16
-------------------------------------------------------------------------------------------------
Created by	:	Jonathan, Solutions et Technologies Industrielles Inc.
On				:	2008-12-23
Version		:	1.0.0
Purpose		: 	Drop properties using GE stored procedure 
					PCMT Version 1.25 and more
-------------------------------------------------------------------------------------------------
*/
@intPropId	INT,
@intUserId INT

AS
SET NOCOUNT ON

   EXEC spEM_DropProp @intPropId, @intUserId

SET NOCOUNT OFF


