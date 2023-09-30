CREATE  PROCEDURE dbo.spPDB_IsTriggerValid(@Valid BIT OUTPUT)
AS
 	 IF (select UPPER(program_name) from master..sysprocesses where spid = @@spid) =  'PURGEAPP'
 	  	 SET @Valid = 0
 	 ELSE
 	  	 SET @Valid = 1
