
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetProductionPlanBasedonCriteria]
        @dept_id                        int = NULL
       ,@line_id                        int = NULL
       ,@pu_id                          int = NULL
	   ,@name							nVARCHAR(255) = NULL
	   ,@product						nVARCHAR(255) = NULL
	   ,@asset							nVARCHAR(255) = NULL
	   ,@quantity						nVARCHAR(255) = NULL
	   ,@status							nVARCHAR(255) = NULL
	   ,@bom							nVARCHAR(255) = NULL
       ,@starttime                      datetime = NULL
       ,@endtime                        datetime = NULL
       ,@isIncremental                  int = NULL
	   ,@sortCol						nVARCHAR(100) = NULL
	   ,@sortOrder						nVARCHAR(100) = NULL
       ,@pageNumber                     bigint = NULL
       ,@pageSize                       bigint = NULL
AS
BEGIN
        SET NOCOUNT ON

        IF EXISTS(SELECT 1 FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id))
        BEGIN
            SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(@dept_id, @line_id, @pu_id)
            RETURN
        END
        DECLARE @ConvertedST DateTime, @ConvertedET datetime, @DbTZ nVARCHAR(255), @InitialST datetime, @TotalCount bigint     
        DECLARE @varProductionPlan TABLE (
             Id Int Identity(1,1)
			,Department int
			,Department_Description nVARCHAR(255)
			,Line int
			,Line_Description nVARCHAR(255)
			,Unit int
			,Unit_Description nVARCHAR(255)
			,PP_Start_Id int
			,Path_Id int
			,Path_desc nVARCHAR(255)
			,Production_Plan_Id int
			,Process_Order nVARCHAR(255)
			,Production_Plan_Start_Time datetime
			,Production_Plan_End_Time datetime
			,Start_Time datetime
			,End_Time datetime
			,Product int
			,Product_Description nVARCHAR(255)
			,BOM int
			,Production_Plan_Status int
			,Production_Plan_Status_Description nVARCHAR(100)
			,Quantity float
			,UOM nVARCHAR(50)
			,Production_Plan_Repeat int
        )

		SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192

		SELECT @isIncremental = ISNULL(@isIncremental, 0)       
		,@ConvertedST = CASE WHEN @starttime IS NULL THEN DATEADD(DAY, -4000, GETDATE()) ELSE dbo.fnServer_CmnConvertToDbTime(@starttime, 'UTC') END
		,@ConvertedET = CASE WHEN @endtime IS NULL THEN GETDATE() ELSE dbo.fnServer_CmnConvertToDbTime(@endtime, 'UTC') END
		,@PageNumber = CASE WHEN (@PageNumber IS NULL OR @PageNumber <= 0) THEN 1 ELSE @PageNumber END
		,@PageSize = CASE WHEN (@PageSize IS NULL OR @PageSize <= 0) THEN 10 ELSE @PageSize END
      
		;WITH CTE AS (
			SELECT 	
				Department = D.Dept_Id
                ,Department_Description = D.Dept_Desc
                ,Line = L.PL_Id
                ,Line_Description = L.PL_Desc
                ,Unit = U.PU_Id
                ,Unit_Description = U.PU_Desc
				,PP_Start_Id = PPS.PP_Start_Id
				,Path_Id = PP.Path_Id
				,Path_desc = PEP.Path_Desc
				,Production_Plan_Id = PP.PP_Id
				,Process_Order = PP.Process_Order
				,Production_Plan_Start_Time = PPS.Start_Time
				,Production_Plan_End_Time = ISNULL(PPS.End_Time, GETDATE())
				,Start_Time = PPS.Start_Time
				,End_Time =  ISNULL(PPS.End_Time, GETDATE())
				,Product = PP.Prod_Id
				,Product_Description = P.Prod_Desc
				,BOM = PP.BOM_Formulation_Id
				,Production_Plan_Status = PP.PP_Status_Id
				,Production_Plan_Status_Description = PS.ProdStatus_Desc
				,Quantity = PP.Forecast_Quantity
				,UOM = ES.dimension_X_Eng_Units
				,Production_Plan_Repeat = ROW_NUMBER() OVER (PARTITION BY PP.PP_Id ORDER BY PP.PP_Id)
			FROM 
				dbo.Departments_Base            D    WITH(NOLOCK)
				JOIN dbo.Prod_Lines_Base		L    WITH(NOLOCK)  ON D.Dept_Id = L.Dept_Id
				JOIN dbo.Prod_Units_Base        U    WITH(NOLOCK)  ON L.PL_Id = U.PL_Id
				JOIN production_plan_starts     PPS  WITH(NOLOCK)  ON U.PU_Id = PPS.PU_Id 
				JOIN dbo.Production_Plan        PP   WITH(NOLOCK)  ON PPS.PP_Id = PP.PP_Id 
				JOIN dbo.Prdexec_Paths			PEP  WITH(NOLOCK)  ON PP.Path_Id = PEP.Path_Id 
				JOIN dbo.Production_Status      PS   WITH(NOLOCK)  ON PP.PP_Status_Id = PS.ProdStatus_Id
				JOIN dbo.Products_Base			P    WITH(NOLOCK)  ON PP.Prod_Id = P.Prod_Id
				JOIN Event_Configuration        EC	 WITH(NOLOCK)  ON PPS.PU_Id = EC.PU_Id AND EC.event_subtype_id IS NOT NULL
				JOIN Event_Subtypes				ES	 WITH(NOLOCK)  ON EC.ET_Id = ES.event_subtype_id
			WHERE  
				D.Dept_Id = ISNULL(@dept_id, D.Dept_Id)
				AND L.PL_Id = ISNULL(@line_id, L.PL_Id)
				AND U.PU_Id = ISNULL(@pu_id, U.PU_Id)
				AND @ConvertedET >= PPS.Start_Time
				AND (@ConvertedST <= PPS.End_Time OR PPS.Start_Time BETWEEN @ConvertedST AND @ConvertedET)
				AND P.Prod_Desc = ISNULL(@product, P.Prod_Desc)
				AND PS.ProdStatus_Desc = ISNULL(@status, PS.ProdStatus_Desc)
				AND ISNULL(PP.Process_Order,'') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@name) + '%'
				AND ISNULL(U.PU_Desc, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@asset) + '%'
				AND ISNULL(PP.Forecast_Quantity, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@quantity) + '%'
				AND ISNULL(PP.BOM_Formulation_Id, '') LIKE '%' + [dbo].[fnMesData_ProcAnz_SpecialToString](@bom) + '%'
			)
			INSERT INTO @varProductionPlan
			SELECT * FROM CTE ORDER BY Unit, Production_Plan_Start_Time, Production_Plan_End_Time

			IF NOT EXISTS(SELECT 1 FROM @varProductionPlan ORDER BY Unit, Production_Plan_Start_Time OFFSET @pageSize * (@PageNumber - 1) ROWS FETCH NEXT @pageSize ROWS ONLY)
			BEGIN
				SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END

			SET @TotalCount = (SELECT COUNT(*) FROM @varProductionPlan)
			SELECT @InitialST = MIN(PP.Production_Plan_Start_Time) FROM @varProductionPlan PP
			SELECT 
				SL_No = PP.Id
				,PP.Department
				,PP.Department_Description
				,PP.Line
				,PP.Line_Description
				,PP.Unit
				,PP.Unit_Description
				,PP_Start_Id
				,PP.Path_Id
				,PP.Path_Desc
				,PP.Production_Plan_Id
				,PP.Process_Order
				,Production_Plan_Start_Time = dbo.fnServer_CmnConvertTime(PP.Production_Plan_Start_Time, @DbTZ,'UTC')
				,Production_Plan_End_Time = dbo.fnServer_CmnConvertTime(PP.Production_Plan_End_Time, @DbTZ,'UTC')
				,Start_Time = dbo.fnServer_CmnConvertTime(PP.Start_Time, @DbTZ,'UTC')
				,End_Time = dbo.fnServer_CmnConvertTime(PP.End_Time, @DbTZ,'UTC')
				,PP.Product
				,PP.Product_Description 
				,PP.BOM
				,PP.Production_Plan_Status
				,PP.Production_Plan_Status_Description 
				,PP.Quantity
				,PP.UOM
				,NbResults = @TotalCount
				,CurrentPage = @pageNumber 
				,PageSize = @pageSize 
				,TotalPages = FLOOR(CEILING(Cast(@TotalCount as decimal(18,2))/ @PageSize)) 
			FROM
				@varProductionPlan PP
			ORDER BY 
			/* for Name */
			CASE WHEN @sortCol='Name'  AND @sortOrder = 'ASC' THEN Process_Order END ASC,
			CASE WHEN @sortCol='Name'  AND @sortOrder = 'DESC' THEN Process_Order END DESC,
			/* for Product */
			CASE WHEN @sortCol='Product'  AND @sortOrder = 'ASC' THEN Product_Description END ASC,
			CASE WHEN @sortCol='Product'  AND @sortOrder = 'DESC' THEN Product_Description END DESC,
			/* for Asset */
			CASE WHEN @sortCol='Asset'  AND @sortOrder = 'ASC' THEN Unit_Description END ASC,
			CASE WHEN @sortCol='Asset'  AND @sortOrder = 'DESC' THEN Unit_Description END DESC,
			/* for Start */
			CASE WHEN @sortCol='Start'  AND @sortOrder = 'ASC' THEN Production_Plan_Start_Time END ASC,
			CASE WHEN @sortCol='Start'  AND @sortOrder = 'DESC' THEN Production_Plan_Start_Time END DESC,
			/* for End */
			CASE WHEN @sortCol='End'  AND @sortOrder = 'ASC' THEN Production_Plan_End_Time END ASC,
			CASE WHEN @sortCol='End'  AND @sortOrder = 'DESC' THEN Production_Plan_End_Time END DESC,
			/* for Quantity */
			CASE WHEN @sortCol='Quantity'  AND @sortOrder = 'ASC' THEN Quantity END ASC,
			CASE WHEN @sortCol='Quantity'  AND @sortOrder = 'DESC' THEN Quantity END DESC,
			/* for Status */
			CASE WHEN @sortCol='Status'  AND @sortOrder = 'ASC' THEN Product_Description END ASC,
			CASE WHEN @sortCol='Status'  AND @sortOrder = 'DESC' THEN Production_Plan_Status_Description END DESC,
			/* for BoM */
			CASE WHEN @sortCol='BoM' AND @sortOrder = 'ASC' THEN BOM END ASC,
			CASE WHEN @sortCol='BoM' AND @sortOrder = 'DESC' THEN BOM END DESC,
			/* default */
			CASE WHEN @sortCol IS NULL AND @sortOrder IS NULL THEN Unit END DESC
			/* For pagination */
			OFFSET @pageSize * (@PageNumber - 1) ROWS FETCH NEXT @pageSize ROWS ONLY;


			SELECT DISTINCT 
			id = CASE WHEN @dept_id IS NULL THEN Department 
							WHEN @line_id IS NULL THEN Line
							ELSE Unit END	
			,name = CASE WHEN @dept_id IS NULL THEN Department_Description 
							WHEN @line_id IS NULL THEN Line_Description
							ELSE Unit_Description END
			,AssetType = CASE WHEN @dept_id IS NULL THEN 'Department' 
							WHEN @line_id IS NULL THEN 'Line'
							ELSE 'Unit' END
			FROM 
				@varProductionPlan

			SELECT DISTINCT 
				id = Production_Plan_Status
				,name = Production_Plan_Status_Description		
			FROM 
				@varProductionPlan
			WHERE Production_Plan_Status IS NOT NULL

			SELECT DISTINCT 
				id = Product
				,name = Product_Description		
			FROM 
				@varProductionPlan
			WHERE 
				Product IS NOT NULL

			SET NOCOUNT OFF

END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetProductionPlanBasedonCriteria] TO [ComXClient]