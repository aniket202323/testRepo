 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Version 1.0  Last Update: 2004-01-23  Jeff Jaeger  
-- 03/31/05 JSJ added the owner name to object references  
--  
*/  
CREATE  PROCEDURE dbo.spLocal_GetLocalLanguageDesc  
--Declare  
@UserName  varchar(50)    
As  
  
SET NOCOUNT ON  
-- test value  
--select @UserName = 'comXClient'  
  
---------------------------------------------  
-- Variable Declarations  
---------------------------------------------  
declare   
@UserID   int,  
@LanguageID  int,  
@LanguageParmID  int  
  
select @LanguageParmID = 8  
  
select @UserID = User_ID  
from [dbo].Users  
where UserName = @UserName  
  
select @LanguageID =  
case  
when isnumeric(ltrim(rtrim(value))) = 1  
then convert(float,ltrim(rtrim(value)))  
else null  
end  
from [dbo].User_Parameters  
where User_ID = @UserID  
and Parm_id = @LanguageParmID  
  
if @LanguageID is null  
 begin  
  
  select @LanguageID =  
   case   
   when isnumeric(ltrim(rtrim(value))) = 1   
   then convert(float,ltrim(rtrim(value)))  
   else null  
   end  
  from [dbo].Site_Parameters  
  where Parm_ID = @LanguageParmID  
    
  if @LanguageID is null  
   select @LanguageID = 0  
  
 end  
  
---------------------------------------  
--  Result set  
---------------------------------------  
select language_desc  
from [dbo].languages   
where language_id = @LanguageID  
  
SET NOCOUNT OFF  
  
