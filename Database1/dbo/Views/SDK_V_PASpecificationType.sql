﻿CREATE view SDK_V_PASpecificationType
as
select
Specification_Types.Specification_Type_Id as Id,
Specification_Types.Specification_Type_Name as SpecificationType
from Specification_Types
