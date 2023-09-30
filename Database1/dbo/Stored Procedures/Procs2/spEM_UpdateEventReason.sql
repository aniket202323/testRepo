Create Procedure dbo.spEM_UpdateEventReason
  @ER_Id   int,
  @ER_Name nVarchar (100),
  @ER_Code VarChar (10),
  @Comment_Required TinyInt,
  @User_Id int
  AS
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_UpdateEventReason',
                Coalesce(Convert(nVarChar(10),@ER_Id),'Null') + ','  + Coalesce(@ER_Name,'Null') + ','  +  Coalesce(@ER_Code,'Null') + ','  + 
                Coalesce(Convert(nVarChar(10),@Comment_Required),'Null') + ','  + Coalesce(Convert(nVarChar(10),@User_Id),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  If Exists (select * from dbo.syscolumns where name = 'Event_Reason_Name_Local' and id =  object_id(N'[Event_Reasons]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Event_Reasons Set Event_Reason_Name_Global = ''' + replace(@ER_Name,'''','''''') + ''' Where Event_Reason_Id = ' + Convert(nVarChar(10),@ER_Id)
     Else
 	  	 Select @Sql =  'Update Event_Reasons Set Event_Reason_Name_Local = ''' + replace(@ER_Name,'''','''''') + ''' Where Event_Reason_Id = ' + Convert(nVarChar(10),@ER_Id)
 	 End
  Else
 	 Select @Sql =  'Update Event_Reasons Set Event_Reason_Name = ''' + replace(@ER_Name,'''','''''') + ''' Where Event_Reason_Id = ' + Convert(nVarChar(10),@ER_Id)
  Execute(@Sql)
  UPDATE Event_Reasons SET  Event_Reason_Code = @ER_Code,
                            Comment_Required = @Comment_Required
    WHERE Event_Reason_Id = @ER_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
