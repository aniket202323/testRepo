CREATE PROCEDURE dbo.spEM_RenameReasonTreeHeader
  @EventReasonLevel_Id      int,
  @Description nVarChar(100),
  @User_Id int
 AS
  DECLARE @Insert_Id Int,@Sql nvarchar(2000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameReasonTreeHeader',
                Convert(nVarChar(10),@EventReasonLevel_Id) + ','  + 
                @Description + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return codes: 0 = Success.
  --
  If Exists (select * from dbo.syscolumns where name = 'Level_Name_Local' and id =  object_id(N'[Event_Reason_Level_Headers]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Event_Reason_Level_Headers Set Level_Name_Global = ''' + replace(@Description,'''','''''') + ''' Where Event_Reason_Level_Header_Id = ' + Convert(nVarChar(10),@EventReasonLevel_Id)
     Else
 	  	 Select @Sql =  'Update Event_Reason_Level_Headers Set Level_Name_Local = ''' + replace(@Description,'''','''''') + ''' Where Event_Reason_Level_Header_Id = ' + Convert(nVarChar(10),@EventReasonLevel_Id)
 	 End
  Else
 	 Select @Sql =  'Update Event_Reason_Level_Headers Set Level_Name = ''' + replace(@Description,'''','''''') + ''' Where Event_Reason_Level_Header_Id = ' + Convert(nVarChar(10),@EventReasonLevel_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
