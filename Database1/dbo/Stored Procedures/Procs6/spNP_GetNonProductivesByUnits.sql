-- spNP_GetNonProductivesByUnits() update the date field specified. Because we don't allow records time range to overlap. An update
-- that leads to an overlap of time range in existing records will need user permission to override and eliminate existing records
-- which is done on application module. If the permission is granted this stored procedure execute the update and deleting existing 
-- records that are 'in the way'
--
CREATE PROCEDURE dbo.spNP_GetNonProductivesByUnits
 	   @UnitString1 	 Varchar(8000)
 	 , @UnitString2 	 Varchar(8000)
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
AS
DECLARE @PU_Id         Int
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
-- Make Temp table for selected units
CREATE TABLE #Temp_ID (ID integer)
INSERT  #Temp_ID EXECUTE spNP_IDsFromString @UnitString1, @UnitString2
SELECT pu.PU_Desc
/*   Reason_Name replaced with Reason_Path: ECR 31917: mt/5-31-2006
     , [Reason_Name]  = CASE WHEN d.Reason_Level1 IS NOT NULL THEN R1.Event_Reason_Name
                             WHEN d.Reason_Level2 IS NOT NULL THEN R2.Event_Reason_Name
                             WHEN d.Reason_Level3 IS NOT NULL THEN R3.Event_Reason_Name
                             WHEN d.Reason_Level4 IS NOT NULL THEN R4.Event_Reason_Name
                        END
*/
     , [Reason_Level] = CASE WHEN d.Reason_Level1 IS NOT NULL THEN 1
                             WHEN d.Reason_Level2 Is NOT NULL THEN 2
                             WHEN d.Reason_Level3 Is NOT NULL THEN 3
                             WHEN d.Reason_Level4 Is NOT NULL THEN 4
                        END
     , [Reason_Path] = CASE WHEN d.Reason_Level1 IS NOT NULL AND d.Reason_Level2 IS NOT NULL AND d.Reason_Level3 IS NOT NULL AND d.Reason_Level4 IS NOT NULL
                              THEN R1.Event_Reason_Name + '\' +  R2.Event_Reason_Name + '\' +  R3.Event_Reason_Name + '\' +  R4.Event_Reason_Name
                            WHEN d.Reason_Level1 IS NOT NULL AND d.Reason_Level2 IS NOT NULL AND d.Reason_Level3 IS NOT NULL 
                              THEN R1.Event_Reason_Name + '\' +  R2.Event_Reason_Name + '\' +  R3.Event_Reason_Name 
                            WHEN d.Reason_Level1 IS NOT NULL AND d.Reason_Level2 IS NOT NULL 
                              THEN R1.Event_Reason_Name + '\' +  R2.Event_Reason_Name 
                            WHEN d.Reason_Level1 IS NOT NULL
                              THEN R1.Event_Reason_Name
                       END
     , pu.Non_Productive_Reason_Tree 	 -- ECR 32518: 8-15-2006
     , d.* 
  FROM NonProductive_Detail d
  JOIN Prod_Units pu ON pu.PU_Id = d.PU_Id AND pu.PU_Id <> 0 AND pu.Non_Productive_Category = 7
  JOIN #Temp_ID t ON t.ID = d.PU_Id AND d.Start_Time BETWEEN @Start_Time AND @End_Time AND d.End_Time <= @End_Time
  LEFT JOIN Event_Reasons R1 ON R1.Event_Reason_Id = d.Reason_Level1
  LEFT JOIN Event_Reasons R2 ON R2.Event_Reason_Id = d.Reason_Level2
  LEFT JOIN Event_Reasons R3 ON R3.Event_Reason_Id = d.Reason_Level3
  LEFT JOIN Event_Reasons R4 ON R4.Event_Reason_Id = d.Reason_Level4
SELECT @Return_Status = @@Error
SELECT [Return_Status] = @Return_Status
DROP TABLE #Temp_ID
