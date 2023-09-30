/* This sp is called by dbo.spBatch_GetSingleVariable parameters need to stay in sync*/
/* This sp is called by dbo.spBatch_CheckEventTable parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreatePUG
  @Description nvarchar(50),
  @PU_Id 	  	 int,
  @PUG_Order 	 int,
  @User_Id  	  	 int,
  @PUG_Id 	  	 int OUTPUT AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create production group.
  --
  DECLARE @Insert_Id integer ,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreatePUG',
                 Isnull(@Description,'Null') + ',' +  Isnull(convert(nVarChar(10),@PU_Id),'Null') + ','  +  Isnull(Convert(nVarChar(10), @PUG_Order),'Null') + ','  +  Isnull(Convert(nVarChar(10), @User_Id),'Null'),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If Exists (select * from dbo.syscolumns where name = 'PUG_Desc_Local' and id =  object_id(N'[PU_Groups]'))
 	 Select @Sql =  'INSERT INTO PU_Groups(PUG_Desc_Local, PU_Id, PUG_Order)'
  Else
 	 Select @Sql =  'INSERT INTO PU_Groups(PUG_Desc, PU_Id, PUG_Order)'
  Select @Sql = @Sql + ' VALUES(''' + replace(@Description,'''','''''') + ''',' + Convert(nVarChar(10),@PU_Id) + ',' + Convert(nVarChar(10),@PUG_Order) + ')'
  Execute(@Sql)
  SELECT @PUG_Id = PUG_Id From PU_Groups Where PUG_Desc = @Description and PU_Id = @PU_Id
  IF @PUG_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
  If Exists (select * from dbo.syscolumns where name = 'PUG_Desc_Local' and id =  object_id(N'[PU_Groups]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update PU_Groups set PUG_Desc_Global = PUG_Desc_Local where PUG_Id = ' + Convert(nVarChar(10),@PUG_Id)
   	  	 Execute (@Sql)
 	   End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PUG_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
