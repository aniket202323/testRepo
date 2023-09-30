CREATE PROCEDURE dbo.spEM_RenamePUG
  @PUG_Id      int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id Int,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenamePUG',
                Convert(nVarChar(10),@PUG_Id) + ','  + 
                @Description + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return codes: 0 = Success.
  --
  If Exists (select * from dbo.syscolumns where name = 'PUG_Desc_Local' and id =  object_id(N'[PU_Groups]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update PU_Groups Set PUG_Desc_Global = ''' + replace(@Description,'''','''''') + ''' Where PUG_Id = ' + Convert(nVarChar(10),@PUG_Id)
     Else
 	  	 Select @Sql =  'Update PU_Groups Set PUG_Desc_Local = ''' + replace(@Description,'''','''''') + ''' Where PUG_Id = ' + Convert(nVarChar(10),@PUG_Id)
 	 End
  Else
 	 Select @Sql =  'Update PU_Groups Set PUG_Desc = ''' + replace(@Description,'''','''''') + ''' Where PUG_Id = ' + Convert(nVarChar(10),@PUG_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
