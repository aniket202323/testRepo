Create Procedure dbo.spServer_CmnUpdateExtendedInfo
@Id int,
@Extended_Info nVarChar(255),
@Table nVarChar(100)
AS
If (@Table = 'Events')
  Begin
    Update Events Set Extended_Info = @Extended_Info Where Event_Id = @Id
  End
