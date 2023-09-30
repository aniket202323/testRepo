CREATE view SDK_V_PAProductionPlanStatus
as
select
Production_Plan_Statuses.PP_Status_Id as Id,
Production_Plan_Statuses.PP_Status_Desc as ProductionPlanStatus,
Production_Plan_Statuses.Allow_Edit as AllowEdit,
Production_Plan_Statuses.Movable as Movable,
Production_Plan_Statuses.Color_Id as ColorId,
Color_Src.Color_Desc as Color
from Production_Plan_Statuses
 Left Join Colors Color_Src on Color_Src.Color_Id = Production_Plan_Statuses.Color_Id 
