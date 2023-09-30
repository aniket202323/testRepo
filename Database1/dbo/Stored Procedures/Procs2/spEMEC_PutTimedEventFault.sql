Create Procedure dbo.spEMEC_PutTimedEventFault
  @PU_Id           	  	 int,
  @TEFault_Id      	 int,
  @Source_PU_Id    	 int,
  @Tree_Id 	  	 Int,
  @TEFault_Name    	 nVarChar(100),
  @TEFault_Value   	 nVarChar(25),
  @Reason_Level1   	 nVarChar(100),
  @Reason_Level2   	 nVarChar(100),
  @Reason_Level3   	 nVarChar(100),
  @Reason_Level4   	 nVarChar(100),
  @User_Id  	  	 int
AS
Declare @Insert_Id int, @Sql nvarchar(1000)
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_PutTimedEventFault',
             Isnull(Convert(nVarChar(10),@PU_Id),'null') + ','  + 
             Isnull(Convert(nVarChar(10),@TEFault_Id),'null') + ','  + 
             Isnull(Convert(nVarChar(10),@Tree_Id),'null') + ','  + 
 	 Isnull(@TEFault_Name ,'null')+ ',' +
 	 Isnull(@TEFault_Value,'null') + ',' +
 	 Isnull(@Reason_Level1,'null') + ',' +
 	 Isnull(@Reason_Level2,'null') + ',' +
 	 Isnull(@Reason_Level3,'null') + ',' +
 	 Isnull(@Reason_Level4,'null') + ',' +
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
  --
  -- insert - IF TEFault_Id is null
  -- update - IF TEFault_Id not null and Source_PU_Id not null
  -- Begin a transaction.
  --
  --
  -- 
  --
     DECLARE @Reason1  int,
             @Reason2   	 int,
             @Reason3   	 int,
             @Reason4   	 int,
 	  	  	  	  	  	  @ReasonId1 	 Int,
 	  	  	  	  	  	  @ReasonId2 	 Int,
 	  	  	  	  	  	  @ReasonId3 	 Int,
 	  	  	  	  	  	  @ReasonId4 	 Int,
 	  	  	  	  	  	  @Event_Reason_Tree_Data_Id Int
--
-- Look up Event_Reason_Tree_Data_Id's
--
If @Reason_Level1 <> '' and @Reason_Level1 is not null 
   Select @ReasonId1 = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data  ertd
 	 Join Event_Reasons e  on ertd.Event_Reason_Id = e.Event_Reason_Id
 	 Where  Tree_Name_Id = @Tree_Id
 	   and Event_Reason_Level = 1
 	   and Event_Reason_Name = @Reason_Level1
Else Select  @ReasonId1 = null
If @Reason_Level2 <> '' and @Reason_Level2 is not null 
   Select @ReasonId2 = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data  ertd
 	 Join Event_Reasons e  on ertd.Event_Reason_Id = e.Event_Reason_Id
 	 Where  Tree_Name_Id = @Tree_Id
 	   and Event_Reason_Level = 2
 	   and Event_Reason_Name = @Reason_Level2
 	   and Parent_Event_R_Tree_Data_Id = @ReasonId1
Else Select @ReasonId2 = null
If @Reason_Level3 <> '' and @Reason_Level3 is not null 
   Select @ReasonId3 = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data  ertd
 	 Join Event_Reasons e  on ertd.Event_Reason_Id = e.Event_Reason_Id
 	 Where  Tree_Name_Id = @Tree_Id
 	   and Event_Reason_Level =3
 	   and Event_Reason_Name = @Reason_Level3
 	   and Parent_Event_R_Tree_Data_Id = @ReasonId2
Else Select @ReasonId3 = null
If @Reason_Level4 <> '' and @Reason_Level4 is not null 
   Select @ReasonId4 = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data  ertd
 	 Join Event_Reasons e  on ertd.Event_Reason_Id = e.Event_Reason_Id
 	 Where  Tree_Name_Id = @Tree_Id
 	   and Event_Reason_Level = 4
 	   and Event_Reason_Name = @Reason_Level4
 	   and Parent_Event_R_Tree_Data_Id = @ReasonId3
Else Select @ReasonId4 = null
  --
  -- look up reasons
  --
Select @Event_Reason_Tree_Data_Id = Coalesce(@ReasonId4,@ReasonId3,@ReasonId2,@ReasonId1)
SELECT @Reason1 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @ReasonId1
SELECT @Reason2 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @ReasonId2
SELECT @Reason3 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @ReasonId3
SELECT @Reason4 = Event_Reason_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @ReasonId4
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
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
