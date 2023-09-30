CREATE PROCEDURE dbo.spSupport_GrantAll 
as 
Declare @Name varchar(255),@count Int
DECLARE @granteeprincipalid Int
if  exists (select * from master..syslogins where name = 'ComXClient')
Begin
 	 SELECT @granteeprincipalid = principal_id
 	  	 FROM sys.database_principals
 	  	 WHERE name = 'ComXClient'
end
if  exists (select * from master..syslogins where name = 'ComXClient')
 	 Begin
 	  	 Print 'Granting rights to tables and Views ...'
 	  	 declare EachTable cursor 
 	  	   For (
 	  	  	  	 SELECT COUNT(a.major_id),'[' + schema_name(uid) + '].[' + name + ']'  
 	  	  	  	 FROM sys.sysobjects b
 	  	  	  	 left Join sys.database_permissions a   on b.id = a.major_id and grantee_principal_id = @granteeprincipalid
 	  	  	  	 where  b.type In ('V','u') and Name not Like 'sys%' 
 	  	  	  	 group by '[' + schema_name(uid) + '].[' + name + ']' 
 	  	  	  	 HAVING COUNT(a.major_id) != 4)
 	  	   For Read Only
 	  	   Open EachTable  
 	  	 EachTable:
 	  	   Fetch Next From EachTable Into @count,@Name
 	  	   If (@@Fetch_Status = 0)
 	  	     Begin
 	  	       --Print @Name
 	  	       exec('GRANT SELECT, INSERT, UPDATE, DELETE ON ' + @Name + 'TO COMXCLIENT')
 	  	       Goto EachTable
 	  	     End
 	  	 Close EachTable
 	  	 Deallocate EachTable 	  	 
 	  	 Print 'Granting rights to stored procedures ...'
 	  	 declare EachProc cursor 
 	  	   For (SELECT COUNT(a.major_id),'[' + schema_name(uid) + '].[' + name + ']'  
 	  	  	  	 from sys.sysobjects b  
 	  	  	  	 left Join sys.database_permissions a on b.id = a.major_id and grantee_principal_id = @granteeprincipalid 
 	  	  	  	 where  b.type = 'p' and name like 'sp%'
 	  	  	  	 group by '[' + schema_name(uid) + '].[' + name + ']' 
 	  	  	  	 HAVING COUNT(a.major_id) != 1)
 	  	   For Read Only
 	  	   Open EachProc  
 	  	 EachProc:
 	  	   Fetch Next From EachProc Into @count,@Name
 	  	   If (@@Fetch_Status = 0)
 	  	     Begin
 	  	       --Print @Name
 	  	       exec('GRANT EXECUTE ON ' + @Name + ' TO COMXCLIENT')
 	  	       Goto EachProc
 	  	     End
 	  	 Close EachProc
 	  	 Deallocate EachProc
 	  	 
 	  	 Print 'Granting rights to Scalar Functions ...'
 	  	 declare EachFunc cursor 
 	  	   For (SELECT COUNT(a.major_id),'[' + schema_name(uid) + '].[' + name + ']'  
 	  	  	  	 from sys.sysobjects b 
 	  	  	  	 left Join sys.database_permissions a on b.id = a.major_id and grantee_principal_id = @granteeprincipalid 
 	  	  	  	 where   b.xtype in('FN')
 	  	  	  	 group by '[' + schema_name(uid) + '].[' + name + ']' 
 	  	  	  	 HAVING COUNT(a.major_id) != 1)
 	  	   For Read Only
 	  	   Open EachFunc  
 	  	 EachFunc:
 	  	   Fetch Next From EachFunc Into @count,@Name
 	  	   If (@@Fetch_Status = 0)
 	  	     Begin
 	  	       --Print @Name
 	  	       exec('GRANT EXECUTE ON ' + @Name + ' TO COMXCLIENT')
 	  	       Goto EachFunc
 	  	     End
 	  	 Close EachFunc
 	  	 Deallocate EachFunc
 	  	 Print 'Granting rights to Table Functions ...'
 	  	 declare EachTVFunc cursor 
 	  	   For (SELECT COUNT(a.major_id),'[' + schema_name(uid) + '].[' + name + ']'  
 	  	  	  	 from sys.sysobjects b 
 	  	  	  	 left Join sys.database_permissions a on b.id = a.major_id and grantee_principal_id = @granteeprincipalid 
 	  	  	  	 where   b.xtype in('TF')
 	  	  	  	 group by '[' + schema_name(uid) + '].[' + name + ']' 
 	  	  	  	 HAVING COUNT(a.major_id) != 1)
 	  	   For Read Only
 	  	   Open EachTVFunc  
 	  	 EachTVFunc:
 	  	   Fetch Next From EachTVFunc Into @count,@Name
 	  	   If (@@Fetch_Status = 0)
 	  	     Begin
 	  	       --Print @Name
 	  	       exec('GRANT SELECT ON ' + @Name + ' TO COMXCLIENT')
 	  	       Goto EachTVFunc
 	  	     End
 	  	 Close EachTVFunc
 	  	 Deallocate EachTVFunc
 	  	 Print 'Granting rights to Synonyms ...'
 	  	 declare EachSynonym cursor 
 	  	   For (SELECT COUNT(a.major_id),'[' + schema_name(uid) + '].[' + name + ']'  
 	  	  	  	 from sys.sysobjects b
 	  	  	  	 left Join sys.database_permissions a on b.id = a.major_id and grantee_principal_id = @granteeprincipalid  
 	  	  	  	 where b.xtype in('SN')
 	  	  	  	 group by '[' + schema_name(uid) + '].[' + name + ']' 
 	  	  	  	 HAVING COUNT(a.major_id) != 1)
 	  	   For Read Only
 	  	   Open EachSynonym  
 	  	 EachSynonym:
 	  	   Fetch Next From EachSynonym Into @count,@Name
 	  	   If (@@Fetch_Status = 0)
 	  	     Begin
 	  	       --Print @Name
 	  	       exec('GRANT SELECT ON ' + @Name + ' TO COMXCLIENT')
 	  	       Goto EachSynonym
 	  	     End
 	  	 Close EachSynonym
 	  	 Deallocate EachSynonym
 	  	 If Exists (Select * from sys.sysobjects where id = object_id('dbo.spServer_CmnGetLicenseMgrInfo') and sysstat & 0xf = 4)
 	  	 BEGIN
 	  	  	 GRANT  EXECUTE  ON dbo.spServer_CmnGetLicenseMgrInfo  TO ProficyConnect
 	  	  	 REVOKE  EXECUTE  ON dbo.spServer_CmnGetLicenseMgrInfo  TO COMXCLIENT
 	  	 END
End
if  exists (select * from master..syslogins where name = 'proficyetl')
  begin
    if exists (select * from sys.sysobjects where id = object_id(N'[dbo].[fnRS_GetMillStartTime]') and xtype in (N'FN', N'IF', N'TF'))
       Grant execute on fnrs_getmillstarttime to proficyetl
  end
Print '... Done'
