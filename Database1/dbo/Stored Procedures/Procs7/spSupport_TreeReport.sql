Create Procedure dbo.spSupport_TreeReport
@TN_Id int
AS
DECLARE @L1_Id  int,
        @L2_Id  int,
        @L3_Id  int,
        @L4_Id  int,
        @L1 VarChar(25),
        @L2 VarChar(25),
        @L3 VarChar(25),
        @L4 VarChar(25),
        @OL1 VarChar(25),
        @OL2 VarChar(25),
        @OL3 VarChar(25),
        @OL4 VarChar(25)
CREATE TABLE #TreeResults(
                  L1  Integer NOT NULL,
                  L2  Integer NULL,
                  L3  Integer NULL,
                  L4  Integer NULL)
SELECT Event_reason_Tree_Data_Id INTO #L1 FROM Event_Reason_Tree_Data Where Tree_Name_Id = @TN_Id And Parent_Event_R_Tree_Data_Id Is Null
DECLARE L1_Cursor CURSOR
 FOR SELECT Event_Reason_Tree_Data_Id FROM #L1
 FOR READ ONLY
 OPEN L1_Cursor 
NextL1:
  FETCH NEXT FROM L1_Cursor INTO @L1_Id
IF (@@Fetch_Status = 0)
  BEGIN
      SELECT Event_reason_Tree_Data_Id INTO #L2 FROM Event_Reason_Tree_Data Where Parent_Event_R_Tree_Data_Id = @L1_Id
      DECLARE L2_Cursor CURSOR
       FOR SELECT Event_Reason_Tree_Data_Id FROM #L2
       FOR READ ONLY
       OPEN L2_Cursor 
      NextL2:
        FETCH NEXT FROM L2_Cursor INTO @L2_Id
        IF (@@Fetch_Status = 0)
            BEGIN
               SELECT Event_reason_Tree_Data_Id INTO #L3 FROM Event_Reason_Tree_Data Where Parent_Event_R_Tree_Data_Id = @L2_Id
               DECLARE L3_Cursor CURSOR
                FOR SELECT Event_Reason_Tree_Data_Id FROM #L3
                FOR READ ONLY
                OPEN L3_Cursor 
               NextL3:
                 FETCH NEXT FROM L3_Cursor INTO @L3_Id
                 IF (@@Fetch_Status = 0)
                    BEGIN
                      SELECT Event_reason_Tree_Data_Id INTO #L4 FROM Event_Reason_Tree_Data Where Parent_Event_R_Tree_Data_Id = @L3_Id
                      DECLARE L4_Cursor CURSOR 
                       FOR SELECT Event_Reason_Tree_Data_Id FROM #L4
                       FOR READ ONLY
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
 	                      DROP TABLE #L4
                             GOTO NextL3
                           END 
                    END
                  ELSE
                    BEGIN
                      INSERT INTO #TreeResults(L1,L2) (SELECT @L1_Id,Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
                         WHERE Event_Reason_Tree_Data_Id = @L2_Id AND @L2_Id NOT IN
                         (SELECT Parent_Event_R_Tree_Data_Id From Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id in(SELECT * From #L3)))
                      DEALLOCATE L3_Cursor
 	               DROP TABLE #L3
                      GOTO NextL2
                    END 
             END
         ELSE
           BEGIN
             INSERT INTO #TreeResults(L1) (SELECT Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
                WHERE Event_Reason_Tree_Data_Id = @L1_Id AND @L1_Id NOT IN
                (SELECT Parent_Event_R_Tree_Data_Id From Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id in(SELECT * From #L2)))
             DEALLOCATE L2_Cursor
             drop Table #L2
             GOTO NextL1
           END
  END
DEALLOCATE L1_Cursor
drop Table #L1
select @OL1 = null
select @OL2 = null
select @OL3 = null
select @OL4 = null
CREATE TABLE #PrintResults(
                  RL1  VarChar(25)  NULL,
                  RL2  VarChar(25)  NULL,
                  RL3  VarChar(25)  NULL,
                  RL4  VarChar(25)  NULL)
DECLARE Print_Cursor CURSOR
 FOR SELECT Level1 = SUBSTRING(e1.Event_Reason_Name,1,25),
       Level2 = SUBSTRING(e2.Event_Reason_Name,1,25),
       Level3 = SUBSTRING(e3.Event_Reason_Name,1,25),
       Level4 = SUBSTRING(e4.Event_Reason_Name,1,25)
    FROM  #TreeResults
    Left Join event_reason_tree_Data etd on etd.Event_Reason_Tree_Data_Id = L1
    Left Join event_reason_tree_Data etd2 on etd2.Event_Reason_Tree_Data_Id = L2
    Left Join event_reason_tree_Data etd3 on etd3.Event_Reason_Tree_Data_Id = L3
    Left Join event_reason_tree_Data etd4 on etd4.Event_Reason_Tree_Data_Id = L4
    Left Join Event_Reasons e1 on etd.event_Reason_Id = e1.event_Reason_Id 
    Left Join Event_Reasons e2 on etd2.event_Reason_Id = e2.event_Reason_Id 
    Left Join Event_Reasons e3 on etd3.event_Reason_Id = e3.event_Reason_Id 
    Left Join Event_Reasons e4 on etd4.event_Reason_Id = e4.event_Reason_Id
    order by level1,level2,level3,level4
 FOR READ ONLY
 OPEN Print_Cursor 
NextPrint:
  FETCH NEXT FROM Print_Cursor INTO @L1,@L2,@L3,@L4
IF (@@Fetch_Status = 0)
   BEGIN
    IF @L1 <> @OL1
       BEGIN  
         INSERT #PrintResults (RL1,RL2,RL3,RL4) Values(@L1,
                 CASE 
                    WHEN @L2 is null THEN ' '
                    ELSE @L2
                 END,
                 CASE 
                    WHEN @L3 is null THEN ' '
                    ELSE @L3
                 END,
                 CASE 
                    WHEN @L4 is null THEN ' '
                    ELSE @L4
                 END)
         SELECT @OL1 = @L1
         SELECT @OL2 = @L2
         SELECT @OL3 = @L3
         SELECT @OL4 = @L4
       END
    ELSE IF @L2 <> @OL2
          BEGIN  
            INSERT #PrintResults (RL1,RL2,RL3,RL4) Values(' ',@L2,
                 CASE 
                    WHEN @L3 is null THEN ' '
                    ELSE @L3
                 END,
                 CASE 
                    WHEN @L4 is null THEN ' '
                    ELSE @L4
                 END)
            SELECT @OL2 = @L2
            SELECT @OL3 = @L3
            SELECT @OL4 = @L4
          END
          ELSE IF @L3 <> @OL3
                BEGIN  
                  INSERT #PrintResults (RL1,RL2,RL3,RL4) Values(' ',' ',@L3,
                    CASE 
                       WHEN @L4 is null THEN ''
                       ELSE @L4
                    END)
                  SELECT @OL3 = @L3
                  SELECT @OL4 = @L4
                END
               ELSE 
                BEGIN     
                  INSERT #PrintResults (RL1,RL2,RL3,RL4) Values(' ',' ',' ',@L4)
                END
       GOTO NextPrint
     END
DEALLOCATE Print_Cursor
select * from #PrintResults
DROP TABLE #TreeResults
DROP TABLE #PrintResults
