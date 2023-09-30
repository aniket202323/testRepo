﻿-- spXLA_BuildActionList. Generate reason list based on event type, (tree) level, specified tree, and specified parent.
-- ECR #25336: mt/4-7-2003: Alarm code change for readability and performance
-- ECR #27896: mt/5-5-2004: Search Action: add Event Type "User-Defined Event"
--
CREATE PROCEDURE dbo.spXLA_BuildActionList
 	   @Event_Type 	 Int
 	 , @SelectLevel 	 Int
 	 , @SelectTree 	 Int
 	 , @SelectParent 	 Int
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
CREATE TABLE #ListItems (
 	   ItemName Varchar(100)
 	 , ItemId   Int          NULL
 	 , TreeId   Int          NULL
 	 , NodeId   Int          NULL 
 	 )
-- *** Build Location as reason list  ****************************************************** ---
If @SelectLevel = 0 	  	 
  BEGIN
    If @Event_Type = 2 	  	 --Downtime
      BEGIN
        INSERT INTO #ListItems (ItemName, ItemId)
             SELECT PU_Desc, PU_Id FROM Prod_Units 
              WHERE (PU_Id = @SelectParent OR Master_Unit = @SelectParent) AND Timed_Event_Association > 0
        UPDATE #ListItems
        SET TreeId = (SELECT Action_Tree_Id FROM Prod_Events WHERE PU_Id = #ListItems.ItemId AND Event_Type = @Event_Type)     
      END
    Else If @Event_Type = 3 	 --Waste
      BEGIN
        INSERT INTO #ListItems (ItemName, ItemId)
             SELECT PU_Desc, PU_Id FROM Prod_Units
              WHERE (PU_Id = @SelectParent OR Master_Unit = @SelectParent) AND Waste_Event_Association > 0
        UPDATE #ListItems
        SET TreeId = (SELECT Action_Tree_Id FROM Prod_Events WHERE PU_Id = #ListItems.ItemId AND Event_Type = @Event_Type)     
      END
    Else If @Event_Type = 11 	 --Alarm
      BEGIN
        INSERT INTO #ListItems (ItemName, ItemId)
             SELECT DISTINCT pu.PU_Desc, pu.Pu_Id 
 	        FROM Prod_Units pu
               JOIN Alarms a ON a.Source_Pu_Id = pu.Pu_Id AND a.Alarm_Type_Id = 1 
              WHERE pu.PU_Id = @SelectParent OR pu.Master_Unit = @SelectParent
        UPDATE #ListItems
        SET TreeId = (SELECT TOP 1 t.Action_Tree_Id 
                        FROM Alarm_Templates t
                        JOIN Alarm_Template_Var_data d ON d.AT_Id = t.AT_Id
                        JOIN Alarms a ON a.ATD_Id = d.ATD_Id AND a.Source_Pu_Id = @SelectParent
                      )
      END
    Else If @Event_Type = 14 	 --ECR #27896: mt/5-5-2004: Search Action: add Event Type "User-Defined Event"
      BEGIN
        INSERT INTO #ListItems(ItemName, ItemId, TreeId)
          SELECT DISTINCT es.Event_Subtype_Desc, ec.Event_Subtype_Id, es.Action_Tree_Id
            FROM Event_Configuration ec 
            JOIN Event_Subtypes es ON es.Event_Subtype_Id = ec.Event_Subtype_Id
           WHERE ec.Event_Subtype_Id Is NOT NULL AND ec.ET_Id = 14 AND ec.PU_Id = @SelectParent AND es.Action_Required = 1
        ORDER BY es.Event_Subtype_Desc
      END
    --EndIf @Event_Type = ...
  END
-- **** Build list of R1's, whose immediate parent is tree root **************************** ---
Else If @SelectLevel = 1 	 
  BEGIN
    INSERT INTO #ListItems (ItemName, ItemId, NodeId, TreeId)
         SELECT r.Event_Reason_Name, r.Event_Reason_Id, rd.Event_Reason_Tree_Data_Id, @SelectTree
           FROM Event_Reason_Tree_Data rd
           JOIN Event_Reasons r ON r.Event_Reason_Id = rd.Event_Reason_Id
          WHERE rd.Tree_Name_Id = @SelectTree AND rd.Event_Reason_Level = @SelectLevel    
  END
--*** (@SelectLevel> 1) Build list of R2, R3, R4 whose immediate parent Is NOT tree root *** ---
Else  	  	  	  	 
  BEGIN
    INSERT INTO #ListItems (ItemName, ItemId, NodeId, TreeId)
         SELECT r.Event_Reason_Name, r.Event_Reason_Id, rd.Event_Reason_Tree_Data_Id, @SelectTree
           FROM Event_Reason_Tree_Data rd
           JOIN Event_Reasons r ON r.Event_Reason_Id = rd.Event_Reason_Id
          WHERE rd.Tree_Name_Id = @SelectTree 
            AND rd.Event_Reason_Level = @SelectLevel 
            AND rd.Parent_Event_R_Tree_Data_Id = @SelectParent   
 	         -- Need Parent_Event_R_Tree_Data_Id as immediate parent is not tree root
  END
--EndIf @SelectLevel ....
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
SELECT * FROM #ListItems ORDER BY ItemName 
DROP TABLE #ListItems
