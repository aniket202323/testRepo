Create Procedure dbo.spEM_PutWasteEventFault
  @PU_Id          int,
  @WEFault_Id     int,
  @Source_PU_Id   int,
  @WEFault_Name   nVarChar(100),
  @WEFault_Value  nvarchar(25),
  @Reason_Level1  int,
  @Reason_Level2  int,
  @Reason_Level3  int,
  @Reason_Level4  int,
  @User_Id int
/******************************************************/
/******* #### CALLED FROM EVENT MANAGER ALSO #### *****/
/******************************************************/
AS
  DECLARE @Insert_Id integer, @Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutWasteEventFault',
                SUBSTRING(Convert(nVarChar(10),@PU_Id) + ','  + 
                Convert(nVarChar(10),@WEFault_Id) + ','  + 
                Convert(nVarChar(10),@Source_PU_Id) + ','  + 
                LTRIM(RTRIM(@WEFault_Name)) + ','  + 
                LTRIM(RTRIM(@WEFault_Value)) + ','  + 
                Convert(nVarChar(10),@Reason_Level1) + ','  + 
                Convert(nVarChar(10),@Reason_Level2) + ','  + 
                Convert(nVarChar(10),@Reason_Level3) + ','  + 
                Convert(nVarChar(10),@Reason_Level4) + ','  + 
                Convert(nVarChar(10),@User_Id),1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- insert - IF WEFault_Id is null
  -- update - IF WEFault_Id not null and Source_PU_Id not null
  -- delete - IF WEFault_Id not null and Source_PU_Id is null 
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- 
  --
     DECLARE @Reason1  int,
             @Reason2  int,
             @Reason3  int,
             @Reason4  int,
 	  	  	  @Event_Reason_Tree_Data_Id Int
  --
  -- look up reasons
  --
Select @Event_Reason_Tree_Data_Id = Coalesce(@Reason_Level4,@Reason_Level3,@Reason_Level2,@Reason_Level1)
SELECT @Reason1 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level1
SELECT @Reason2 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level2
SELECT @Reason3 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level3
SELECT @Reason4 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level4
IF @WEFault_Id IS NULL
  BEGIN 
 	   If Exists (select * from dbo.syscolumns where name = 'WEFault_Name_Local' and id =  object_id(N'[Waste_Event_Fault]'))
      Begin
   	  	   Select @Sql = 'INSERT Waste_Event_Fault (PU_Id,WEFault_Name_Local,WEFault_Value,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id) Values('
 	  	  	 End
 	   Else
 	     Begin
 	  	  	   Select @Sql = 'INSERT Waste_Event_Fault (PU_Id,WEFault_Name,WEFault_Value,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id) Values('
 	  	   End
    Select @Sql = @Sql + Convert(nVarChar(10),@PU_Id) + ',''' + @WEFault_Name + ''',''' + @WEFault_Value + ''',' + Coalesce(Convert(nVarChar(10),@Source_PU_Id),'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ',' + Coalesce(Convert(nVarChar(10),@Reason2), 'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ',' + Coalesce(Convert(nVarChar(10),@Reason4), 'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Event_Reason_Tree_Data_Id), 'Null') + ')'
    Exec (@Sql)
  END
ELSE
  BEGIN
    IF @Source_PU_Id IS NOT NULL
      BEGIN
     	   If Exists (select * from dbo.syscolumns where name = 'WEFault_Name_Local' and id =  object_id(N'[Waste_Event_Fault]'))
          Begin
            If (@@Options & 512) = 0
              Begin
                Select @Sql = 'UPDATE Waste_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',WEFault_Name_Global = ' + '''' + @WEFault_Name + ''',WEFault_Value = ''' + @WEFault_Value + ''','
              End
            Else
              Begin
                Select @Sql = 'UPDATE Waste_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',WEFault_Name_Local = ' + '''' + @WEFault_Name + ''',WEFault_Value = ''' + @WEFault_Value + ''','
              End
 	  	  	  	  	 End
        Else
 	  	  	  	  	 Begin
            Select @Sql = 'UPDATE Waste_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',WEFault_Name = ' + '''' + @WEFault_Name + ''',WEFault_Value = ''' + @WEFault_Value + ''','
 	  	  	  	  	 End
          Select @Sql = @Sql + 'Source_PU_Id = ' + Coalesce(Convert(nVarChar(10),@Source_PU_Id), 'Null') + ','
          Select @Sql = @Sql + 'Reason_Level1 = ' + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ',Reason_Level2 = ' + Coalesce(Convert(nVarChar(10),@Reason2), 'Null') + ','
          Select @Sql = @Sql + 'Reason_Level3 = ' + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ',Reason_Level4 = ' + Coalesce(Convert(nVarChar(10),@Reason4), 'Null') + ','
          Select @Sql = @Sql + 'Event_Reason_Tree_Data_Id = ' + Coalesce(Convert(nVarChar(10),@Event_Reason_Tree_Data_Id), 'Null')
          Select @Sql = @Sql + ' WHERE WEFault_Id = ' + Convert(nVarChar(10),@WEFault_Id)
      Execute (@Sql)
      END
    ELSE
      BEGIN
       UPDATE Waste_Event_Details SET WEFault_Id = NULL WHERE WEFault_Id = @WEFault_Id
       DELETE Waste_Event_Fault WHERE WEFault_Id = @WEFault_Id
      END
  END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
