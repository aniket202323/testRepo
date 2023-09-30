Create Procedure dbo.spRC_PreloadByTree
@pTree_Id int
AS
create table #ReasonTree (
  Reason_Level tinyint,
  Parent1 int NULL,
  Parent2 int NULL,
  Parent3 int NULL,
  Reason_ID int,
  Reason_Name nvarchar(100),
  Flags tinyint NULL,
  ParentReasonId int NULL, 
  ParentNodeId int NULL,
  Reason_Level_Update tinyint NULL
)
--Return Header Resultset
Select Tree_Name = (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = @pTree_id),
       Header1 =  (Select Level_Name From Event_Reason_Level_Headers Where Tree_Name_Id = @pTree_id and Reason_Level = 1),
       Header2 =  (Select Level_Name From Event_Reason_Level_Headers Where Tree_Name_Id = @pTree_id and Reason_Level = 2),
       Header3 =  (Select Level_Name From Event_Reason_Level_Headers Where Tree_Name_Id = @pTree_id and Reason_Level = 3),
       Header4 =  (Select Level_Name From Event_Reason_Level_Headers Where Tree_Name_Id = @pTree_id and Reason_Level = 4)
--Get Reason Tree  
insert into #ReasonTree (Reason_Level,Parent1,Parent2,Parent3,Reason_ID,Reason_Name,Flags,ParentReasonId, ParentNodeId, Reason_Level_Update)
  select d.event_reason_level, Null, Null, Null, d.event_reason_id, r.event_reason_name, r.comment_required, d.Parent_Event_Reason_Id, d.Parent_Event_R_Tree_Data_Id, d.event_reason_level
    from event_reason_tree_data d
    join event_reasons r on (d.event_reason_id = r.event_reason_id)
    Where d.tree_name_id = @pTree_Id
--Update Reason Level 4 Parents
Update #ReasonTree 
  Set Parent3 = d.event_reason_id, Reason_Level_Update = 3, ParentNodeId = d.Parent_Event_R_Tree_Data_Id
  From event_reason_tree_data d
  Where d.Event_Reason_Tree_Data_Id = #ReasonTree.ParentNodeId and #ReasonTree.Reason_Level_Update = 4
--Update Reason Level 3 Parents
Update #ReasonTree 
  Set Parent2 = d.event_reason_id,  Reason_Level_Update = 2, ParentNodeId = d.Parent_Event_R_Tree_Data_Id
  From event_reason_tree_data d
  Where d.Event_Reason_Tree_Data_Id = #ReasonTree.ParentNodeId and #ReasonTree.Reason_Level_Update = 3
--Update Reason Level 2 Parents
Update #ReasonTree 
  Set Parent1 = d.event_reason_id
  From event_reason_tree_data d
  Where d.Event_Reason_Tree_Data_Id = #ReasonTree.ParentNodeId and #ReasonTree.Reason_Level_Update = 2
select distinct * from #ReasonTree
  order by Reason_Level ASC, Parent1 ASC, Parent2 ASC, Parent3 ASC, Flags ASC, Reason_Name ASC
drop table #ReasonTree
