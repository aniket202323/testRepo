﻿CREATE view SDK_V_PAReasonCategory
as
select
Event_Reason_Catagories.ERC_Id as Id,
Event_Reason_Catagories.ERC_Desc as ReasonCategoryName
FROM Event_Reason_Catagories
