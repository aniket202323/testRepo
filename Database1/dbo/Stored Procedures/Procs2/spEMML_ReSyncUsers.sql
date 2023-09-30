CREATE PROCEDURE dbo.spEMML_ReSyncUsers
@User_Id int,
@Load_Key bit = 0
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMML_ReSyncUsers',
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @License_Id int,
@License_Text nvarchar(500),
@SN nVarChar(25),
@Module_Desc nvarchar(50),
@TimeStamp nvarchar(255),
@Type_Id tinyint,
@Module_Id tinyint,
@Concurrent_Users int,
@Validation_Key nvarchar(255),
@Index int,
@MinModuleId int,
@MaxModuleId int,
@Counter int,
@RowCount int,
@SumConcurrentUsers int,
@ConcurrentUsersString nvarchar(255),
@MinValidationKey nvarchar(255),
@MinValidationDate datetime,
@Month nVarChar(10),
@Day nVarChar(10),
@Year nVarChar(10),
@SiteParamSN nvarchar(50),
@Position int,
@Temp_License_Text nvarchar(500),
@ValidLicKey bit,
@App_Id int, 
@Check_Digit nvarchar(255), 
@Check_Digit_Out nvarchar(255), 
@Check_App_Id int, 
@Check_Module_Id int
select @SiteParamSN = Value from Site_Parameters
where Parm_Id = 22
create table #LicensesEncrypted(
License_Id int,
License_Text nvarchar(500)
)
ALTER TABLE #LicensesEncrypted ADD CONSTRAINT
 	 IX_Licenses UNIQUE NONCLUSTERED 
 	 (
 	 License_Text
 	 )
create table #LicensesUnEncrypted(
License_Id int,
License_Text nvarchar(500)
)
create table #LicensesParsed(
License_Id int,
SN nVarChar(25),
Module_Desc nvarchar(50),
TimeStamp nvarchar(255),
Type_Id tinyint,
Module_Id tinyint,
Concurrent_Users int,
Validation_Key nvarchar(255)
)
insert into #LicensesEncrypted
select * from Licenses
Begin Transaction
Declare LicenseKeyCursor Cursor For
  Select License_Id, License_Text from #LicensesEncrypted for read only
Open LicenseKeyCursor
While (0=0) Begin
  Fetch Next
    From LicenseKeyCursor
    Into @License_Id, @License_Text
  If (@@Fetch_Status <> 0) Break
    execute spCmn_Encryption @License_Text,'EncrYptoR',@License_Id,0,@License_Text output
    if @SiteParamSN = 'D000002' and @Load_Key = 1
      Begin
        select @Position = 0
        select @Position = patindex('%D000001%', @License_Text)
        if @Position <> 0
          Begin
            select @Temp_License_Text = @License_Text
            select @Temp_License_Text = replace(@Temp_License_Text,'D000001','D000002')
            select @ValidLicKey = 0
            exec spEMML_ValidateLicKey @Temp_License_Text, @User_Id, @ValidLicKey OUTPUT
            if @ValidLicKey = 1
              Begin
                select @License_Text = @Temp_License_Text
                insert into Licenses (License_Text) values (Null)
                select @License_Id = Scope_Identity()
                execute spCmn_Encryption @Temp_License_Text,'EncrYptoR',@License_Id,1,@Temp_License_Text output
                update Licenses set License_Text = @Temp_License_Text
                where License_Id = @License_Id
              End
          End
      End
    insert into #LicensesUnEncrypted (License_Id, License_Text) values (@License_Id, @License_Text)
    select @Index = charindex('\', @License_Text)
    select @SN = Left(@License_Text, @Index - 1)
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Index = charindex('\', @License_Text)
    select @Module_Desc = Left(@License_Text, @Index - 1)
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Index = charindex('\', @License_Text)
    select @TimeStamp = Left(@License_Text, @Index - 1)
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Index = charindex('\', @License_Text)
    select @Type_Id = Convert(int, Left(@License_Text, @Index - 1))
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Index = charindex('\', @License_Text)
    select @Module_Id = Convert(int, Left(@License_Text, @Index - 1))
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Index = charindex('\', @License_Text)
    select @Concurrent_Users = Convert(int, Left(@License_Text, @Index - 1))
    select @License_Text = LTrim(Stuff(@License_Text, 1, @Index, ''))
    select @Validation_Key = @License_Text
    if SUBSTRING(@Validation_Key, 3,1) <> '/'
      SELECT @Validation_Key = SUBSTRING(@Validation_Key, 1,2) + '/' + SUBSTRING(@Validation_Key, 3,2) + '/' + SUBSTRING(@Validation_Key, 5, 4)
    if @SiteParamSN = @SN and (@Validation_Key = '01/01/1970' or Convert(datetime, @Validation_Key) > dbo.fnServer_CmnGetDate(getUTCdate()))
      Begin
        insert into #LicensesParsed (License_Id, SN, Module_Desc, TimeStamp, Type_Id, Module_Id, Concurrent_Users, Validation_Key) values 
        (@License_Id, @SN, @Module_Desc, @TimeStamp, @Type_Id, @Module_Id, @Concurrent_Users, @Validation_Key)    
      End
End
Close LicenseKeyCursor
Deallocate LicenseKeyCursor
select @MinModuleId = Min(Module_Id) from #LicensesParsed
select @MaxModuleId = Max(Module_Id) from #LicensesParsed
select @Counter = @MinModuleId
update Modules set Concurrent_Users = NULL, Modified_On = dbo.fnServer_CmnGetDate(getUTCdate())
where module_id > 0
NextModuleId:
select @RowCount = Count(*) from #LicensesParsed
where Module_Id = @Counter
If @RowCount > 0 and @Counter <= @MaxModuleId
  Begin
    select @Module_Id = Module_Id, @TimeStamp = TimeStamp from #LicensesParsed
    where Module_Id = @Counter
    If (@SN = 'S200017' or @SN = 'S200018' or @SN = 'S200021' or @SN = 'S200030' or @SN = 'S200031' or @SN = 'S200035' or @SN = 'S200036' or 
        @SN = 'S200039' or @SN = 'S200040' or @SN = 'S200041' or @SN = 'S200043' or @SN = 'S300177' or @SN = 'S300182' or @SN = 'S300183' or 
        @SN = 'S300185' or @SN = 'S300191' or @SN = 'S300192' or @SN = 'S300198' or @SN = 'S300199' or @SN = 'S300200' or @SN = 'S300201' or 
        @SN = 'S300202' or @SN = 'S300205' or @SN = 'S300207' or @SN = 'S300209' or @SN = 'S300231' or @SN = 'S300237' or @SN = 'S300238' or 
        @SN = 'S300239' or @SN = 'S300240' or @SN = 'S300241' or @SN = 'S300242' or @SN = 'S300243' or @SN = 'S300244' or @SN = 'S300252' or 
        @SN = 'S300261' or @SN = 'S300272' or @SN = 'S300285' or @SN = 'S300303' or @SN = 'S300311' or @SN = 'S300328' or @SN = 'S300333' or 
        @SN = 'S300337' or @SN = 'S300340' or @SN = 'S300343' or @SN = 'S300352' or @SN = 'S300354' or @SN = 'S300356' or @SN = 'S300362' or 
        @SN = 'S300375' or @SN = 'S300391') and @Module_Id = 4 and @TimeStamp < '2002-08-01'
      Begin
        update Modules set Concurrent_Users = NULL, Validation_Key = NULL, Modified_On = dbo.fnServer_CmnGetDate(getUTCdate())
        where Module_Id = @Counter
        select @Counter = @Counter + 1
        goto NextModuleId
      End
    Else
      Begin
        select @SumConcurrentUsers = sum(Concurrent_Users) from #LicensesParsed
        where Module_Id = @Counter
        select @ConcurrentUsersString = Convert(nvarchar(255), @SumConcurrentUsers)
        execute spCmn_Encryption @ConcurrentUsersString,'EncrYptoR',@Counter,1,@ConcurrentUsersString output
        select @MinValidationDate = Min(Convert(datetime,Validation_Key)) from #LicensesParsed
        where Module_Id = @Counter
        select @Month = Convert(nVarChar(10), Month(@MinValidationDate))
        select @Day = Convert(nVarChar(10), Day(@MinValidationDate))
        select @Year = Convert(nVarChar(10), Year(@MinValidationDate))
        if Len(@Month) = 1
          select @Month = '0' + @Month
        if Len(@Day) = 1
          select @Day = '0' + @Day
        select @MinValidationKey = @Month + @Day + @Year
        execute spCmn_Encryption @MinValidationKey,'EncrYptoR',@Counter,1,@MinValidationKey output
        update Modules set Concurrent_Users = @ConcurrentUsersString, Validation_Key = @MinValidationKey, Modified_On = dbo.fnServer_CmnGetDate(getUTCdate())
        where Module_Id = @Counter
        select @Counter = @Counter + 1
        goto NextModuleId
      End
  End
else if @RowCount = 0 and @Counter <= @MaxModuleId
  Begin
    update Modules set Concurrent_Users = NULL, Validation_Key = NULL, Modified_On = dbo.fnServer_CmnGetDate(getUTCdate())
    where Module_Id = @Counter
    select @Counter = @Counter + 1
    goto NextModuleId
  End
--ReSync Module_Id for all existing AppVersions rows
Declare AppVersionsCursor Cursor For
  Select Module_Id, App_Id, Module_Check_Digit from AppVersions for read only
Open AppVersionsCursor
While (0=0) Begin
  Fetch Next
    From AppVersionsCursor
    Into @Module_Id, @App_Id, @Check_Digit
    If (@@Fetch_Status <> 0) Break
    If (@Check_Digit is not NULL)
      Begin
        execute spCmn_Encryption @Check_Digit,'EncrYptoR',@App_Id,0,@Check_Digit_Out output
        Select @Index = charindex('\', @Check_Digit_Out)
        If @Index <> 0
          Begin
            Select @Check_App_Id = SubString(@Check_Digit_Out, 1, @Index - 1)
            Select @Check_Module_Id = SubString(@Check_Digit_Out, @Index + 1, (Len(@Check_Digit_Out) - @Index))
            If @Check_App_Id = @App_Id
              Begin
                Update AppVersions Set Module_Id = @Check_Module_Id where App_id = @App_Id
              End
            Else
              Begin
                Update AppVersions set Module_Id = NULL, Module_Check_Digit = NULL Where App_Id = @App_Id
              end
          End
        Else
          Begin
            Update AppVersions set Module_Id = NULL, Module_Check_Digit = NULL Where App_Id = @App_Id
          End
      End
    Else
      Begin
        Update AppVersions set Module_Id = NULL Where App_Id = @App_Id
      End
End
Close AppVersionsCursor
Deallocate AppVersionsCursor
/*
select * from #LicensesParsed
order by Module_Id
select * from #LicensesUnEncrypted
order by License_Text desc
select * from #LicensesEncrypted
*/
commit transaction
drop table #LicensesEncrypted
drop table #LicensesUnEncrypted
drop table #LicensesParsed
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
