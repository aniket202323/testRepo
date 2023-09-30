/* ##### spServer_DBMgrUpdActivitiesForTest #####
Description 	 : Updates activities related to the test.
Creation Date 	 : NA
Created By 	 : NA
#### Update History ####
DATE 	  	  	  Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  ----------- 	  	 ------------------- 	  	 --------
*/
CREATE PROCEDURE dbo.spServer_DBMgrUpdActivitiesForTest @TestId BIGINT
AS
BEGIN
    DECLARE @VariableId INT, @EventId INT, @ResultOn DATETIME;
    DECLARE @ActivityIds TABLE(Id             INT,
                               ActivityId     BIGINT,
                               ActivityTypeId INT);
    SELECT @VariableId = Var_Id,
           @EventId = ISNULL(Event_Id, 0),
           @ResultOn = Result_On FROM Tests WHERE Test_Id = @TestId;
WITH SV_Base
     AS (
     SELECT S.Sheet_Id,
            Var_Id,
            Title,
            Title_Var_Order_Id,
            Var_Order,SDO.Value FROM Sheet_Variables S 
 	  	  	 LEFT JOIN Sheet_Display_Options AS SDO ON S.Sheet_Id = SDO.Sheet_Id
                                                           AND SDO.Display_Option_Id = 445
 	  	  	 WHERE 
 	  	  	 --Sheet_Id IN(SELECT Sheet_Id FROM Sheet_Variables WHERE Var_Id = @VariableId)
 	  	  	 Exists (SELECT 1 FROM Sheet_Variables Where Var_Id = @VariableId ANd Sheet_Id = S.Sheet_Id)
 	  	  	 ),
     SV
     AS (
     SELECT S1.Sheet_Id,
            CASE
                WHEN S2.Var_Order = S1.Title_Var_Order_Id
                     AND S2.Sheet_Id = S1.Sheet_Id
                     AND S2.Title IS NOT NULL
                     AND ISNULL(S1.Value, 0) = 1
                THEN S2.Title
                ELSE S1.Title
            END AS Title
            FROM SV_Base AS S1
                 JOIN SV_Base AS S2 ON S2.Sheet_Id = S1.Sheet_Id
                                       AND S1.Var_Id = @VariableId
                                       AND (S2.Var_Order = S1.Title_Var_Order_Id
                                            AND S2.Title IS NOT NULL
                                            OR ISNULL(S2.Title_Var_Order_Id,0) = ISNULL(S1.Title_Var_Order_Id,0)
                                            AND S2.Var_Id = S1.Var_Id
                                            AND S2.Title IS NULL
                                            AND ISNULL(S2.Title_Var_Order_Id,0) = 0)
                 --LEFT JOIN Sheet_Display_Options AS SDO ON S1.Sheet_Id = SDO.Sheet_Id
                 --                                          AND SDO.Display_Option_Id = 445
 	  	  	  	  )
 	  	 ,CTE_Activities As 
 	  	 (
 	  	  	 Select Activity_Id,Activity_Type_Id,Title,KeyId1,Sheet_Id,KeyId from Activities A Where Exists (Select 1 FROM SV_Base Where Sheet_Id = A.Sheet_Id)  
 	  	  	 And activity_status in (1,2)
 	  	  	 UNION
 	  	  	 Select Activity_Id,Activity_Type_Id,Title,KeyId1,Sheet_Id,KeyId from Activities where Keyid1 = @EventId
 	  	  	 --Editing completed activity will allow the percentage calcuation to work
 	  	 )
     INSERT INTO @ActivityIds
     SELECT ROW_NUMBER() OVER(ORDER BY A.Activity_Id DESC),
            A.Activity_Id,
            A.Activity_Type_Id
            FROM CTE_Activities AS A
                 JOIN SV ON SV.Sheet_Id = A.Sheet_Id
                 LEFT JOIN Events AS E ON E.Event_Id = A.KeyId1
                                          AND A.Activity_Type_Id = 2
            WHERE ISNULL(A.Title, '') = ISNULL(SV.Title, '')
                  AND @EventId = CASE
                                     WHEN A.Activity_Type_Id = 1
                                     THEN 0
 	  	  	  	  	  	  	  	  	  WHEN A.Activity_Type_Id IN(4, 5) 
 	  	  	  	  	  	  	  	  	  THEN @EventId
                                     ELSE A.KeyId1
                                 END
                  AND @ResultOn = CASE A.Activity_Type_Id
                                      WHEN 2
                                      THEN E.TimeStamp
                                      ELSE A.KeyId
                                  END
    DECLARE @LoopStart INT= 1, @LoopEnd INT= (SELECT MAX(Id) FROM @ActivityIds)
    DECLARE @ActivityId INT, @ActivityTypeId INT
    WHILE @LoopStart <= @LoopEnd
        BEGIN
            SELECT @ActivityId = ActivityId,
                   @ActivityTypeId = ActivityTypeId FROM @ActivityIds WHERE Id = @LoopStart;
            EXECUTE spServer_DBMgrUpdActivities @ActivityId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL
            SET @LoopStart+=1
        END
END
