  /*  
Stored Procedure: dbo.spLocal_Parts_SpeedsCleanUp  
Author:   John Yannone  
Date Created:  Feb 27, 2006  
  
  
  
Description:  
=========  
This sp will complete the round trip and update the PARTS database with the results   
of the speeds import transactions.  
  
Change Date  Who What  
=========== ==== =====  
Feb 27, 2006   JY  Created procedure  
April 9, 2007   FGO  Updated to the new Oracle field names  
April 20,2007  FGO  Corrected the change in Oracle progamming made by John Yannone and not taken into account with the org. code  
May 1, 2007   FGO  missed on update with SiteID corrected  
May 10, 2007  FGO  added the Proficy User to the update of the PARTS History table  
June 14, 2007  FGO  correct the delete statment back to PARTS  
June 21, 2007  FGO  updated @NoExist to write to the PARTS error table  
         added more error checking  
May 05, 2008    FLD  Increased size of @NoExist from 200 to 500.  The string was getting cut off, causing an Oracle error.  
May 08, 2008  FLD  Corrected issue with field sizes in @PartsRemoteUpds not aligned with sizes of the variables  
         feeding it.  
  
  
*/  
  
CREATE  PROCEDURE dbo.spLocal_Parts_SpeedsCleanUp  
  
  @Success int OUTPUT,    --the sucess status  
  @ErrMsg varchar(255) OUTPUT   --the error message  
AS  
     
  
Declare   
        @CheckExist varchar(200),  --the string to run against the foreign computer to check for data  
        @YesExist varchar(1000),  --the string to run against the foreign computer is @CheckExit is greater than 1  
        @NoExist varchar(500),   --the string to run against the foreign computer is @CheckExit is 0  
        @ConfirmString varchar(200),  --the confirmation string that would optionally (Parm4) be called against the foreign computer  
        @YesConfirm varchar(100),  --if @ConfirmString greater then 0 call this string against the local computer  
        @NoConfirm varchar(100),  --if @ConfirmString =0 call this string against the local computer  
        @TransID int,     --the transid from the tranactions table that will match the Orcal tran_is on the PARTS side  
        @TransOutcome varchar(30),  --the transaction outcome ofr PARTS  
        @InterfaceMsg varchar(500),  --the interface message for PARTS  
        @SqlServerMsgs varchar(500),  -- the sql message for PARTS  
        @Archived varchar(3),   --the PARTS archived Flag  
        @SQLCommand varchar(250),  --the SQL command  
 @DBLangParmID  int,    --this is the lang parm_id for the site  
 @GlobalLang  int,    --this is the value of the lang parm_id of the site  
 @UserId    int,    --this is the caller user_id  
 @UserLang   int,    --this is the user lang value  
 @PlantID   varchar(25),  --this is the plant id for the TT Interfaces  
 @LinkStr   varchar(100), --This is the external_link string to find in the sheets table to inculde the sheet  
 @ProfUser   varchar(30)    --This is the Proficy User         
 -- Create Temporary table variable  
declare @PartsRemoteUpds table (  
 Id Int Identity (1,1) Not Null,   
 CheckExist varchar(200) Null,  
 YesExist varchar(1000) Null,  
 NoExist varchar(500) Null,  
 ConfirmString varchar(200) Null,  
 YesConfirm varchar(100) Null,  
 NoConfirm varchar(100) Null  
)  
  
Select @Success = 0  
Select @ErrMsg = 'No Records'  
SELECT @ProfUser = 'PARTS Speeds'  
-- Determine the language and user to set the correct desc fields  
 SELECT @DBLangParmID=parm_id FROM dbo.parameters WHERE parm_name = 'LanguageNumber'  
 SELECT @GlobalLang = value FROM dbo.site_parameters WHERE parm_id = @DBLangParmID  
 IF EXISTS(SELECT * FROM dbo.users WHERE username =@ProfUser)  
  BEGIN  
    SELECT @UserID = user_id FROM dbo.users WHERE username = @ProfUser  
    SELECT @UserLang = up.value  
     FROM dbo.user_parameters up  
      LEFT JOIN dbo.users u on u.user_id = up.user_id  
     WHERE u.user_id = @UserID and up.parm_id = @DBLangParmID  
  END  
 ELSE  
  BEGIN  
   SELECT @Success = 0  
   SELECT @ErrMsg= 'No PARTS Speeds User'  
   GOTO PlantAppsReturn  
  END   
IF @UserLang = @GlobalLang  
  BEGIN  
   SET nocount on  
  END  
 ELSE  
  BEGIN  
   SET nocount off  
  END  
--Find @PlantID  
 SET @LinkStr = 'SAPSite='  
 SELECT @PlantID = GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @LinkStr)  
  from dbo.prod_lines   
   where pl_desc = 'TT Interfaces'  
  
-- Declare Cursor to Pull all records from   
-- Proficy side holding table.  
DECLARE CleanUpCursor CURSOR FOR  
  
SELECT Trans_ID, Trans_Outcome, Interface_Comments, SQL_Server_Messages   
FROM [dbo].Local_Parts_Speeds_Interface_Log   
  
Open CleanUpCursor    
FETCH NEXT FROM CleanUpCursor  
INTO @TransID, @TransOutcome, @InterfaceMsg, @SqlServerMsgs  
    
--A Fetch status of zero means we are not at the end of the cursor  
--i.e. there's a record in the cursor  
WHILE @@FETCH_STATUS = 0  
  
  Begin  
   
-- Build Strings for the resultset  
  Select @CheckExist = Null  
  Select @YesExist = Null  
  Select @NoExist = Null  
  Select @ConfirmString = Null  
  Select @YesConfirm = Null  
  Select @NoConfirm = Null  
  Select @Archived = 'YES'  
   
  --Check the PARTS history table for matching trans_id.  
  Select @CheckExist ='SELECT Count(*) FROM part_adm.PROF_SPEEDS_INTERFACE_HOLDING WHERE trans_id = '+'''' + convert(varchar,(@TransID))  + ''''+ ' AND site_id = ''' + @PlantID +''''  
  
  --If record(s) exist, archive them.  
  Select @YesExist = ' UPDATE part_adm.PROF_SPEEDS_INTERFACE_HISTORY SET Archived = ''' + @Archived  +  ''',' +  
                     ' Trans_Outcome = ''' + @TransOutcome +  ''',' + 'Interface_Comments = ''' + @InterfaceMsg +  ''',' +  
                     ' SQL_Server_Messages = ''' + @SqlServerMsgs + ''',' + 'PROFICY_USERNAME= ''' +  @ProfUser +  '''  WHERE TRANS_ID = ''' + convert(varchar,(@TransID)) +'''' + ' AND site_id = ''' + @PlantID +''''  
    
  --Delete the original record from the PARTS  
  --side HOLDING table.  
  
Select @NoExist =       'INSERT INTO part_adm.PROF_SPEEDS_INTERFACE_ERRORS (TRANS_ID, SITE_ID, ERROR, ERR_TIMESTAMP) ' +  
                                          'VALUES (''' + convert(varchar,(@TransID)) +  ''',''' + @PlantID +  ''', ''The Proficy side of the ' +  
                                          'interface processed a record NOT found in the PARTS holding table.'', SYSDATE)'  
--  Select @NoExist = 'DELETE FROM part_adm.PROF_SPEEDS_INTERFACE_HOLDING WHERE trans_id = ''' + convert(varchar,(@TransID)) +''' AND site_id = ''' + @PlantID +''''  
  
  Select @SQLCommand = 'DELETE from dbo.Local_Parts_Speeds_Interface_Log where trans_id = ''' + convert(varchar,(@TransID)) +''''  
  Execute(@SQLCommand)  
   
   --Populate temporary table variable.  
   Insert Into @PartsRemoteUpds (CheckExist, YesExist, NoExist, ConfirmString, YesConfirm, NoConfirm)  
   Select @CheckExist, @YesExist, @NoExist, @ConfirmString, @YesConfirm, @NoConfirm  
   
  
  --Get the next rec.  
  FETCH NEXT FROM CleanUpCursor  
  INTO @TransID, @TransOutcome, @InterfaceMsg, @SqlServerMsgs  
  
End  
  
--Clean up.   
Close CleanUpCursor  
Deallocate CleanUpCursor  
  
--Return resultset  
If (SELECT Count(*) FROM @PartsRemoteUpds) > 0  
 Begin  
    SELECT CheckExist, YesExist, NoExist, ConfirmString, YesConfirm, NoConfirm  
     FROM @PartsRemoteUpds  
     ORDER BY Id  
  End  
ELSE  
 BEGIN  
  Select @Success = 1  
  Select @ErrMsg = 'No Data to Send to PARTS'  
  GOTO PlantAppsReturn  
 END  
--Reset the error messaging  
 SELECT @Success =1  
 SELECT @ErrMsg = 'All Data processed'  
PlantAppsReturn:  
  
  
