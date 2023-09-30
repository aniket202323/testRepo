﻿CREATE view SDK_V_PAReasonCategoryData
as
select
Event_Reason_Category_Data.ERCD_Id as Id,
Event_Reason_Category_Data.ERC_Id as ReasonCategoryId,
Event_Reason_Catagories.ERC_Desc as ReasonCategoryName,
Event_Reason_Tree_Data.Tree_Name_Id as ReasonTreeId,
Event_Reason_Tree.Tree_Name as ReasonTreeName,
Event_Reason_Category_Data.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
Event_Reason_Category_Data.Propegated_From_ETDId as PropegatedFromRTDId
FROM Event_Reason_Category_Data
 JOIN Event_Reason_Catagories on Event_Reason_Category_Data.ERC_Id = Event_Reason_Catagories.ERC_Id
 LEFT JOIN Event_Reason_Tree_Data on Event_Reason_Tree_Data.Event_Reason_Tree_Data_Id = Event_Reason_Category_Data.Event_Reason_Tree_Data_Id
 LEFT JOIN Event_Reason_Tree on Event_Reason_Tree.Tree_Name_Id = Event_Reason_Tree_Data.Tree_Name_Id
