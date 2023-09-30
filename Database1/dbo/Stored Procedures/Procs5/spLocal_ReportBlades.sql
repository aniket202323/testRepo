CREATE PROCEDURE spLocal_ReportBlades  
  
 @VarHead  varchar(30),  
 @VarTail  varchar(20),  
 @PUID   int,  
 @Field   varchar(50),  
 @UserName  char(20),  
 @DEBUG_STATUS int  
AS  
DECLARE  
 @VarID  int,  
 @StrSQL varchar(8000)  
IF @DEBUG_STATUS = 1  
 BEGIN  
  print 'updating the reprot blade table'  
  select @VarHead as VarHead, @VarTail as VarTail  
 END  
 select @VarID = var_id  
  from variables  
  where var_desc = @VarHead + @VarTail  
   and pu_id = @PUID  
IF @DEBUG_STATUS = 1  
 BEGIN  
  select @varid as VarID,@Field as Field  
 END  
--set @strSQL  
 select @strSQL = 'Update Local_ReportPMKGBlades  
   set [' + @Field +'] = result  
  from tests  
   inner join Local_ReportPMKGBlades on (eventtime = result_on)  
  where  var_id = ' + convert(char(4),@VarID) + 'and username = ''' + @UserName + ''''  
IF @DEBUG_STATUS = 1  
 BEGIN  
  print @strSQL  
 END  
--exec @strSQL  
 exec(@strSQL)  
  
  
  
  
  
  
  
  
  
  
  
  
  
