CREATE view SDK_V_PAProductionStatus
as
select
Production_Status.ProdStatus_Id as Id,
Production_Status.ProdStatus_Desc as ProductionStatus,
Colors.Color_Desc as Color,
Colors.Color as ColorRGB,
Production_Status.Status_Valid_For_Input as StatusValidForInput,
Production_Status.Count_For_Inventory as CountForInventory,
Production_Status.Count_For_Production as CountForProduction,
Production_Status.Color_Id as ColorId,
Production_Status.LifecycleStage as LifeCycleStage,
production_status.Icon_Id as IconId
FROM Production_Status
 LEFT JOIN Colors ON  Production_Status.Color_Id = Colors.Color_Id
