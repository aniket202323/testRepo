﻿CREATE view SDK_V_PAProductionPlanType
as
select
Production_Plan_Types.PP_Type_Id as Id,
Production_Plan_Types.PP_Type_Name as ProductionPlanType
from Production_Plan_Types
