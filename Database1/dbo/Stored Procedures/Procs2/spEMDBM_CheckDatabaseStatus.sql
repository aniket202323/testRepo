CREATE PROCEDURE dbo.spEMDBM_CheckDatabaseStatus 
  AS
 	 If (Select count(*) from master..sysprocesses where loginame = 'ComXClient' and spid <> @@spid) > 0 
 	  	 Begin
 	  	  	 Select Distinct ltrim(rtrim(hostname)) + '  [' +  ltrim(rtrim(program_name)) + ']'
 	  	  	  	 from master..sysprocesses 
 	  	  	  	 where loginame = 'ComXClient' and spid <> @@spid and  ltrim(rtrim(program_name)) <> 'PlantApps License Manager'
 	  	  	 Return(1)
 	  	 End
 	 Return(0)
