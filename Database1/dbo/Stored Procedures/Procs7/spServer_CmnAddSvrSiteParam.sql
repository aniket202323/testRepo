Create Procedure dbo.spServer_CmnAddSvrSiteParam
@ParmId int,
@Value nVarChar(255)
AS
Declare
  @CurrentValue nVarChar(255),
  @Found int,
  @MyHostname nvarchar(50)
SELECT @MyHostname = HOST_NAME() 
Select @CurrentValue = NULL
Select @Found = NULL
Select @Found = Parm_Id, @CurrentValue = Value From Site_Parameters Where (Parm_Id = @ParmId) And ((Hostname = '') Or (Hostname = @MyHostname))
If (@Found Is Not NULL) And (@CurrentValue Is Not NULL)
  Return
If (@Found Is NULL)
  Begin
    Select @Found = NULL
    Select @Found = Parm_Id From Parameters Where (Parm_Id = @ParmId)
    If (@Found Is NULL)
      Begin
        Set Identity_Insert Parameters On
        Insert Into Parameters (Parm_Id,Parm_Name) Values(@ParmId,'Server Parameter (' + Convert(nVarChar(10),@ParmId) + ') Missing')
        Set Identity_Insert Parameters Off
      End
    Insert Into Site_Parameters (Parm_Id,Value,Hostname) Values(@ParmId,@Value,'')
  End
Else
  Update Site_Parameters Set Value = @Value Where (Parm_Id = @ParmId) And (((Hostname = '') Or (Hostname = @MyHostname)))
