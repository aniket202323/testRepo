CREATE PROCEDURE dbo.spSDK_GetProdSetupDetailById
 	 @PPSetupDetailId 	  	  	  	  	 INT
AS
SELECT PPSetupDetailId = psd.PP_Setup_Detail_Id,
      PathCode = pep.Path_Code,
 	  	  	 ProcessOrder = pp.Process_Order, 
      PatternCode = ps.Pattern_Code,
      ElementNumber = psd.Element_Number,
      PlantOrderNumber = co.Plant_Order_Number,
 	  	  	 ProdStatus = pss.ProdStatus_Desc, 
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 DimensionX = psd.Target_Dimension_X, 
 	  	  	 DimensionY = psd.Target_Dimension_Y, 
 	  	  	 DimensionZ = psd.Target_Dimension_Z, 
 	  	  	 DimensionA = psd.Target_Dimension_A,
 	  	  	 CommentId = psd.Comment_Id,
 	  	  	 ExtendedInfo = psd.Extended_Info,
  	  	  	 UserGeneral1 = psd.User_General_1,
  	  	  	 UserGeneral2 = psd.User_General_2,
  	  	  	 UserGeneral3 = psd.User_General_3
 	 FROM  PrdExec_Paths pep JOIN
 	  	  	   Production_Plan pp ON pp.Path_Id = pep.Path_Id JOIN
 	       Production_Setup ps ON ps.PP_Id = pp.PP_Id JOIN 
        Production_Setup_Detail psd ON psd.PP_Setup_Id = ps.PP_Setup_Id JOIN
 	  	  	   Production_Status pss ON pss.ProdStatus_Id = psd.Element_Status LEFT OUTER JOIN
       	 Products p ON psd.Prod_Id = p.Prod_Id LEFT OUTER JOIN
        Customer_Order_Line_Items col on col.Order_Line_Id = psd.Order_Line_Id LEFT OUTER JOIN
        Customer_Orders co on co.Order_Id = col.Order_Id
 	 WHERE 	 psd.PP_Setup_Detail_Id = @PPSetupDetailId
