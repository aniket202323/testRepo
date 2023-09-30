CREATE view SDK_V_PAReasonTree
as
select
Event_Reason_Tree.Tree_Name_Id as Id,
Event_Reason_Tree.Tree_Name as ReasonTreeName,
h1.Level_Name as Level1HdrName,
h2.Level_Name as Level2HdrName,
h3.Level_Name as Level3HdrName,
h4.Level_Name as Level4HdrName,
event_reason_tree.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
FROM Event_Reason_Tree 
LEFT
 JOIN Event_Reason_Level_Headers h1 ON (Event_Reason_Tree.Tree_Name_Id = h1.Tree_Name_Id AND h1.Reason_Level = 1) 
LEFT
 JOIN Event_Reason_Level_Headers h2 ON (Event_Reason_Tree.Tree_Name_Id = h2.Tree_Name_Id AND h2.Reason_Level = 2) 
LEFT
 JOIN Event_Reason_Level_Headers h3 ON (Event_Reason_Tree.Tree_Name_Id = h3.Tree_Name_Id AND h3.Reason_Level = 3) 
LEFT
 JOIN Event_Reason_Level_Headers h4 ON (Event_Reason_Tree.Tree_Name_Id = h4.Tree_Name_Id AND h4.Reason_Level = 4)
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = event_reason_tree.Group_Id 
