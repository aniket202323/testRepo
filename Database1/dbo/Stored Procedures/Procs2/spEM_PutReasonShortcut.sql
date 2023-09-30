Create Procedure dbo.spEM_PutReasonShortcut
  @PU_Id          int,
  @RS_Id          int,
  @App_Id         int,
  @Source_PU_Id   int,
  @Shortcut_Name  nvarchar(25),
  @Amount         real,
  @Reason_Level1  nVarChar(100),
  @Reason_Level2  nVarChar(100),
  @Reason_Level3  nVarChar(100),
  @Reason_Level4  nVarChar(100),
  @User_Id               int
AS
  --
  -- insert - IF RsId is null
  -- update - IF RsId not null and source Id not null
  -- delete - IF RsId not null and source Id is null 
  --
  --
     DECLARE @Reason1  int,
             @Reason2  int,
             @Reason3  int,
             @Reason4  int
  DECLARE @Insert_Id integer, @Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutReasonShortcut',
                Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@RS_Id) + ','  + 
 	  	 Convert(nVarChar(10),@App_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Source_PU_Id) + ','  + 
 	  	 @Shortcut_Name + ','  + 
 	  	 Convert(nVarChar(10),@Amount) + ','  + 
 	  	 Convert(nVarChar(10),@Reason_Level1) + ','  + 
 	  	 Convert(nVarChar(10),@Reason_Level2) + ','  + 
 	  	 Convert(nVarChar(10),@Reason_Level3) + ','  + 
 	  	 Convert(nVarChar(10),@Reason_Level4) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
BEGIN TRANSACTION
  --
  -- look up reasons
  --
SELECT @Reason1 = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @Reason_Level1
SELECT @Reason2 = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @Reason_Level2
SELECT @Reason3 = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @Reason_Level3
SELECT @Reason4 = Event_Reason_Id FROM Event_Reasons WHERE Event_Reason_Name = @Reason_Level4
IF @RS_Id IS NULL 
  Begin
  If Exists (select * from dbo.syscolumns where name = 'Shortcut_Name_Local' and id =  object_id(N'[Reason_Shortcuts]'))
 	   Select @Sql = 'INSERT Reason_Shortcuts (App_Id,PU_Id,Shortcut_Name_Local,Amount,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4) Values ('
  Else
    Begin
 	  	   Select @Sql = 'INSERT Reason_Shortcuts (App_Id,PU_Id,Shortcut_Name,Amount,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4) Values ('
 	   End
 	   Select @Sql = @Sql + Convert(nVarChar(10), @app_Id) + ',' + Coalesce(Convert(nVarChar(10), @PU_Id),'Null') + ',''' + @Shortcut_Name + ''',' + Coalesce(Convert(nVarChar(10), @Amount), 'Null')
 	   Select @Sql = @Sql + ',' + Coalesce(Convert(nVarChar(10), @Source_PU_Id),'Null') + ',' + Coalesce(Convert(nVarChar(10), @Reason1), 'Null')
 	   Select @Sql = @Sql + ',' + Coalesce(Convert(nVarChar(10), @Reason2), 'Null') + ',' + Coalesce(Convert(nVarChar(10), @Reason3), 'Null') + ',' + Coalesce(Convert(nVarChar(10), @Reason4), 'Null') + ')'
    Exec (@Sql)
  End
ELSE IF @Source_PU_Id IS NOT NULL
  Begin
 	   If Exists (select * from dbo.syscolumns where name = 'WEMT_Name_Local' and id =  object_id(N'[Waste_Event_Meas]'))
 	  	  	 Begin
 	  	  	   If (@@Options & 512) = 0
          Begin
 	  	  	  	  	   Select @Sql = 'UPDATE Reason_Shortcuts SET App_Id = ' + Convert(nVarChar(10),@App_Id) + ' ,PU_Id = ' + Coalesce(Convert(nVarChar(10),@PU_Id),'Null') + ' ,Shortcut_Name_Global = ''' + @Shortcut_Name + ''''
 	  	  	  	     Select @Sql = @Sql + ' ,Amount = ' + Coalesce(Convert(nVarChar(10),@Amount), 'Null') + ' ,Source_PU_Id = ' + Coalesce(Convert(nVarChar(10),@Source_PU_Id), 'Null')
 	  	  	  	     Select @Sql = @Sql + ' ,Reason_Level1 = ' + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ' ,Reason_Level2 = ' + Coalesce(Convert(nVarChar(10),@Reason2),'Null')
 	  	  	  	     Select @Sql = @Sql + ' ,Reason_Level3 = ' + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ' ,Reason_Level4 = ' + Coalesce(Convert(nVarChar(10),@Reason4),'Null')
 	  	  	  	  	   Select @Sql = @Sql + ' WHERE RS_Id = ' + Convert(nVarChar(10),@RS_Id)
          End
 	  	     Else
          Begin
 	  	  	  	  	   Select @Sql = 'UPDATE Reason_Shortcuts SET App_Id = ' + Convert(nVarChar(10),@App_Id) + ' ,PU_Id = ' + Coalesce(Convert(nVarChar(10),@PU_Id),'Null') + ' ,Shortcut_Name_Local = ''' + @Shortcut_Name + ''''
 	  	  	  	     Select @Sql = @Sql + ' ,Amount = ' + Coalesce(Convert(nVarChar(10),@Amount), 'Null') + ' ,Source_PU_Id = ' + Coalesce(Convert(nVarChar(10),@Source_PU_Id), 'Null')
 	  	  	  	     Select @Sql = @Sql + ' ,Reason_Level1 = ' + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ' ,Reason_Level2 = ' + Coalesce(Convert(nVarChar(10),@Reason2),'Null')
 	  	  	  	     Select @Sql = @Sql + ' ,Reason_Level3 = ' + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ' ,Reason_Level4 = ' + Coalesce(Convert(nVarChar(10),@Reason4),'Null')
 	  	  	  	  	   Select @Sql = @Sql + ' WHERE RS_Id = ' + Convert(nVarChar(10),@RS_Id)
          End
 	  	  	 End
 	   Else
      Begin
 	  	  	   Select @Sql = 'UPDATE Reason_Shortcuts SET App_Id = ' + Convert(nVarChar(10),@App_Id) + ' ,PU_Id = ' + Coalesce(Convert(nVarChar(10),@PU_Id),'Null') + ' ,Shortcut_Name = ''' + @Shortcut_Name + ''''
 	  	     Select @Sql = @Sql + ' ,Amount = ' + Coalesce(Convert(nVarChar(10),@Amount), 'Null') + ' ,Source_PU_Id = ' + Coalesce(Convert(nVarChar(10),@Source_PU_Id), 'Null')
 	  	     Select @Sql = @Sql + ' ,Reason_Level1 = ' + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ' ,Reason_Level2 = ' + Coalesce(Convert(nVarChar(10),@Reason2),'Null')
 	  	     Select @Sql = @Sql + ' ,Reason_Level3 = ' + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ' ,Reason_Level4 = ' + Coalesce(Convert(nVarChar(10),@Reason4),'Null')
 	  	  	   Select @Sql = @Sql + ' WHERE RS_Id = ' + Convert(nVarChar(10),@RS_Id)
      End
 	   Execute(@Sql)
  End
ELSE
  DELETE Reason_Shortcuts WHERE RS_Id = @RS_Id
  --
   COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
