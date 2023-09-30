CREATE PROCEDURE dbo.spEMML_UpdateModuleLicense 
@Module_Id tinyint,
@Validation_Key nvarchar(255),
@Concurrent_Users nvarchar(255),
@Type_Id tinyint,
@License_Text nvarchar(500),
@SN nVarChar(25),
@TimeStamp nvarchar(255),
@User_Id int,
@ValidLicense bit OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMML_UpdateModuleLicense',
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @CurrentUsers nvarchar(255),
@CurrentTimeOutDate nvarchar(255),
@License_Id int,
@dNow datetime
Declare @@License_Id int,
@@License_Text nvarchar(500),
@@SN nVarChar(25),
@@Module_Desc nvarchar(50),
@@TimeStamp nvarchar(255),
@@Type_Id tinyint,
@@Module_Id tinyint,
@@Concurrent_Users int,
@@Validation_Key nvarchar(255),
@@Index int
If (@SN = 'S200017' or @SN = 'S200018' or @SN = 'S200021' or @SN = 'S200030' or @SN = 'S200031' or @SN = 'S200035' or @SN = 'S200036' or 
    @SN = 'S200039' or @SN = 'S200040' or @SN = 'S200041' or @SN = 'S200043' or @SN = 'S300177' or @SN = 'S300182' or @SN = 'S300183' or 
    @SN = 'S300185' or @SN = 'S300191' or @SN = 'S300192' or @SN = 'S300198' or @SN = 'S300199' or @SN = 'S300200' or @SN = 'S300201' or 
    @SN = 'S300202' or @SN = 'S300205' or @SN = 'S300207' or @SN = 'S300209' or @SN = 'S300231' or @SN = 'S300237' or @SN = 'S300238' or 
    @SN = 'S300239' or @SN = 'S300240' or @SN = 'S300241' or @SN = 'S300242' or @SN = 'S300243' or @SN = 'S300244' or @SN = 'S300252' or 
    @SN = 'S300261' or @SN = 'S300272' or @SN = 'S300285' or @SN = 'S300303' or @SN = 'S300311' or @SN = 'S300328' or @SN = 'S300333' or 
    @SN = 'S300337' or @SN = 'S300340' or @SN = 'S300343' or @SN = 'S300352' or @SN = 'S300354' or @SN = 'S300356' or @SN = 'S300362' or 
    @SN = 'S300375' or @SN = 'S300391') and @Module_Id = 4 and @TimeStamp < '2002-08-01'
  Begin
    select @ValidLicense = 1
  End
Else
  Begin
  select @ValidLicense = 0
  select @dNow = dbo.fnServer_CmnGetDate(getUTCdate())
  select @CurrentTimeOutDate = validation_key
  from modules
  where module_id = @Module_Id
  if @CurrentTimeOutDate <> ""
    execute spCmn_Encryption @CurrentTimeOutDate,'EncrYptoR',@Module_Id,0,@CurrentTimeOutDate output
  if SUBSTRING(@CurrentTimeOutDate, 3,1) <> '/'
    SELECT @CurrentTimeOutDate = SUBSTRING(@CurrentTimeOutDate, 1,2) + '/' + SUBSTRING(@CurrentTimeOutDate, 3,2) + '/' + SUBSTRING(@CurrentTimeOutDate, 5, 4)
  if SUBSTRING(@Validation_Key, 3,1) <> '/'
    SELECT @Validation_Key = SUBSTRING(@Validation_Key, 1,2) + '/' + SUBSTRING(@Validation_Key, 3,2) + '/' + SUBSTRING(@Validation_Key, 5, 4)
  if @Validation_Key = '01/01/1970' or (Convert(datetime, @Validation_Key) >= @dNow and Convert(datetime, @Validation_Key) >= Convert(datetime, Coalesce(@CurrentTimeOutDate, '01/01/1970')))
    Begin
      select @ValidLicense = 1
      if @Type_Id = 2
        Begin
          select @CurrentUsers = concurrent_users from modules where module_id = @Module_Id
          execute spCmn_Encryption @CurrentUsers,'EncrYptoR',@Module_Id,0,@CurrentUsers output
          select @Concurrent_Users = Convert (nvarchar(255), Convert(int, @Concurrent_Users) + Convert(int, @CurrentUsers))
          execute spCmn_Encryption @Concurrent_Users,'EncrYptoR',@Module_Id,1,@Concurrent_Users output
        End
      else if @Type_Id = 1
        Begin
          execute spCmn_Encryption @Concurrent_Users,'EncrYptoR',@Module_Id,1,@Concurrent_Users output
        End
      Begin Transaction
      if @CurrentTimeOutDate = '01/01/1970'
        Begin
          update modules set concurrent_users = @Concurrent_Users, modified_on = dbo.fnServer_CmnGetDate(getUTCdate())
          where module_id = @Module_Id
        End
      else if Not(@Validation_Key = '01/01/0970' and @Type_Id = 2) 
        Begin
          if SUBSTRING(@Validation_Key, 3,1) = '/'
            SELECT @Validation_Key = SUBSTRING(@Validation_Key, 1,2) + SUBSTRING(@Validation_Key, 4,2) + SUBSTRING(@Validation_Key, 7, 4)
          execute spCmn_Encryption @Validation_Key,'EncrYptoR',@Module_Id,1,@Validation_Key output
          update modules set validation_key = @Validation_Key, concurrent_users = @Concurrent_Users, modified_on = dbo.fnServer_CmnGetDate(getUTCdate())
          where module_id = @Module_Id
        End
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
      Declare LicenseKeyCursor Cursor For
        Select License_Id, License_Text from #LicensesEncrypted for read only
      Open LicenseKeyCursor
      While (0=0) Begin
        Fetch Next
          From LicenseKeyCursor
          Into @@License_Id, @@License_Text
        If (@@Fetch_Status <> 0) Break
          execute spCmn_Encryption @@License_Text,'EncrYptoR',@@License_Id,0,@@License_Text output
          insert into #LicensesUnEncrypted (License_Id, License_Text) values (@@License_Id, @@License_Text)
          select @@Index = charindex('\', @@License_Text)
          select @@SN = Left(@@License_Text, @@Index - 1)
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Index = charindex('\', @@License_Text)
          select @@Module_Desc = Left(@@License_Text, @@Index - 1)
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Index = charindex('\', @@License_Text)
          select @@TimeStamp = Left(@@License_Text, @@Index - 1)
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Index = charindex('\', @@License_Text)
          select @@Type_Id = Convert(int, Left(@@License_Text, @@Index - 1))
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Index = charindex('\', @@License_Text)
          select @@Module_Id = Convert(int, Left(@@License_Text, @@Index - 1))
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Index = charindex('\', @@License_Text)
          select @@Concurrent_Users = Convert(int, Left(@@License_Text, @@Index - 1))
          select @@License_Text = LTrim(Stuff(@@License_Text, 1, @@Index, ''))
          select @@Validation_Key = @@License_Text
          if SUBSTRING(@@Validation_Key, 3,1) <> '/'
            SELECT @@Validation_Key = SUBSTRING(@@Validation_Key, 1,2) + '/' + SUBSTRING(@@Validation_Key, 3,2) + '/' + SUBSTRING(@@Validation_Key, 5, 4)
          insert into #LicensesParsed (License_Id, SN, Module_Desc, TimeStamp, Type_Id, Module_Id, Concurrent_Users, Validation_Key) values 
          (@@License_Id, @@SN, @@Module_Desc, @@TimeStamp, @@Type_Id, @@Module_Id, @@Concurrent_Users, @@Validation_Key)    
      End
      Close LicenseKeyCursor
      Deallocate LicenseKeyCursor
      delete from licenses where License_Id = (select License_Id from #LicensesParsed where module_id = @Module_Id)
      insert into Licenses (License_Text) values (Null)
      select @License_Id = Scope_Identity()
      execute spCmn_Encryption @License_Text,'EncrYptoR',@License_Id,1,@License_Text output
      update Licenses set License_Text = @License_Text
      where License_Id = @License_Id
      commit transaction
      drop table #LicensesEncrypted
      drop table #LicensesUnEncrypted
      drop table #LicensesParsed
    End
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
