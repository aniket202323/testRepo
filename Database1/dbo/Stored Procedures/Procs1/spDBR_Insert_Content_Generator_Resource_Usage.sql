Create Procedure dbo.spDBR_Insert_Content_Generator_Resource_Usage
@logtime datetime,
@cpu_usage float = 0,
@virtual_mem int= 0,
@virtual_peak int= 0,
@private_mem int = 0,
@handles int = 0 ,
@threads int = 0,
@pagefaults int =0,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
 	 ---24/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	  
 	  	 SELECT @logtime = dbo.fnServer_CmnConvertToDBTime(@logtime,@InTimeZone)
 	  
insert Dashboard_Content_Generator_Resource_Usage (Dashboard_Resource_Log_Time, Dashboard_CG_CPU_Usage, Dashboard_CG_Virtual_Memory, Dashboard_CG_Virtual_Memory_Peak, Dashboard_CG_Private_Memory, Dashboard_CG_Handle_Count, Dashboard_CG_Thread_Count,Dashboard_CG_PageFaults_per_sec) values(@logtime, @cpu_usage, @virtual_mem, @virtual_peak, @private_mem, @handles, @threads, @pagefaults)
