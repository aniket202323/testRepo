
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetTraversedProductionPlanProduct]
     @pp_start_id					int = NULL
    ,@startTime                     Datetime = NULL
    ,@endTime						Datetime = NULL
    ,@NextOrPrevious                nvarchar(10) = NULL ---- 'Previous', 'Current', 'Next'
	,@isIncremental					int = 0
AS
BEGIN
		SET NOCOUNT ON

		IF NOT EXISTS(Select 1 from dbo.Production_Plan_Starts WITH(NOLOCK) WHERE pp_start_id = @pp_start_id)
		BEGIN
			SELECT Error = 'ERROR: No Valid process order Found', Code = 'InvalidData', ErrorType = 'ValidProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

        DECLARE @ConvertedST DateTime, @ConvertedET DateTime , @DbTZ nvarchar(200), @UnitId int
		SELECT @UnitId = PPS.PU_ID FROM dbo.Production_Plan_Starts PPS WHERE PPS.pp_start_id = @pp_start_id
		SET @isIncremental = ISNULL(@isIncremental, 0)
        SELECT @DbTZ = [VALUE] FROM site_parameters WHERE parm_id = 192
        SET @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startTime, 'UTC')
        SET @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endTime, 'UTC')
       
		DECLARE @tempPPStartsId TABLE (
			Previous_Id int
			,Current_Id int
			,Next_Id int
		)
		DECLARE @tempPPStartsNameValue TABLE (
			ColValue nVARCHAR(50)
			,PP_Start_Id int
		)

        DECLARE @tempPPStarts TABLE (
            Id int
			,Department int
			,Department_Description nVARCHAR(255)
            ,Line int
            ,Line_Description nVARCHAR(255)
            ,Unit int
            ,Unit_Description nVARCHAR(255)
			,PP_Id int
            ,Process_Order nVARCHAR(100)
			,PP_Start_Id int
            ,PP_Start_Time datetime
            ,PP_End_Time datetime
            ,Product_Id int
            ,Product_Description nVARCHAR(255)
            ,Start_Time datetime
            ,End_Time datetime
            ,Production_Status nVARCHAR(100)
        )

		IF(@startTime IS NOT NULL AND @endTime IS NOT NULL)
		BEGIN
			GOTO TimeBased
		END
		ELSE IF(@NextOrPrevious IS NOT NULL)
		BEGIN
			GOTO NextOrPrevious
		END
		ELSE
		BEGIN
			SELECT Error = 'ERROR: Invalid Input Parameter', Code = 'InvalidParameter', ErrorType = 'InvalidInputParameter', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END

		NextOrPrevious:  

			INSERT INTO @tempPPStartsId
				SELECT * FROM (
					SELECT LAG(PPS.PP_start_id) OVER(PARTITION BY PPS.PU_Id ORDER BY PPS.Start_Time) PrevPPStart
					,PPS.PP_start_id PP_start_id
					,LEAD(PPS.PP_start_id) OVER(PARTITION BY PPS.PU_Id ORDER BY PPS.Start_Time) NextPPtStart
				FROM 
					dbo.Production_Plan_Starts PPS WITH(NOLOCK) 
				WHERE 
				PPS.PU_Id = @UnitId) AS A
			WHERE 
				A.PP_start_id = @pp_start_id


			INSERT INTO @tempPPStartsNameValue
			SELECT 'Previous' AS Name, Previous_Id AS Event_Id FROM @tempPPStartsId 
			UNION ALL
			SELECT 'Current' AS Name, Current_Id AS Event_Id FROM @tempPPStartsId	
			UNION ALL
			SELECT 'Next' AS Name, Next_Id AS Event_Id FROM @tempPPStartsId

			------Select next, previous and current batch order by event End_Time i.e. timestamp 
			INSERT INTO @tempPPStarts
				SELECT 
					Id = PPS.pp_start_id
					,Department = D.Dept_Id
					,Department_Description = D.Dept_Desc
					,Line = L.PL_Id
					,Line_Description = L.PL_Desc
					,Unit = U.PU_Id
					,Unit_Description = U.PU_Desc
					,PP_Id = PP.PP_id
					,Process_Order = PP.Process_Order
					,PP_Start_Id = PPS.PP_Start_Id
					,PP_Start_Time = PPS.Start_Time
					,PP_End_Time = ISNULL(PPS.End_Time, GETDATE())
					,Product = PB.Prod_Id
					,Product_Description = PB.Prod_Desc
					,Start_Time = PPS.Start_Time
					,End_Time = ISNULL(PPS.End_Time, GETDATE())
					,Production_Status = PS.ProdStatus_Desc
				FROM 
					dbo.Production_Plan_Starts          PPS  WITH(NOLOCK)
					JOIN dbo.Prod_Units_base            U  WITH(NOLOCK) ON PPS.PU_Id = U.PU_Id
					JOIN dbo.Prod_Lines_Base			L  WITH(NOLOCK) ON U.PL_Id = L.PL_Id
					JOIN dbo.Departments_Base			D  WITH(NOLOCK) ON L.Dept_Id = D.Dept_Id
					JOIN dbo.Production_Plan			PP WITH(NOLOCK) ON PPS.PP_Id = PP.PP_Id
					JOIN dbo.Production_Status			PS WITH(NOLOCK) ON PP.PP_status_id = PS.ProdStatus_Id
					JOIN dbo.Products_Base				PB WITH(NOLOCK) ON PP.Prod_Id = PB.Prod_Id
				WHERE 
					PPS.PP_start_id IN ((SELECT PP_Start_Id FROM @tempPPStartsNameValue)) 
					AND PPS.PU_Id = @UnitId
				ORDER BY
					 PPS.PU_Id, PPS.Start_Time
			
				SELECT 
					Id
					,Department
					,Department_Description
					,Line
					,Line_Description
					,Unit
					,Unit_Description
					,PP_Id
					,Process_Order
					,PP_Start_Id = TPPNV.PP_Start_Id
					,PP_Start_Time = dbo.fnServer_CmnConvertTime(PP_Start_Time, @DbTZ, 'UTC')
					,PP_End_Time = dbo.fnServer_CmnConvertTime(PP_End_Time, @DbTZ, 'UTC')
					,Product_Id
					,Product_Description
					,Start_Time = dbo.fnServer_CmnConvertTime(Start_Time, @DbTZ, 'UTC')
					,End_Time = dbo.fnServer_CmnConvertTime(End_Time, @DbTZ, 'UTC')
					,Production_Status
					,TPPNV.ColValue 
				FROM @tempPPStarts TPPS
					JOIN @tempPPStartsNameValue TPPNV ON TPPS.Id = TPPNV.PP_Start_Id 
				WHERE
					TPPNV.ColValue = @NextOrPrevious
			RETURN

		TimeBased:

			INSERT INTO @tempPPStarts
			SELECT 
				Id = PPS.pp_start_id
				,Department = D.Dept_Id
				,Department_Description = D.Dept_Desc
				,Line = L.PL_Id
				,Line_Description = L.PL_Desc
				,Unit = U.PU_Id
				,Unit_Description = U.PU_Desc
				,PP_Id = PP.PP_id
				,Process_Order = PP.Process_Order
				,PP_Start_Id = PPS.PP_Start_Id
				,PP_Start_Time = PPS.Start_Time
				,PP_End_Time = ISNULL(PPS.End_Time, GETDATE())
				,Product = PB.Prod_Id
				,Product_Description = PB.Prod_Desc
				,Start_Time = PPS.Start_Time
				,End_Time = ISNULL(PPS.End_Time, GETDATE())
				,Production_Status = PS.ProdStatus_Desc
			FROM 
				dbo.Production_Plan_Starts          PPS  WITH(NOLOCK)
				JOIN dbo.Prod_Units_base            U  WITH(NOLOCK) ON PPS.Pu_Id = U.Pu_Id
				JOIN dbo.Prod_Lines_Base			L  WITH(NOLOCK) ON U.PL_Id = L.PL_Id
				JOIN dbo.Departments_Base			D  WITH(NOLOCK) ON L.Dept_Id = D.Dept_Id
				JOIN dbo.Production_Plan			PP WITH(NOLOCK) ON PPS.PP_Id = PP.PP_Id
				JOIN dbo.Production_Status			PS WITH(NOLOCK) ON PP.PP_status_id = PS.ProdStatus_Id
				JOIN dbo.products_base				PB WITH(NOLOCK) ON PP.Prod_Id = PB.Prod_Id
			WHERE 
				((@ConvertedST <= PPS.End_Time  OR PPS.End_Time IS NULL)
				AND @ConvertedET > PPS.Start_Time)
				AND PPS.PU_Id = @UnitId
			ORDER BY
				 PPS.PU_Id, PPS.Start_Time
		
			SELECT 
				Id
				,Department
				,Department_Description
				,Line
				,Line_Description
				,Unit
				,Unit_Description
				,PP_Id
				,Process_Order
				,PP_Start_Id = TPPS.PP_Start_Id
				,PP_Start_Time = dbo.fnServer_CmnConvertTime(PP_Start_Time, @DbTZ, 'UTC')
				,PP_End_Time = dbo.fnServer_CmnConvertTime(PP_End_Time, @DbTZ, 'UTC')
				,Product_Id
				,Product_Description
				,Start_Time = dbo.fnServer_CmnConvertTime(Start_Time, @DbTZ, 'UTC')
				,End_Time = dbo.fnServer_CmnConvertTime(End_Time, @DbTZ, 'UTC')
				,Production_Status
				,NULL AS ColValue
			FROM 
				@tempPPStarts TPPS
			ORDER BY Start_Time
		RETURN
	END
GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetTraversedProductionPlanProduct] TO [ComXClient]