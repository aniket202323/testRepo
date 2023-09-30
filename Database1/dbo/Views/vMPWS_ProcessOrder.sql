
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_ProcessOrder
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
CREATE view [dbo].[vMPWS_ProcessOrder] as
		SELECT
			plC.PL_Id PreweighLineId,
			plC.PL_Desc PreweighDesc,
			ppC.Path_Id PreweighPathId,
			ppC.Process_Order PreweighPO,
			ppsC.PP_Status_Desc PreweighPOStatus,
			ppC.PP_Id PreweighPPId,
			ppC.BOM_Formulation_Id PreweighBOMF_Id,
			psC.Pattern_Code PreweighBatchNum,
			tfv1.Value PreweighPOPriority,
 
			plP.PL_Id ProdLineId,
			plP.PL_Desc ProdLineDesc,
			ppP.Path_Id ProdLinePathId,
			ppP.Process_Order ProdLinePO,
			ppsP.PP_Status_Desc ProdLinePOStatus,
			ppP.PP_Id ProdLinePPId,
			ppP.BOM_Formulation_Id ProdLineBOMF_Id,
			psP.Pattern_Code ProdLineBatchNum
		FROM dbo.Production_Plan ppC														-- child / pre-weigh
		
			JOIN dbo.Production_Plan_Statuses ppsC ON ppsC.PP_Status_Id = ppC.PP_Status_Id
			JOIN dbo.Production_Setup psC ON psC.PP_Id = ppC.PP_Id
			JOIN dbo.PrdExec_Paths pepC ON pepC.Path_Id = ppC.Path_Id
			JOIN dbo.Prod_Lines_Base plC ON plC.PL_Id = pepC.PL_Id
            JOIN dbo.Departments_Base AS dc ON dc.Dept_Id = plc.Dept_Id 
				AND dc.Dept_Desc = 'Pre-weigh'
			JOIN dbo.Tables AS t ON t.TableName = 'Production_Plan' 
			JOIN dbo.Table_Fields AS tf1 ON tf1.Table_Field_Desc = 'PreWeighProcessOrderPriority' 
				AND tf1.TableId = t.TableId 
			LEFT OUTER JOIN dbo.Table_Fields_Values AS tfv1 ON tfv1.KeyId = ppC.PP_Id
				AND tfv1.TableId = t.TableId 
				AND tfv1.Table_Field_Id = tf1.Table_Field_Id
                      
			LEFT JOIN dbo.Production_Plan ppP ON ppP.PP_Id = ppC.Source_PP_Id				-- parent / making line
			LEFT JOIN dbo.Production_Setup psP ON psP.PP_Id = ppP.PP_Id
			LEFT JOIN dbo.Production_Plan_Statuses ppsP ON ppsP.PP_Status_Id = ppP.PP_Status_Id
			LEFT JOIN dbo.PrdExec_Paths pep ON pep.Path_Id = ppP.Path_Id
			LEFT JOIN dbo.Prod_Lines_Base plP ON pep.PL_Id = plP.PL_Id

