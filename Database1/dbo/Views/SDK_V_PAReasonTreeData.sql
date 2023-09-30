CREATE view SDK_V_PAReasonTreeData
as
select
Event_Reason_Tree_Data.Tree_Name_Id as ReasonTreeId,
Event_Reason_Tree.Tree_Name as ReasonTreeName,
reason1.Event_Reason_Name as ReasonLevel1,
reason2.Event_Reason_Name as ReasonLevel2,
reason3.Event_Reason_Name as ReasonLevel3,
reason4.Event_Reason_Name as ReasonLevel4,
Event_Reason_Tree_Data.Level1_Id as ReasonLevel1Id,
Event_Reason_Tree_Data.Level2_Id as ReasonLevel2Id,
Event_Reason_Tree_Data.Level3_Id as ReasonLevel3Id,
Event_Reason_Tree_Data.Level4_Id as ReasonLevel4Id,
Event_Reason_Tree_Data.Event_Reason_Tree_Data_Id as Id,
Event_Reason_Tree_Data.Parent_Event_R_Tree_Data_Id as ParentReasonTreeDataId,
Event_Reason_Tree_Data.Event_Reason_Id as ReasonId,
Event_Reasons.Event_Reason_Name as Reason,
Event_Reason_Tree_Data.Event_Reason_Level as ReasonLevel,
Event_Reason_Tree_Data.Parent_Event_Reason_Id as ParentReasonId,
parentreason.Event_Reason_Name as ParentReason,
Event_Reason_Category_Data.ERCD_Id as ReasonCategoryDataId,
Event_Reason_Category_Data.ERC_Id as ReasonCategoryId,
Event_Reason_Catagories.ERC_Desc as ReasonCategoryName,
event_reason_tree_data.Bottom_Of_Tree as BottomOfTree,
event_reason_tree_data.Comment_Required as CommentRequired,
event_reason_tree_data.ERT_Data_Order as ERTDataOrder
FROM Event_Reason_Tree_Data
 JOIN Event_Reason_Tree on Event_Reason_Tree.Tree_Name_Id = Event_Reason_Tree_Data.Tree_Name_Id
 LEFT OUTER JOIN Event_Reasons on Event_Reason_Tree_Data.Event_Reason_Id = Event_Reasons.Event_Reason_Id
 LEFT OUTER JOIN Event_Reasons reason1 on Event_Reason_Tree_Data.Level1_Id = reason1.Event_Reason_Id
 LEFT OUTER JOIN Event_Reasons reason2 on Event_Reason_Tree_Data.Level2_Id = reason2.Event_Reason_Id
 LEFT OUTER JOIN Event_Reasons reason3 on Event_Reason_Tree_Data.Level3_Id = reason3.Event_Reason_Id
 LEFT OUTER JOIN Event_Reasons reason4 on Event_Reason_Tree_Data.Level4_Id = reason4.Event_Reason_Id
 LEFT JOIN Event_Reasons parentreason on Event_Reason_Tree_Data.parent_event_reason_Id = parentreason.Event_Reason_Id
 LEFT JOIN Event_Reason_Category_Data on Event_Reason_Tree_Data.Event_Reason_Tree_Data_Id = Event_Reason_Category_Data.Event_Reason_Tree_Data_Id
 LEFT JOIN Event_Reason_Catagories on Event_Reason_Category_Data.ERC_Id = Event_Reason_Catagories.ERC_Id
