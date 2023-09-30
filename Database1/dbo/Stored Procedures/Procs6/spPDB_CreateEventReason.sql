CREATE PROCEDURE dbo.spPDB_CreateEventReason
  @Event_Desc nVarchar (100),
  @Event_Code nVarChar (10),
  @Comment_Required tinyint,
  @User_Id int,
  @EventReason_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create Reason.
  --
DECLARE @Insert_Id integer 
Declare @Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spPDB_CreateEventReason',
                 @Event_Desc + ','  + Coalesce(@Event_Code,'(Null)') + ',' + Convert(nvarchar(1), @Comment_Required) + ','  + Convert(nvarchar(10), @User_Id),
                getdate())
select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
 	 If Exists (select * from sys.syscolumns where name = 'Event_Reason_Name_Local' and id =  object_id(N'[Event_Reasons]'))
 	  	 Select @Sql =  'INSERT INTO Event_Reasons(Event_Reason_Name_Local,Event_Reason_Code,Comment_Required)'
 	 Else
 	  	 Select @Sql =  'INSERT INTO Event_Reasons(Event_Reason_Name,Event_Reason_Code,Comment_Required)'
  Select @Sql = @Sql + ' VALUES(''' + replace(@Event_Desc,'''','''''') + ''',' 
  If @Event_Code is Not null
   	 Select @Sql = @Sql + '''' +  replace(@Event_Code,'''','''''') + ''',' + Convert(nvarchar(10),@Comment_Required) + ')'
  Else
   	 Select @Sql = @Sql + 'null' + ',' + Convert(nvarchar(10),@Comment_Required) + ')'
  Execute(@Sql)
  SELECT @EventReason_Id = Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Event_Desc
  IF @EventReason_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = getdate(),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  If Exists (select * from sys.syscolumns where name = 'Event_Reason_Name_Local' and id =  object_id(N'[Event_Reasons]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update Event_Reasons set Event_Reason_Name_Global = Event_Reason_Name_Local where Event_Reason_Id = ' + Convert(nvarchar(10),@EventReason_Id)
   	  	 Execute (@Sql)
 	   End
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = getdate(),returncode = 0,Output_Parameters = convert(nvarchar(10),@EventReason_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
