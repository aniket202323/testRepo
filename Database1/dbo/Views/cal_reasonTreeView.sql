-- =============================================
-- Author: 	  	 <502406286, Alfredo Scotto>
-- Create date: <Create Date,,>
-- Description: 	 <Description,,>
-- =============================================
CREATE VIEW dbo.cal_reasonTreeView as
  select d.Event_Reason_Tree_Data_Id as nodeId, null as Parent1, null as Parent2, null as Parent3, 
   r.event_reason_name as Reason_Name, r.comment_required as Flags, 
   d.event_reason_id as Reason_ID, coalesce(d.Parent_Event_Reason_Id,0) as ParentReasonId, d.Parent_Event_R_Tree_Data_Id as ParentNodeId, 
   d.event_reason_level as Reason_Level, d.event_reason_level as Reason_Level_Update,d.tree_name_id as treeNameId
    from event_reason_tree_data d
    join event_reasons r on (d.event_reason_id = r.event_reason_id and d.Level2_Id is null)
UNION
 select d.Event_Reason_Tree_Data_Id as nodeId, d.Level2_Id as Parent1, null as Parent2, null as Parent3, 
  r.event_reason_name as Reason_Name, r.comment_required as Flags, 
  d.event_reason_id as Reason_ID,d.Parent_Event_Reason_Id as ParentReasonId, d.Parent_Event_R_Tree_Data_Id as ParentNodeId, 
  d.event_reason_level as Reason_Level,d.event_reason_level as Reason_Level_Update,d2.tree_name_id as treeNameId
    from event_reason_tree_data d2
    join event_reason_tree_data d on ( d.Parent_Event_R_Tree_Data_Id = d2.Event_Reason_Tree_Data_Id and d.event_reason_level = 2 and d.Level2_Id is not null) 
    join event_reasons r on (d.event_reason_id = r.event_reason_id)
UNION
 select d.Event_Reason_Tree_Data_Id as nodeId, d.Level2_Id as Parent1, d.Level3_Id as Parent2, null as Parent3, 
   r.event_reason_name as Reason_Name, r.comment_required as Flags, 
  d.event_reason_id as Reason_ID,d.Parent_Event_Reason_Id as ParentReasonId, d.Parent_Event_R_Tree_Data_Id as ParentNodeId, 
  d.event_reason_level as Reason_Level,d.event_reason_level as Reason_Level_Update,d2.tree_name_id as treeNameId
    from event_reason_tree_data d2
    join event_reason_tree_data d1 on ( d1.Parent_Event_R_Tree_Data_Id = d2.Event_Reason_Tree_Data_Id  and d1.event_reason_level = 2 and d1.Level2_Id is not null) 
    join event_reason_tree_data d on ( d.Parent_Event_R_Tree_Data_Id = d1.Event_Reason_Tree_Data_Id and d.event_reason_level = 3 and d.Level3_Id is not null) 
    join event_reasons r on (d.event_reason_id = r.event_reason_id)
UNION
 select d.Event_Reason_Tree_Data_Id as nodeId, d.Level2_Id as Parent1, d.Level3_Id as Parent2, d.Level4_Id as Parent3, 
  r.event_reason_name as Reason_Name, r.comment_required as Flags, 
   d.event_reason_id as Reason_ID,d.Parent_Event_Reason_Id as ParentReasonId, d.Parent_Event_R_Tree_Data_Id as ParentNodeId, 
  d.event_reason_level as Reason_Level, d.event_reason_level as Reason_Level_Update,d2.tree_name_id as treeNameId
    from event_reason_tree_data d2
    join event_reason_tree_data d1 on ( d1.Parent_Event_R_Tree_Data_Id = d2.Event_Reason_Tree_Data_Id  and d1.event_reason_level = 2 and d1.Level2_Id is not null) 
    join event_reason_tree_data d3 on ( d1.Parent_Event_R_Tree_Data_Id = d1.Event_Reason_Tree_Data_Id  and d3.event_reason_level = 3 and d3.Level3_Id is not null) 
    join event_reason_tree_data d on ( d.Parent_Event_R_Tree_Data_Id = d3.Event_Reason_Tree_Data_Id  and d.event_reason_level = 4 and d.Level4_Id is not null) 
    join event_reasons r on (d.event_reason_id = r.event_reason_id)
;
