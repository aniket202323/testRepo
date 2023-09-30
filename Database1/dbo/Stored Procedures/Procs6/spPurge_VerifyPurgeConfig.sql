CREATE PROCEDURE dbo.spPurge_VerifyPurgeConfig
AS
--We can't count on the DELETE CASCADE foreign keys in 215/7.0
Delete PurgeConfig_Detail Where Purge_Id not in (Select Purge_Id from PurgeConfig)
Delete PurgeConfig_Detail Where pu_id not in (Select Pu_Id from Prod_Units)
Delete PurgeConfig_Detail Where Var_id not in (Select Var_Id from Variables)
