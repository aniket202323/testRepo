﻿CREATE view SDK_V_PAPathInputPosition
as
select
PrdExec_Input_Positions.PEIP_Id as Id,
PrdExec_Input_Positions.PEIP_Desc as PathInputPosition
from PrdExec_Input_Positions