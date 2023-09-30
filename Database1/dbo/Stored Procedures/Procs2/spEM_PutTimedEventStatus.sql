Create Procedure dbo.spEM_PutTimedEventStatus
  @PU_Id          int,
  @TEStatus_Id     int,
  @TEStatus_Name   nVarChar(100),
  @TEStatus_Value  nvarchar(25),
  @User_Id int
AS
  DECLARE @Insert_Id integer, @Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutTimedEventStatus',
    SUBSTRING(Convert(nVarChar(10),@PU_Id) + ','  + 
    Convert(nVarChar(10),@TEStatus_Id) + ','  + 
    LTRIM(RTRIM(@TEStatus_Name)) + ','  + 
    LTRIM(RTRIM(@TEStatus_Value)) + ','  + 
    Convert(nVarChar(10),@User_Id),1,255),
    dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- insert - IF TEStatus_Id is null
  -- update - IF TEStatus_Id not null and PU_Id is not null
  -- delete - IF TEStatus_Id not null and PU_Id is null
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- 
  --
IF @TEStatus_Id IS NULL
  BEGIN 
  If Exists (select * from dbo.syscolumns where name = 'TEStatus_Name_Local' and id =  object_id(N'[Timed_Event_Status]'))
    Select @Sql = 'INSERT Timed_Event_Status (PU_Id, TEStatus_Name_Local, TEStatus_Value) Values(' + Convert(nVarChar(10),@PU_Id) + ',''' + @TEStatus_Name + ''',' + '''' + @TEStatus_Value + ''')'
  Else
    Begin
      Select @Sql = 'INSERT Timed_Event_Status (PU_Id, TEStatus_Name, TEStatus_Value) Values(' + Convert(nVarChar(10),@PU_Id) + ',''' + @TEStatus_Name + ''',' + '''' + @TEStatus_Value + ''')'
 	   End
  END
ELSE
  BEGIN
    IF @PU_Id IS NULL
      BEGIN
        Select @Sql = 'DELETE Timed_Event_Status'
      END
    ELSE
      BEGIN
 	  	  	   If Exists (select * from dbo.syscolumns where name = 'TEStatus_Name_Local' and id =  object_id(N'[Timed_Event_Status]'))
   	  	  	   If (@@Options & 512) = 0
            Begin
              Select @Sql = 'UPDATE Timed_Event_Status SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ' ,TEStatus_Name_Global = ''' + @TEStatus_Name + ''', TEStatus_Value = ''' + @TEStatus_Value + ''''
 	  	  	  	  	  	 End
          Else
            Begin
              Select @Sql = 'UPDATE Timed_Event_Status SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ' ,TEStatus_Name_Local = ''' + @TEStatus_Name + ''', TEStatus_Value = ''' + @TEStatus_Value + ''''
 	  	  	  	  	  	 End
        Else
          Begin
            Select @Sql = 'UPDATE Timed_Event_Status SET PU_Id = ' + Convert(nVarChar(10),@PU_Id) + ' ,TEStatus_Name = ''' + @TEStatus_Name + ''', TEStatus_Value = ''' + @TEStatus_Value + ''''
          End
      END
    Select @Sql = @Sql + ' WHERE TEStatus_Id = ' + Convert(nVarChar(10),@TEStatus_Id)
  END
  COMMIT TRANSACTION
  Execute (@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
    WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
