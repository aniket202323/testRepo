CREATE PROCEDURE dbo.spPurge_GetConfigs AS
exec dbo.spPurge_VerifyPurgeConfig
--get a list of all purge configs
select 
 	 Purge_Desc,Purge_Id
from
 	 PurgeConfig
order by
 	 Purge_Desc
