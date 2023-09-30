CREATE  PROCEDURE dbo.spCSS_LoadSiteInformation 
@Hostname nvarchar(50)
AS
Declare
  @AppId int,
  @AppKey nVarChar(255),
  @ExpirationDate nVarChar(255),
  @TempDate nVarChar(30), 
  @Date datetime, 
  @Licensed bit,
  @SiteParmId int, 
  @Name nvarchar(50),
  @Value Varchar(5000), 
  @Encrypted bit, 
  @OutputValue nVarChar(255)
SET NOCOUNT ON
--1st Resultset Is Company Information
Declare @Company nVarChar(255), @Site nVarChar(255), @DB nvarchar(50), @ModuleId Int , @AppVersion nvarchar(50)
Select @Company = Value 
  From Site_Parameters 
  Where Parm_Id = 11
Select @Site = Value 
  From Site_Parameters 
  Where Parm_Id = 12
Select @DB = App_Version
  From AppVersions 
  Where App_Id = 34
Select @AppVersion = App_Version
  From AppVersions 
  Where App_Id = 2
Select CompanyName = @Company,
           SiteName = @Site,
           DataBaseVersion = @DB,
           AppVersion = @AppVersion
--2nd Resultset Is License Information
Create Table #Licenses (App_Id int, Licensed bit)
--These apps need to appear in the Licenses table because we have to register them.  
-- This will load their respective translation messages into the message cache.
--8 - Proficy Client
--22 - Common Dialogs
--23 - Server Object (ProfSVR)
--24 - Query Wizard
--200-299 - Reports
-->50000 - Local Reports
Insert Into #Licenses (App_Id, Licensed) 
  Select App_Id, 1
    From AppVersions 
    Where (App_Id in (8, 22, 23, 24,37)) 
      or (App_Id between 200 and 299) 
      or (App_Id > 49999)
Declare AppCursor INSENSITIVE CURSOR
  For (Select App_Id, a.Module_Id, Validation_Key 
        From AppVersions a 
        Join Modules m on a.Module_Id = m.Module_Id
        Where (App_Id not in (8, 22, 23, 24,37)) 
           and (App_Id < 200 or (App_Id between 300 and 49998)))
  For Read Only
  Open AppCursor  
AppCursorLoop1:
  Fetch Next From AppCursor Into @AppId, @ModuleId, @AppKey
  If (@@Fetch_Status = 0)
    Begin
      execute spCmn_Encryption @AppKey,'EncrYptoR',@ModuleId,0,@ExpirationDate output
      If @ExpirationDate is NULL 
        BEGIN
          Select @Licensed = 0 
        END
      ELSE
        BEGIN
 	     -- If it's not a date then set it to valid but expired date (the most important date of 1966 in this case)
          SELECT @TempDate = SUBSTRING(@ExpirationDate, 1,2) + '/' + SUBSTRING(@ExpirationDate, 3,2) + '/' + SUBSTRING(@ExpirationDate, 5, 4)
          If ISDATE(@TempDate) = 0 SELECT @Date = '08/12/1966'
          ELSE SELECT @Date = @TempDate
          SELECT @Licensed = 
            CASE 
              WHEN @Date = '1/1/1970' THEN 1 
              WHEN @Date >= dbo.fnServer_CmnGetDate(getutcdate()) THEN 1 
              ELSE 0 
            END
        END
      INSERT INTO #Licenses VALUES(@AppId, @Licensed)
      Goto AppCursorLoop1
    End
Close AppCursor
Deallocate AppCursor
--Autolog Time-Based and Product-Time displays can be licensed under the Efficiency Module if Quality Module is not licensed
If (Select @Licensed From #Licenses Where App_Id = 30) = 0
  Begin
    Select @AppKey = Validation_Key From Modules Where Module_Id = 2
    Select @ModuleId = 2
    execute spCmn_Encryption @AppKey,'EncrYptoR',@ModuleId,0,@ExpirationDate output
    If @ExpirationDate is not NULL 
      BEGIN
    -- If it's not a date then set it to valid but expired date (the most important date of 1966 in this case)
        SELECT @TempDate = SUBSTRING(@ExpirationDate, 1,2) + '/' + SUBSTRING(@ExpirationDate, 3,2) + '/' + SUBSTRING(@ExpirationDate, 5, 4)
        If ISDATE(@TempDate) = 0 SELECT @Date = '08/12/1966'
        ELSE SELECT @Date = @TempDate
        SELECT @Licensed = 
        CASE 
          WHEN @Date = '1/1/1970' THEN 1 
          WHEN @Date >= dbo.fnServer_CmnGetDate(getutcdate()) THEN 1 
          ELSE 0 
        END
        Update #Licenses Set Licensed = @Licensed Where App_Id = 30
      END
  End
Select App_Id, Licensed From #Licenses
--3rd Resultset Is Site Options
--Create Table #Options (OptionName nvarchar(50), OptionValue nvarchar(50))
--Insert Into #Options (OptionName, OptionValue) Values ('Option1', 'test')
--Select * From #Options
Create Table #Parms (Parm_Id int, Parm_Name nvarchar(50), String_Value varchar(5000) NULL, IsEncrypted bit, HostName nvarchar(50))
Create Table #Parms2 (Parm_Name nvarchar(50), String_Value varchar(5000) NULL)
--Load Hostname specific parameters
Insert Into #Parms
  Select s.Parm_Id, Parm_Name, Value, IsEncrypted, Hostname
    From Site_Parameters s
    Join Parameters p on p.Parm_Id = s.Parm_Id
    Where HostName = @HostName
    Order By HostName
--Load remaining parameters not already loaded
Insert Into #Parms
  Select s.Parm_Id, Parm_Name, Value, IsEncrypted, Hostname
    From Site_Parameters s
    Join Parameters p on p.Parm_Id = s.Parm_Id
    Where HostName = '' and s.Parm_Id not in (Select Parm_Id From #Parms)
    Order By HostName
--Until moved: 
Update #Parms Set String_Value = (Select Listener_Address From CXS_Service Where Service_Id = 14)
  Where Parm_Name = 'RealTimeAddress' and HostName = ''
Update #Parms Set String_Value = (Select Listener_Port From CXS_Service Where Service_Id = 14)
  Where Parm_Name = 'RealTimePort' and HostName = ''
--Site (App_Id = 0) and App parms/overrides
Declare ParmCursor INSENSITIVE CURSOR
  For (Select Parm_Id, Parm_Name, String_Value, IsEncrypted from #Parms)
  For Read Only
  Open ParmCursor  
ParmLoop1:
  Fetch Next From ParmCursor Into @SiteParmId, @Name, @Value, @Encrypted
  If (@@Fetch_Status = 0)
    Begin
      If @Encrypted = 1 
        Begin 
          execute spCmn_Encryption @Value, 'EncrYptoR', @SiteParmId , 0, @OutputValue output
          Select @Value = @OutputValue
        End
      Update #Parms2 Set String_Value = @Value Where Parm_Name = @Name
      If @@ROWCOUNT = 0 
        Insert Into #Parms2 (Parm_Name, String_Value) Values(@Name, @Value)
      Goto ParmLoop1
    End
Close ParmCursor
Deallocate ParmCursor
Select UPPER(Parm_Name) as Parm_Name, String_Value from #Parms2
--4th Resultset Is Site Prompts
Create Table #Prompts (PromptName nvarchar(50), PromptValue nvarchar(50))
Insert Into #Prompts (PromptName, PromptValue) Values ('Product', 'Product')
Select * From #Prompts
Drop Table #Licenses
Drop Table #Prompts
Drop Table #Parms
Drop Table #Parms2
