CREATE PROCEDURE dbo.spPurge_DeleteConfig(@PurgeId int)
 AS
DELETE FROM PurgeConfig_Detail WHERE Purge_Id=@PurgeId
DELETE FROM PurgeConfig WHERE Purge_Id=@PurgeId
