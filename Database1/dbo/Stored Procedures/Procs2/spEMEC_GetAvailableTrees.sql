Create Procedure dbo.spEMEC_GetAvailableTrees
@User_Id int
AS
 select Name=tree_name,Levels =coalesce((select Max(Event_Reason_Level) from event_reason_tree_Data where Tree_Name_Id = ert.Tree_Name_Id),0)  , Header1 = h1.level_name,Header2 = h2.level_name,Header3 = h3.level_name,Header4 = h4.level_name, 
  ert.Tree_Name_Id
    From event_reason_tree ert
    left Join event_reason_level_headers h1 on ert.tree_name_Id = h1.Tree_Name_Id and h1.reason_level = 1
    left Join event_reason_level_headers h2 on ert.tree_name_Id = h2.Tree_Name_Id and h2.reason_level = 2
    left Join event_reason_level_headers h3 on ert.tree_name_Id = h3.Tree_Name_Id and h3.reason_level = 3
    left Join event_reason_level_headers h4 On ert.tree_name_Id = h4.Tree_Name_Id and h4.reason_level = 4
