CREATE PROCEDURE dbo.spEM_CreateReasonTreeHeader
  @TreeName_Id int,
  @Level_Name nVarChar(100),
  @User_Id int,
  @Event_Reason_Level_Id int OUTPUT 
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create Reason Level
  --
  DECLARE @Insert_Id integer ,@Reason_Level int,@Sql nvarchar(2000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateReasonTreeHeader',
                 convert(nVarChar(10),@TreeName_Id) + ','  + @Level_Name + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @Reason_level = MAX(Reason_level) + 1 FROM Event_Reason_Level_Headers
          WHERE Tree_Name_Id = @TreeName_Id 
  IF @Reason_level IS NULL  SELECT @Reason_level = 1
  If Exists (select * from dbo.syscolumns where name = 'Level_Name_Local' and id =  object_id(N'[Event_Reason_Level_Headers]'))
 	 Select @Sql =  'INSERT INTO Event_Reason_Level_Headers(Level_Name_Local,Tree_Name_Id,Reason_Level)'
  Else
 	 Select @Sql =  'INSERT INTO Event_Reason_Level_Headers(Level_Name,Tree_Name_Id,Reason_Level)'
  Select @Sql = @Sql + ' VALUES(''' + replace(@Level_Name,'''','''''') + ''',' + Convert(nVarChar(10),@TreeName_Id) + ',' +  Convert(nVarChar(10),@Reason_level) + ')'
  Execute(@Sql)
  SELECT @Event_Reason_Level_Id = Event_Reason_Level_Header_Id From Event_Reason_Level_Headers Where Tree_Name_Id = @TreeName_Id And Level_Name = @Level_Name And Reason_Level = @Reason_level
  IF @Event_Reason_Level_Id IS NULL
 	 BEGIN
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
 	 END
  If Exists (select * from dbo.syscolumns where name = 'Level_Name_Local' and id =  object_id(N'[Event_Reason_Level_Headers]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update Event_Reason_Level_Headers set Level_Name_Global = Level_Name_Local where Event_Reason_Level_Header_Id = ' + Convert(nVarChar(10),@Event_Reason_Level_Id)
   	  	 Execute (@Sql)
 	   End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Event_Reason_Level_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
