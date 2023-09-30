Create Procedure dbo.spServer_CmnAddSvrUserParam
@UserId int,
@ParmId int,
@Value nVarChar(255),
@ForceUpdate int = 0
AS
Declare
  @Found int,
  @SiteFound int,
  @CurrentValue nVarChar(255),
  @SiteCurrentValue nVarChar(255),
  @MyHostname nvarchar(50)
SELECT @MyHostname = HOST_NAME() 
Select @CurrentValue = NULL
Select @Found = NULL
Select @Found = Parm_Id, @CurrentValue = Value From User_Parameters Where (User_Id = @UserId) And (Parm_Id = @ParmId) And ((Hostname = '') Or (Hostname = @MyHostname))
If (@Found Is Not NULL) And (@CurrentValue Is Not NULL) And (@ForceUpdate = 0)
  Return
If (@Found Is NULL)
  Begin
-- Use the value from the site parameters unless we are forcing.
 	  	 Select @SiteCurrentValue = NULL
 	  	 Select @SiteFound = NULL
 	  	 Select @SiteFound = Parm_Id, @SiteCurrentValue = Value From Site_Parameters Where (Parm_Id = @ParmId) And ((Hostname = '') Or (Hostname = @MyHostname))
 	  	 If (@SiteFound Is Not NULL) And (@SiteCurrentValue Is Not NULL) And (@ForceUpdate = 0)
 	  	 begin
 	  	  	 Select @Value = @SiteCurrentValue 
 	  	 end
    Select @Found = NULL
    Select @Found = Parm_Id From Parameters Where (Parm_Id = @ParmId)
    If (@Found Is NULL)
      Begin
        Set Identity_Insert Parameters On
        Insert Into Parameters (Parm_Id,Parm_Name) Values(@ParmId,'Server Parameter (' + Convert(nVarChar(10),@ParmId) + ') Missing')
        Set Identity_Insert Parameters Off
      End
    Insert Into User_Parameters (User_Id, Parm_Id, Value, HostName) VALUES(@UserId ,@ParmId ,@Value, '')
  End
Else
  Update User_Parameters Set Value = @Value Where (Parm_Id = @ParmId) And (User_Id = @UserId) And ((Hostname = '') Or (Hostname = @MyHostname))
