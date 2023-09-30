CREATE PROCEDURE dbo.spEM_RenameScheduleStatus
  @PP_Status_Id int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id integer ,@Sql nvarchar(1000) 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameScheduleStatus',
                Convert(nVarChar(10),@PP_Status_Id) + ','  + 
                @Description + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  If Exists (select * from dbo.syscolumns where name = 'PP_Status_Desc_Local' and id =  object_id(N'[Production_Plan_Statuses]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Production_Plan_Statuses Set PP_Status_Desc_Global = ''' + replace(@Description,'''','''''') + ''' Where PP_Status_Id = ' + Convert(nVarChar(10),@PP_Status_Id)
     Else
 	  	 Select @Sql =  'Update Production_Plan_Statuses Set PP_Status_Desc_Local = ''' + replace(@Description,'''','''''') + ''' Where PP_Status_Id = ' + Convert(nVarChar(10),@PP_Status_Id)
 	 End
  Else
 	 Select @Sql =  'Update Production_Plan_Statuses Set PP_Status_Desc = ''' + replace(@Description,'''','''''') + ''' Where PP_Status_Id = ' + Convert(nVarChar(10),@PP_Status_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
