 
 
/*	-------------------------------------------------------------------------------
	dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId
	
	Gets Production Line Info for a PP_Id 
	
	Date			Version		Build	Author  
	29-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
SELECT * FROM dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(390817)
SELECT * FROM dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(390815)
SELECT * FROM dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(390816)
SELECT * FROM dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(390788)
 
 
 
pp_id	process_order	path_id
390817	905045973	29
390815	905045975	29
390816	905049755	29
390818	905049758	29
390822	905045973	32
390819	905045974	32
390821	905045975	32
390820	905049755	32
390823	905049758	32
*/	-------------------------------------------------------------------------------
 
CREATE  FUNCTION [dbo].[fnLocal_MPWS_GetProductionLineInfoByPwPPId] (@PPId INT)
 
RETURNS TABLE
 
AS
 
RETURN (WITH paths AS
		(
			SELECT
				pep.Path_Id
			FROM dbo.Prdexec_Paths pep
				JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
				JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
			WHERE d.Dept_Desc = 'Pre-Weigh'
		)
		SELECT
			COALESCE(pl.PL_Id, plC.PL_Id) ProdLineId,
			COALESCE(pl.PL_Desc, plC.PL_Desc) ProdLineDesc,
			COALESCE(ppP.Path_Id, ppC.Path_Id) ProdLinePathId,
			COALESCE(ppP.Process_Order, ppC.Process_Order) ProdLinePO,
			COALESCE(pps.PP_Status_Desc, ppsC.PP_Status_Desc) ProdLinePOStatus,
			COALESCE(ppP.PP_Id, ppC.PP_Id) ProdLinePPId,
			COALESCE(ppP.BOM_Formulation_Id, ppC.BOM_Formulation_Id) ProdLineBOMF_Id,
			COALESCE(ps.Pattern_Code, psC.Pattern_Code) ProdLineBatchNum
			, COALESCE(StrgLoc.Value, 'Can not Get Value') StorageLocation
			, COALESCE(RecStrgLoc.Value, 'Can not Get Value') ReceivingStorageLocation
			
 
 
			
		FROM dbo.Production_Plan ppC														-- child / pre-weigh
		
			JOIN dbo.Production_Plan_Statuses ppsC ON ppsC.PP_Status_Id = ppC.PP_Status_Id
			JOIN dbo.Production_Setup psC ON psC.PP_Id = ppC.PP_Id
			JOIN dbo.PrdExec_Paths pepC ON pepC.Path_Id = ppC.Path_Id
			JOIN dbo.Prod_Lines_Base plC ON plC.PL_Id = pepC.PL_Id
			
			LEFT JOIN dbo.Production_Plan ppP ON ppP.PP_Id = ppC.Source_PP_Id				-- parent / making line
			LEFT JOIN dbo.Production_Setup ps ON ps.PP_Id = ppP.PP_Id
			LEFT JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = ppP.PP_Status_Id
			LEFT JOIN dbo.PrdExec_Paths pep ON pep.Path_Id = ppP.Path_Id
			LEFT JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			
			JOIN paths ON ppC.Path_Id = paths.Path_Id
 
			/* MK added - getting ReceivingStorageLocation from UDP of Line execution Path*/
			LEFT JOIN 
				(SELECT TFV.KeyId /*keyId is PathId*/, TFV.Value FROM dbo.Table_Fields_Values TFV  --ON TFV1.TableId=13 --AND TFV1.KeyId= 83 -- ppC.Path_Id --83 
				INNER JOIN Table_Fields TF1 ON TF1.TableId = TFV.TableId AND tf1.Table_Field_Id=TFV.Table_Field_Id
												AND tf1.Table_Field_Desc = 'PE_RTCISSIM_Line'
				WHERE TFV.TableId=13) RecStrgLoc ON RecStrgLoc.KeyId = ppC.Path_Id
 
			/* MK added - getting StorageLocation from UDP of Line execution Path*/
			LEFT JOIN 
				(SELECT TFV.KeyId /*keyId is PathId*/, TFV.Value FROM dbo.Table_Fields_Values TFV  --ON TFV1.TableId=13 --AND TFV1.KeyId= 83 -- ppC.Path_Id --83 
				INNER JOIN Table_Fields TF1 ON TF1.TableId = TFV.TableId AND tf1.Table_Field_Id=TFV.Table_Field_Id
												AND tf1.Table_Field_Desc = 'PE_RTCISSIM_WHSE'
				WHERE TFV.TableId=13) StrgLoc ON StrgLoc.KeyId = ppC.Path_Id
						
 
		WHERE ppC.PP_Id = @PPId )
	
 
