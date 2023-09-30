Create Procedure dbo.spEM_PutTimedEventFault
  @PU_Id          int,
  @TEFault_Id     int,
  @Source_PU_Id   int,
  @TEFault_Name   nVarChar(100),
  @TEFault_Value  nvarchar(25),
  @Reason_Level1  int,
  @Reason_Level2  int,
  @Reason_Level3  int,
  @Reason_Level4  int,
  @User_Id int
AS
/******************************************************/
/******* #### CALLED FROM EVENT MANAGER ALSO #### *****/
/******************************************************/
  DECLARE @Insert_Id integer, @Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTimedEventFault',
                SUBSTRING(Convert(nVarChar(10),@PU_Id) + ','  + 
                Convert(nVarChar(10),@TEFault_Id) + ','  + 
                Convert(nVarChar(10),@Source_PU_Id) + ','  + 
                LTRIM(RTRIM(@TEFault_Name)) + ','  + 
                LTRIM(RTRIM(@TEFault_Value)) + ','  + 
                Convert(nVarChar(10),@Reason_Level1) + ','  + 
                Convert(nVarChar(10),@Reason_Level2) + ','  + 
                Convert(nVarChar(10),@Reason_Level3) + ','  + 
                Convert(nVarChar(10),@Reason_Level4) + ','  + 
                Convert(nVarChar(10),@User_Id),1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- insert - IF TEFault_Id is null
  -- update - IF TEFault_Id not null and Source_PU_Id not null
  -- delete - IF TEFault_Id not null and Source_PU_Id is null 
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
SELECT @Reason1 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level1
SELECT @Reason2 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level2
SELECT @Reason3 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level3
SELECT @Reason4 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @Reason_Level4
Select @Event_Reason_Tree_Data_Id = Coalesce(@Reason_Level4,@Reason_Level3,@Reason_Level2,@Reason_Level1)
IF @TEFault_Id IS NULL
  BEGIN 
 	   If Exists (select * from dbo.syscolumns where name = 'TEFault_Name_Local' and id =  object_id(N'[Timed_Event_Fault]'))
      Begin
   	  	   Select @Sql = 'INSERT Timed_Event_Fault (PU_Id,TEFault_Name_Local,TEFault_Value,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id) Values('
 	  	  	 End
 	   Else
 	     Begin
 	  	  	   Select @Sql = 'INSERT Timed_Event_Fault (PU_Id,TEFault_Name,TEFault_Value,Source_PU_Id,Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id) Values('
 	  	   End
    Select @Sql = @Sql + Convert(nVarChar(10),@PU_Id) + ',''' + @TEFault_Name + ''',''' + @TEFault_Value + ''',' + Coalesce(Convert(nVarChar(10),@Source_PU_Id),'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ',' + Coalesce(Convert(nVarChar(10),@Reason2), 'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ',' + Coalesce(Convert(nVarChar(10),@Reason4), 'Null') + ','
    Select @Sql = @Sql + Coalesce(Convert(nVarChar(10),@Event_Reason_Tree_Data_Id), 'Null') + ')'
    Exec (@Sql)
  END
ELSE
  BEGIN
    IF @Source_PU_Id IS NOT NULL
      BEGIN
     	   If Exists (select * from dbo.syscolumns where name = 'TEFault_Name_Local' and id =  object_id(N'[Timed_Event_Fault]'))
          Begin
            If (@@Options & 512) = 0
              Begin
                Select @Sql = 'UPDATE Timed_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',TEFault_Name_Global = ' + '''' + @TEFault_Name + ''',TEFault_Value = ''' + @TEFault_Value + ''','
              End
            Else
              Begin
                Select @Sql = 'UPDATE Timed_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',TEFault_Name_Local = ' + '''' + @TEFault_Name + ''',TEFault_Value = ''' + @TEFault_Value + ''','
              End
 	  	  	  	  	 End
        Else
 	  	  	  	  	 Begin
            Select @Sql = 'UPDATE Timed_Event_Fault SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ',TEFault_Name = ' + '''' + @TEFault_Name + ''',TEFault_Value = ''' + @TEFault_Value + ''','
 	  	  	  	  	 End
          Select @Sql = @Sql + 'Source_PU_Id = ' + Coalesce(Convert(nVarChar(10),@Source_PU_Id), 'Null') + ','
          Select @Sql = @Sql + 'Reason_Level1 = ' + Coalesce(Convert(nVarChar(10),@Reason1), 'Null') + ',Reason_Level2 = ' + Coalesce(Convert(nVarChar(10),@Reason2), 'Null') + ','
          Select @Sql = @Sql + 'Reason_Level3 = ' + Coalesce(Convert(nVarChar(10),@Reason3), 'Null') + ',Reason_Level4 = ' + Coalesce(Convert(nVarChar(10),@Reason4), 'Null') + ','
          Select @Sql = @Sql + 'Event_Reason_Tree_Data_Id = ' + Coalesce(Convert(nVarChar(10),@Event_Reason_Tree_Data_Id), 'Null')
          Select @Sql = @Sql + ' WHERE TEFault_Id = ' + Convert(nVarChar(10),@TEFault_Id)
      Execute (@Sql)
      END
    ELSE
      BEGIN
       UPDATE Timed_Event_Details SET TEFault_Id = NULL WHERE TEFault_Id = @TEFault_Id
       DELETE Timed_Event_Fault WHERE TEFault_Id = @TEFault_Id
      END
  END
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
