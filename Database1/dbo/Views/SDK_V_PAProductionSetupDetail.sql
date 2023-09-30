CREATE view SDK_V_PAProductionSetupDetail
as
select
Production_Setup_Detail.PP_Setup_Detail_Id as Id,
Production_Setup_Detail.Element_Number as ElementNumber,
Prdexec_Paths.Path_Code as PathCode,
Production_Plan.Process_Order as ProcessOrder,
Customer_Orders.Plant_Order_Number as PlantOrderNumber,
Production_Setup.Pattern_Code as PatternCode,
Production_Setup_Detail.Target_Dimension_X as DimensionX,
Production_Setup_Detail.Target_Dimension_Y as DimensionY,
Production_Setup_Detail.Target_Dimension_Z as DimensionZ,
Production_Setup_Detail.Target_Dimension_A as DimensionA,
Products.Prod_Code as ProductCode,
Production_Setup_Detail.Comment_Id as CommentId,
Production_Setup_Detail.Extended_Info as ExtendedInfo,
Production_Setup_Detail.User_General_1 as UserGeneral1,
Production_Setup_Detail.User_General_2 as UserGeneral2,
Production_Setup_Detail.User_General_3 as UserGeneral3,
Comments.Comment_Text as CommentText,
Production_Plan.Path_Id as PathId,
Production_Setup_Detail.Element_Status as ElementStatusId,
Production_Setup_Detail.Order_Line_Id as CustomerOrderLineId,
Production_Setup_Detail.PP_Setup_Id as ProductionSetupId,
Production_Setup_Detail.Prod_Id as ProductId,
Production_Setup.PP_Id as ProductionPlanId
FROM PrdExec_Paths
 JOIN Production_Plan ON Production_Plan.Path_Id = PrdExec_Paths.Path_Id
 JOIN Production_Setup ON Production_Setup.PP_Id = Production_Plan.PP_Id
 JOIN Production_Setup_Detail ON Production_Setup_Detail.PP_Setup_Id = Production_Setup.PP_Setup_Id
 LEFT OUTER JOIN Products ON Production_Setup_Detail.Prod_Id = Products.Prod_Id
 LEFT OUTER JOIN Customer_Order_Line_Items on Customer_Order_Line_Items.Order_Line_Id = Production_Setup_Detail.Order_Line_Id
 LEFT OUTER JOIN Customer_Orders on Customer_Orders.Order_Id = Customer_Order_Line_Items.Order_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=production_setup_detail.Comment_Id
