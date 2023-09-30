Create Procedure dbo.spBF_GetReasonTreeByMasterUnit
@pPu_id int,
@TreeType tinyint = 1
AS
/*
Public Enum eReasonTreeTypes
  DowntimeCause = 1
  DowntimeAction = 2
  WasteCause = 3
  WasteAction = 4
  AlarmCause = 5
  AlarmAction = 6
  UDECause = 7
  UDEAction = 8
  ComplaintCause = 9
  ComplaintAction = 10
End Enum
*/
DECLARE @err_message nVarChar(255)
DECLARE @pTree_Id Int = 0
If @TreeType = 1 -- Downtime Cause
  Begin
    Select @pTree_Id = t.Name_Id--, p.pu_id, p.pu_desc, Flags = 0, Tree_Name_Id = t.Name_Id
    From prod_units p
    Join Prod_Events t on t.PU_Id = p.PU_Id and Event_Type = 2 
    where (p.pu_id = @pPu_Id) and 
    timed_event_association > 0 and 
    timed_event_association is not null
    order by master_unit
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
    --Get Reason Tree 
    insert into #ReasonTree(Reason_Level,Parent1,Parent2,Parent3,Reason_ID,Reason_Name,Flags,ParentReasonId, ParentNodeId, Reason_Level_Update)
    select d.event_reason_level, Null, Null, Null, d.event_reason_id, r.event_reason_name, r.comment_required, d.Parent_Event_Reason_Id,     d.Parent_Event_R_Tree_Data_Id, d.event_reason_level
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
    Set Parent2 = d.event_reason_id, Reason_Level_Update = 2, ParentNodeId = d.Parent_Event_R_Tree_Data_Id
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
  End
Else 
  BEGIN 	 
  SET @err_message = ' Tree Type ' + CAST(@TreeType as nVarChar(5)) + ' is currently not supported!'
  RAISERROR (@err_message, 11, 1)
  END
