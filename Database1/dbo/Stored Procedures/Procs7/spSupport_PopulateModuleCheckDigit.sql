Create Procedure [dbo].[spSupport_PopulateModuleCheckDigit]
AS
--******************************************************************************************************
--*  IMPORTANT: This must always on an install and on a server move which involves a new server name. 
--*  this is called by the Verify scripts (Misc) and called by spSupport_ChangeDBOAccount
--******************************************************************************************************
    --Encrypt Check_Digit for all existing AppVersions rows (AppId and ModuleId)
    Declare @App_Id int, @Module_Id int, @Check_Digit varchar(255), @Check_Digit_Out varchar(255)
    Declare AppVersionsCursor Cursor For
      Select Module_Id, App_Id from AppVersions WHERE App_Id < 50000 for read only
    Open AppVersionsCursor
    While (0=0) Begin
      Fetch Next
        From AppVersionsCursor
        Into @Module_Id, @App_Id
        If (@@Fetch_Status <> 0) Break
        If (@Module_Id is not NULL)
          Begin
 	  	     Select @Check_Digit = convert (varchar(255), Convert(varchar(25), @App_Id) + '\' + Convert(varchar(25), @Module_Id))
            execute spCmn_Encryption @Check_Digit,'EncrYptoR',@App_Id,1,@Check_Digit_Out output
            update AppVersions set Module_Check_Digit = @Check_Digit_Out where App_id = @App_Id
          End
    End
    Close AppVersionsCursor
    Deallocate AppVersionsCursor
