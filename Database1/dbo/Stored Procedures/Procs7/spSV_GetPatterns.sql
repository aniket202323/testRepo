Create Procedure [dbo].[spSV_GetPatterns]
@PP_Setup_Id int
AS
DECLARE 	  @PPId 	  Int
DECLARE  @PathId Int
DECLARE  @UnitStart TABLE(PuId Int)
DECLARE @GoodAndBad TABLE (Good Int,Bad Int,PPSetupDetailId Int)
SELECT @PPId = a.PP_Id  From Production_Setup  a WHERE a.PP_Setup_Id = @PP_Setup_Id
SELECT @PathId = Path_Id FROM Production_Plan WHERE PP_Id = @PPId
INSERT INTO @UnitStart(PuId)
   	 SELECT DISTINCT PU_Id
  	    	 FROM PrdExec_Path_units 
  	    	 WHERE Is_Production_Point = 1 AND Path_Id = @PathId 
INSERT INTO @GoodAndBad(Good,Bad,PPSetupDetailId)
 	 SELECT  coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 1 then 1 ELSE 0 end),0),
 	  	  	 coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 0 then 1 ELSE 0 end),0),
 	  	  	 psd.PP_Setup_Detail_Id 
 	 FROM Production_Setup_Detail psd
  	 LEFT JOIN  	  Event_details ed ON psd.PP_Setup_Detail_Id = ed.PP_Setup_Detail_Id and ed.initial_dimension_x is not null
  	 LEFT JOIN  	  Events e on ed.event_id = e.event_id 	  	  	 
  	 LEFT JOIN  	  production_status s on s.prodstatus_id = e.event_status
  	 LEFT JOIN  	  @UnitStart us ON us.PuId = e.PU_Id 
 	 WHERE  	  	 psd.PP_Setup_Id = @PP_Setup_Id 	  	  	 
 	 GROUP BY psd.PP_Setup_Detail_Id
UPDATE @GoodAndBad SET Good = Coalesce(Good,0), Bad = Coalesce(Bad,0)
Select psd.PP_Setup_Detail_Id, psd.Comment_Id, psd.Element_Number, psd.Element_Status, 
    'Good_Items' = Good, 
    'Bad_Items' = Bad,
    psd.Target_Dimension_X, 
 	 psd.Target_Dimension_Y, 
 	 psd.Target_Dimension_Z, 
 	 psd.Target_Dimension_A, 
 	 Total_Target_Dimension_X = (Select Sum(Target_Dimension_X) From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id), 
    Total_Target_Dimension_Y = (Select Sum(Target_Dimension_Y) From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id), 
    Total_Target_Dimension_Z = (Select Sum(Target_Dimension_Z) From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id), 
    Total_Target_Dimension_A = (Select Sum(Target_Dimension_A) From Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id), 
    psd.Order_Line_Id, 
 	 co.Plant_Order_Number, 
 	 c.Customer_Code, 
 	 co.Order_Instructions, 
    'Production_Setup_Detail_Prod_Id' = psd.Prod_Id , 
 	 'Customer_Order_Line_Items_Prod_Id' = psd.Prod_Id, 
    psd.User_General_1, 
 	 psd.User_General_2, 
 	 psd.User_General_3,
 	 psd.Extended_Info
  From Production_Setup_Detail psd
  Left Outer Join Customer_Order_Line_Items col on col.Order_Line_Id = psd.Order_Line_Id
  Left Outer Join Customer_Orders co on co.Order_Id = col.Order_Id
  Left Outer Join Customer c on c.Customer_ID = co.Customer_Id
  LEFT JOIN @GoodAndBad a on a.PPSetupDetailId = psd.PP_Setup_Detail_Id
  Where psd.PP_Setup_Id = @PP_Setup_Id
