﻿CREATE view SDK_V_PAResearchStatus
as
select
Research_Status.Research_Status_Id as Id,
Research_Status.Research_Status_Desc as ResearchStatus
from Research_Status
