CREATE PROCEDURE dbo.spPurge_CheckProcesses(@count int out) AS
--get count of plantapps processes
set @count=0
select 
 	 @count=count(*) 
from 
 	 master..sysprocesses 
where 
 	 spid<>@@spid 
 	 and dbid=DB_ID()
 	 and loginame in( 'ComXClient')
 	 and ltrim(rtrim(program_name)) in ( 
 	  	 'PlantApps PlantAppsMgr',
 	  	 'PlantApps RDS',
 	  	 'PlantApps ScheduleMgr',
 	  	 'PlantApps Gateway',
 	  	 'PlantApps EmailEngine',
 	  	 'PlantApps AlarmMgr',
 	  	 'PlantApps FTPEngine',
 	  	 'PlantApps CalculationMgr',
 	  	 'PlantApps PrintServer',
 	  	 'PlantApps DatabaseMgr',
 	  	 'PlantApps EventMgr',
 	  	 'PlantApps Reader',
 	  	 'PlantApps Writer',
 	  	 'PlantApps SummaryMgr',
 	  	 'PlantApps Stubber',
 	  	 'Proficy ProficyMgr',
 	  	 'Proficy Gateway',
 	  	 'Proficy AlarmMgr',
 	  	 'Proficy FTPEngine',
 	  	 'Proficy CalculationMgr',
 	  	 'Proficy DatabaseMgr',
 	  	 'Proficy EventMgr',
 	  	 'Proficy Reader',
 	  	 'Proficy Writer',
 	  	 'Proficy SummaryMgr',
 	  	 'Proficy Stubber'
 	 )
