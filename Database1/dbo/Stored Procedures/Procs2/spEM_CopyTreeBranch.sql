CREATE PROCEDURE dbo.spEM_CopyTreeBranch
@From_Id int,
@To_Id   int,
@User_Id int,
@TreeId  int = null
AS
DECLARE @L1_Id  int,
        @L2_Id  int,
        @L3_Id  int,
        @L4_Id  int,
        @PrevL1_Id  int,
        @PrevL2_Id  int,
        @PrevL3_Id  int,
        @PrevL4_Id  int,
 	 @NewEventId int,
 	 @NewEventId2 int,
 	 @NewEventId3 int,
 	 @Insert_Id integer,
 	 @DoFlag as bit
Declare @Level int,@ReasonId int,@RC int,@NewLevel int
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CopyTreeBranch',
                 convert(nVarChar(10),@From_Id) + ','  + Convert(nVarChar(10), @To_Id) + ','  + Convert(nVarChar(10), @User_Id) + ','  + Convert(nVarChar(10), @TreeId) ,
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
CREATE TABLE #Results(  Tree_Name_Id  Integer NOT NULL,
                   	 Event_Reason_Tree_Data_Id  Integer NULL,
                   	 Event_Reason_Id  Integer NULL,
                   	 Event_Reason_Level Integer NULL,
 	  	  	 Parent_Event_R_Tree_Data_Id Integer NULL)
IF @TreeId IS NOT NULL AND @To_Id IS NULL
    BEGIN
 	 SELECT @Level = 1
 	 SELECT @ReasonId = Event_Reason_Id
          FROM Event_Reason_Tree_Data
 	   WHERE Event_Reason_Tree_Data_Id = @From_Id
        EXECUTE @RC = spem_CreateEventReasonData @TreeId,@ReasonId,@To_Id,@Level,@User_Id,@To_Id  Output
 	 IF @RC = 0
 	  	 INSERT INTO #Results  (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	   VALUES(@TreeId,@To_Id,@ReasonId,@Level,null)
 	 ELSE
 	     BEGIN
 	  	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	  	 Select * from #Results
 	  	 RETURN(1)
 	    END
    END
ELSE
    IF @TreeId IS NULL AND @To_Id IS NOT NULL
 	 BEGIN
 	   SELECT @TreeId = Tree_Name_Id,@Level = Event_Reason_Level
 	     FROM Event_Reason_tree_Data
 	     WHERE Event_reason_Tree_data_id = @To_Id
 	   SELECT @Level = @Level + 1
 	   SELECT @ReasonId = Event_Reason_Id
                  FROM Event_Reason_Tree_Data
 	        WHERE Event_Reason_Tree_Data_Id = @From_Id
                EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@To_Id,@Level,@User_Id,@NewEventId  Output
 	    IF @RC = 0
 	     BEGIN
 	    	 INSERT INTO #Results  (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	                   VALUES(@TreeId,@NewEventId,@ReasonId,@Level,@To_Id)
 	    	 SELECT @To_Id = @NewEventId
 	    	 SELECT @NewEventId = null
 	      END
 	    ELSE
 	  	 BEGIN
 	  	     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = @RC where Audit_Trail_Id = @Insert_Id
 	  	     Select * from #Results
 	  	     RETURN(@RC)
 	  	 END
 	 END
    ELSE
      BEGIN
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 3 where Audit_Trail_Id = @Insert_Id
 	 Select * from #Results
 	 RETURN(3)
      END
CREATE TABLE #TreeResults(
                  L1  Integer NOT NULL,
                  L2  Integer NULL,
                  L3  Integer NULL,
                  L4  Integer NULL)
CREATE TABLE #L1(Event_reason_Tree_Data_Id int NOT NULL)
CREATE TABLE #L2(Event_reason_Tree_Data_Id int NOT NULL)
CREATE TABLE #L3(Event_reason_Tree_Data_Id int NOT NULL)
CREATE TABLE #L4(Event_reason_Tree_Data_Id int NOT NULL)
INSERT INTO #L1 SELECT Event_reason_Tree_Data_Id 
                 FROM Event_Reason_Tree_Data 
                 WHERE Event_Reason_Tree_Data_Id = @From_Id
EXECUTE ('DECLARE L1_Cursor CURSOR Global ' +
 'FOR SELECT Event_Reason_Tree_Data_Id FROM #L1 ' +
 'FOR READ ONLY')
 OPEN L1_Cursor 
NextL1:
  FETCH NEXT FROM L1_Cursor INTO @L1_Id
IF (@@Fetch_Status = 0)
  BEGIN
      INSERT INTO #L2 SELECT Event_reason_Tree_Data_Id 
                       FROM Event_Reason_Tree_Data 
                       WHERE Parent_Event_R_Tree_Data_Id = @L1_Id and Event_reason_Tree_Data_Id <> @To_Id
      EXECUTE('DECLARE L2_Cursor CURSOR Global ' +
       'FOR SELECT Event_Reason_Tree_Data_Id FROM #L2 ' +
       'FOR READ ONLY')
       OPEN L2_Cursor
      NextL2:
        FETCH NEXT FROM L2_Cursor INTO @L2_Id
        IF (@@Fetch_Status = 0)
            BEGIN
               INSERT INTO #L3 SELECT Event_reason_Tree_Data_Id 
                                 FROM Event_Reason_Tree_Data 
                                 WHERE Parent_Event_R_Tree_Data_Id = @L2_Id and Event_reason_Tree_Data_Id <> @To_Id
               EXECUTE('DECLARE L3_Cursor CURSOR Global ' +
                'FOR SELECT Event_Reason_Tree_Data_Id FROM #L3 ' +
                'FOR READ ONLY')
                OPEN L3_Cursor 
               NextL3:
                 FETCH NEXT FROM L3_Cursor INTO @L3_Id
                 IF (@@Fetch_Status = 0)
                    BEGIN
                      INSERT INTO #L4 SELECT Event_Reason_Tree_Data_Id 
                                      FROM Event_Reason_Tree_Data 
                                      WHERE Parent_Event_R_Tree_Data_Id = @L3_Id  and Event_reason_Tree_Data_Id <> @To_Id
                      EXECUTE('DECLARE L4_Cursor CURSOR Global ' +
                       'FOR SELECT Event_Reason_Tree_Data_Id FROM #L4 ' +
                       'FOR READ ONLY')
                       OPEN L4_Cursor 
                       NextL4:
                        FETCH NEXT FROM L4_Cursor INTO @L4_Id
                        IF (@@Fetch_Status = 0)
                           BEGIN
 	  	              INSERT INTO #TreeResults(L1,L2,L3,L4) Values(@L1_Id,@L2_Id,@L3_Id,@L4_Id)
                             GOTO NextL4
                           END
                        ELSE
                           BEGIN
                             INSERT INTO #TreeResults(L1,L2,L3) (SELECT @L1_Id,@L2_Id,Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
                                WHERE Event_Reason_Tree_Data_Id = @L3_Id AND @L3_Id NOT IN
                            (SELECT Parent_Event_R_Tree_Data_Id From Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id in(SELECT * From #L4)))
                             DEALLOCATE L4_Cursor
 	                      DELETE #L4
                             GOTO NextL3
                           END 
                    END
                  ELSE
                    BEGIN
                      INSERT INTO #TreeResults(L1,L2) (SELECT @L1_Id,Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
                         WHERE Event_Reason_Tree_Data_Id = @L2_Id AND @L2_Id NOT IN
                         (SELECT Parent_Event_R_Tree_Data_Id From Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id in(SELECT * From #L3)))
                      DEALLOCATE L3_Cursor
 	               DELETE #L3
                      GOTO NextL2
                    END 
             END
         ELSE
           BEGIN
             INSERT INTO #TreeResults(L1) (SELECT Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
                WHERE Event_Reason_Tree_Data_Id = @L1_Id AND @L1_Id NOT IN
                (SELECT Parent_Event_R_Tree_Data_Id From Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id in(SELECT * From #L2)))
             DEALLOCATE L2_Cursor
             DELETE #L2
             GOTO NextL1
           END
  END
DEALLOCATE L1_Cursor
DROP TABLE #L1
DROP TABLE #L2
DROP TABLE #L3
DROP TABLE #L4
SELECT @PrevL1_Id = null,@PrevL2_Id = null,@PrevL3_Id = null,@PrevL4_Id = null,@NewEventId = @To_Id
EXECUTE('DECLARE Insert_Cursor CURSOR Global ' +
 'FOR SELECT L1,L2,L3,L4 FROM #TreeResults ' +
 'ORDER BY L1,L2,L3,L4 ' +
 'FOR READ ONLY')
 OPEN Insert_Cursor
NextInsert:
  FETCH NEXT FROM Insert_Cursor INTO @L1_Id,@L2_Id,@L3_Id,@L4_Id
IF (@@Fetch_Status = 0)
  BEGIN
 	 Select @DoFlag = 0
 	 If @PrevL2_Id Is Null and @L2_Id IS NOT NULL
 	     Select @DoFlag = 1
 	 Else If @L2_Id IS NOT NULL and @PrevL2_Id Is Not Null
                       If  @PrevL2_Id <> @L2_Id Select @DoFlag = 1
 	       If @DoFlag = 1
-- 	 IF @PrevL2_Id <> @L2_Id AND @L2_Id IS NOT NULL 
 	  	 BEGIN
 	  	       SELECT @ReasonId = Event_Reason_Id
                                   FROM Event_Reason_Tree_Data
 	  	  	  WHERE Event_Reason_Tree_Data_Id = @L2_Id
 	  	       Select @NewLevel = @Level + 1
 	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@To_Id,@NewLevel,@User_Id,@NewEventId  Output
 	  	       IF @RC = 0
 	  	  	       INSERT INTO #Results (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	 VALUES(@TreeId,@NewEventId,@ReasonId,@NewLevel,@To_Id)
 	  	       IF @L3_Id IS NOT NULL
 	  	  	 BEGIN
 	  	  	       SELECT @ReasonId = Event_Reason_Id
 	                          FROM Event_Reason_Tree_Data
 	  	  	  	  WHERE Event_Reason_Tree_Data_Id = @L3_Id
 	  	  	       Select @NewLevel = @Level + 2
 	  	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@NewEventId,@NewLevel,@User_Id,@NewEventId2  Output
 	  	  	       IF @RC = 0
 	  	  	  	       INSERT INTO #Results(Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	  	  VALUES(@TreeId,@NewEventId2,@ReasonId,@NewLevel,@NewEventId)
 	  	  	       IF @L4_Id IS NOT NULL
 	  	  	  	 BEGIN
 	  	  	  	       SELECT @ReasonId = Event_Reason_Id
 	                  	          FROM Event_Reason_Tree_Data
 	  	  	  	  	  WHERE Event_Reason_Tree_Data_Id = @L4_Id
 	  	  	  	       Select @NewLevel = @Level + 3
 	  	  	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@NewEventId2,@NewLevel,@User_Id,@NewEventId3  Output
 	  	  	  	       IF @RC = 0
 	  	  	  	        	       INSERT INTO #Results (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	  	  	 VALUES(@TreeId,@NewEventId3,@ReasonId,@NewLevel,@NewEventId2)
 	  	  	  	 END
 	  	  	 END
 	  	       SELECT @PrevL1_Id = @L1_Id,@PrevL2_Id = @L2_Id,@PrevL3_Id = @L3_Id,@PrevL4_Id = @L4_Id
 	  	       GOTO NextInsert
 	  	 END
 	  	 Select @DoFlag = 0
 	  	 If @PrevL3_Id Is Null and @L3_Id IS NOT NULL
 	  	     Select @DoFlag = 1
 	  	 Else If @L3_Id IS NOT NULL and @PrevL3_Id Is Not Null
 	                        If  @PrevL3_Id <> @L3_Id Select @DoFlag = 1
 	       If @DoFlag = 1
-- 	 IF @PrevL3_Id <> @L3_Id AND @L3_Id IS NOT NULL
 	  	 BEGIN
 	  	       SELECT @ReasonId = Event_Reason_Id
                         FROM Event_Reason_Tree_Data
 	  	  	  WHERE Event_Reason_Tree_Data_Id = @L3_Id
 	  	       Select @NewLevel = @Level + 2
 	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@NewEventId,@NewLevel,@User_Id,@NewEventId2  Output
 	  	       IF @RC = 0
 	  	  	       INSERT INTO #Results (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	 VALUES(@TreeId,@NewEventId2,@ReasonId,@NewLevel,@NewEventId)
 	  	       IF @L4_Id IS NOT NULL
 	  	  	 BEGIN
 	  	  	       SELECT @ReasonId = Event_Reason_Id
                 	          FROM Event_Reason_Tree_Data
 	  	  	  	  WHERE Event_Reason_Tree_Data_Id = @L4_Id
 	  	  	       Select @NewLevel = @Level + 3
 	  	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@NewEventId2,@NewLevel,@User_Id,@NewEventId3  Output
 	  	  	       IF @RC = 0
 	  	  	        	 INSERT INTO #Results (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	  	 VALUES(@TreeId,@NewEventId3,@ReasonId,@NewLevel,@NewEventId2)
 	  	  	 END
 	  	  	 SELECT @PrevL1_Id = @L1_Id,@PrevL2_Id = @L2_Id,@PrevL3_Id = @L3_Id,@PrevL4_Id = @L4_Id
 	  	  	 GOTO NextInsert
 	  	 END
 	 Select @DoFlag = 0
 	 If @PrevL4_Id Is Null and @L4_Id IS NOT NULL
 	     Select @DoFlag = 1
 	 Else If @L4_Id IS NOT NULL and @PrevL4_Id Is Not Null
                       If  @PrevL4_Id <> @L4_Id Select @DoFlag = 1
 	       If @DoFlag = 1
-- 	 IF @PrevL4_Id <> @L4_Id AND @L4_Id IS NOT NULL
 	  	 BEGIN
 	  	       SELECT @ReasonId = Event_Reason_Id
                	          FROM Event_Reason_Tree_Data
 	  	  	  WHERE Event_Reason_Tree_Data_Id = @L4_Id
 	  	       Select @NewLevel = @Level + 3
 	  	       EXECUTE @Rc = spem_CreateEventReasonData @TreeId,@ReasonId,@NewEventId2,@NewLevel,@User_Id,@NewEventId3  Output
 	  	       IF @RC = 0
 	  	        	 INSERT INTO #Results (Tree_Name_Id,Event_Reason_Tree_Data_Id,Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id)
 	  	  	  	 VALUES(@TreeId,@NewEventId3,@ReasonId,@NewLevel,@NewEventId2)
 	  	 END
 	 SELECT @PrevL1_Id = @L1_Id,@PrevL2_Id = @L2_Id,@PrevL3_Id = @L3_Id,@PrevL4_Id = @L4_Id
 	 GOTO NextInsert
  END
DEALLOCATE Insert_Cursor
DROP TABLE #TreeResults
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode =0 where Audit_Trail_Id = @Insert_Id
SELECT  Tree_Name_Id,Event_Reason_Tree_Data_Id,r.Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id,Event_Reason_Name
      FROM  #Results r
      Join Event_Reasons e on r.Event_Reason_Id = e.Event_Reason_Id
      WHERE Tree_Name_Id = @TreeId
      ORDER BY Event_Reason_Level
DROP TABLE #Results
Return (0)
