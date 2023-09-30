CREATE PROCEDURE dbo.spEMML_GetModuleInfo 
@User_Id int,
@ModuleOnly bit = NULL
AS
Declare 
  @OutputString nvarchar(255), 
  @ConcurrentUsers nvarchar(255), 
  @MaxUsers int, 
  @CurrentUsers int, 
  @HeartbeatLength int 
Declare @Module_Id int,
@Validation_Key nvarchar(255),
@Concurrent_Users nvarchar(255),
@SN nVarChar(25)
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMML_GetModuleInfo',
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
exec spEMML_ReSyncUsers @User_Id
if @ModuleOnly is NULL select @ModuleOnly = 0
create table #ModuleInfo(
  Module_Id tinyint,
  Module_Desc nvarchar(50),
  Validation_Key nvarchar(255),
  Concurrent_Users nvarchar(255),
  Active_Users int,
  Configure_By_Number_Of_Users int
)
--First two if's are for iDownTime and the third is for Proficy Administrator
select @SN = value from site_parameters
where parm_id = 22
if @SN = 'D000001'
  Begin
    insert into #ModuleInfo
    select module_id, CASE WHEN Module_Id = 2 THEN 'Single Line iDownTime' ELSE 'Excel Add-In' END, validation_key, concurrent_users, NULL, configure_by_number_of_users
    from modules
    Where Module_Id in (2, 5)
  End
else if @SN = 'D000002'
  Begin
    insert into #ModuleInfo
    select module_id, CASE WHEN Module_Id = 2 THEN 'Multi-Line iDownTime' ELSE 'Excel Add-In' END, validation_key, concurrent_users, NULL, configure_by_number_of_users
    from modules
    Where Module_Id in (2, 5)
  End
else
  Begin
    insert into #ModuleInfo
    select module_id, module_desc, validation_key, concurrent_users, NULL, configure_by_number_of_users
    from modules
    Where Module_Id > 0
  End
Declare #ModuleInfoCursor Cursor For
  Select Module_Id from #ModuleInfo for read only
Open #ModuleInfoCursor
While (0=0) Begin
  Fetch Next
    From #ModuleInfoCursor
    Into @Module_Id
  If (@@Fetch_Status <> 0) Break
    select @Validation_Key = validation_key from #ModuleInfo
    where module_id = @Module_Id
    if @Validation_Key <> ''
      Begin
        execute spCmn_Encryption @Validation_Key,'EncrYptoR',@Module_Id,0,@Validation_Key output
        if SUBSTRING(@Validation_Key, 3,1) <> '/'
          SELECT @Validation_Key = SUBSTRING(@Validation_Key, 1,2) + '/' + SUBSTRING(@Validation_Key, 3,2) + '/' + SUBSTRING(@Validation_Key, 5, 4)
      End
      select @Concurrent_Users = concurrent_users from #ModuleInfo
      where module_id = @Module_Id
      if @Concurrent_Users <> ''
        execute spCmn_Encryption @Concurrent_Users,'EncrYptoR',@Module_Id,0,@Concurrent_Users output
    update #ModuleInfo set Concurrent_Users = @Concurrent_Users, Validation_Key = @Validation_Key
    where module_id = @Module_Id
    SELECT @ConcurrentUsers = m.Concurrent_Users
    FROM Modules m 
    WHERE m.Module_id = @Module_Id
    EXEC spCmn_Encryption @ConcurrentUsers,'EncrYptoR',@Module_Id,0,@OutputString output 
    SELECT @MaxUsers = CONVERT(Int, COALESCE(@OutputString, 0))
    If @MaxUsers > 0 
      BEGIN 
        Select @HeartbeatLength = COALESCE(CONVERT(int, COALESCE(value, '0') ), 0) 
        From Site_Parameters p
        Join Client_Connections c on p.Hostname = c.Hostname
        Where Parm_Id = 21 
        If @HeartbeatLength = 0 
          Select @HeartbeatLength = CONVERT(int, COALESCE(value, '10') ) 
          From Site_Parameters p
          Where Parm_Id = 21 and Hostname = ''
        If @HeartbeatLength is NULL or @HeartbeatLength = 0 
          Select @HeartbeatLength = 10
        -- How many users are currently logged on
        SELECT @CurrentUsers = COALESCE(COUNT(DISTINCT HOSTNAME), 0) 
          From Client_Connection_Module_Data m
          Join Client_Connections c on c.Client_Connection_Id = m.Client_Connection_Id 
            and (c.End_Time is null and DATEDIFF(minute, c.Last_Heartbeat, dbo.fnServer_CmnGetDate(getUTCdate())) < @HeartbeatLength) 
          Where Module_Id = @Module_Id
/*
        SELECT @CurrentUsers = COALESCE(COUNT(*), 0) 
          From Client_Connection_Module_Data m
          Join Client_Connections c on c.Client_Connection_Id = m.Client_Connection_Id and c.End_Time is null and DATEDIFF(minute, c.Last_Heartbeat, dbo.fnServer_CmnGetDate(getUTCdate())) < @HeartbeatLength  
          Where Module_Id = @Module_Id
*/
          update #ModuleInfo set Active_Users = @CurrentUsers
          where module_id = @Module_Id
      END
End
Close #ModuleInfoCursor
Deallocate #ModuleInfoCursor
select * from #ModuleInfo
order by Module_Desc
drop table #ModuleInfo
if @ModuleOnly = 0
  select * from site_parameters where parm_id = 22
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
