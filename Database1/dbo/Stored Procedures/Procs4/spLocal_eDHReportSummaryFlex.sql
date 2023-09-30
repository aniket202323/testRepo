-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Report Name ���������: spLocal_eDHReportSummaryFlex
-- Store PROCEDURE Name : spLocal_eDHReportSummaryFlex
--  ����������������������Facundo Sosa/Pablo Galanzini/Eduardo Mrakovich/Gonzalo Luc : Arido Software
--������������������������2016-02-11
--������������������������Store PROCEDURE re-writed TO meet Centerline configuration.
-------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2016-02-11		Gonzalo Luc		 		created
--================================================================================================

CREATE PROCEDURE [dbo].spLocal_eDHReportSummaryFlex  
	@MasterUnitId	INT,
	@StartTime		DATETIME,
	@EndTime		DATETIME

--SELECT	@MasterUnitId	= 132,
--			@StartTime		='2016-01-01 00:00:00',
--			@EndTime		='2016-02-01 00:00:00'

AS


-------------------------------------------------------------------------------------
--DECLARE OUTPUT TABLE
-------------------------------------------------------------------------------------
	DECLARE @eDefects TABLE(Id  			INT,
							FLCode			NVARCHAR(255),
							Description		NVARCHAR(MAX),
							DateFound  		DATETIME,
			 				DateSolved  	DATETIME,
							PMOpenDate  	DATETIME,
							PMCloseDate  	DATETIME,
							FLId  			INT,
        					SourceEventID	INT,
			 				SourceRecordID	INT,
			 				UserName		NVARCHAR(255),
			 				DefectTypeId	INT,
			 				DefectType  	NVARCHAR(255),
			 				DefectComponentId  INT,
			 				DefectComponent  	NVARCHAR(255),
			 				HowFoundId  		INT,
			 				HowFound  			NVARCHAR(255),
			 				PMNotification  	BIT,
			 				NotificationNum  	NVARCHAR(255),
			 				PMStatus  			NVARCHAR(255),
			 				PriorityId   		INT,
			 				Priority  			NVARCHAR(255),
			 				FileURL  			NVARCHAR(255),
			 				CM1Text  			NVARCHAR(255),
			 				CM2Text  			NVARCHAR(255),
			 				CM3Text  			NVARCHAR(255),
			 				CM1  				NVARCHAR(255),
			 				CM2  				NVARCHAR(255),
			 				CM3  				NVARCHAR(255),
			 				Responsibility  	NVARCHAR(255),
			 				WorkPlanId  		INT,
			 				WorkPlan  			NVARCHAR(255),
			 				imageValue64  		NVARCHAR(255),
			 				CreatedBy  			NVARCHAR(255),
			 				FoundBy  			NVARCHAR(255),
			 				ClosedBy  			NVARCHAR(255),
			 				FixedBy  			NVARCHAR(255),
			 				OtherFLDescription  NVARCHAR(255),
			 				Department  		NVARCHAR(255),
			 				ProdLineDesc  		NVARCHAR(255),
			 				ProdUnitDesc  		NVARCHAR(255),
			 				PUGroupDesc  		NVARCHAR(255),
			 				DepartmentId  		INT,
			 				ProdLineId  		INT,
			 				ProdUnitId  		INT,
			 				PUGroupId  			INT,
			 				NonEquipment  		BIT,
			 				CILLongDescription  NVARCHAR(MAX),
			 				Level 				INT,
							SummaryType			NVARCHAR(10)) 

-------------------------------------------------------------------------------------
--Summary Variables
-------------------------------------------------------------------------------------
	DECLARE		@TotalDefects   	INT ,
				@TotalFixed		INT ,
				@TotalOpen		INT ,
				@OpenThirtyDays	INT

-------------------------------------------------------------------------------------
--GET DATA Time Based.
-------------------------------------------------------------------------------------

	INSERT INTO @eDefects (			Id,
            						CM1,
            						CM2,
            						CM3,
            						CM1Text,
            						CM2Text,
            						CM3Text,
            						DateFound,
            						DateSolved,
            						FileURL,
            						NotificationNum,
            						PMCloseDate,
            						PMNotification,
            						PMOpenDate,
            						PMStatus,
            						Responsibility,
            						DefectTypeId,
            						DefectType,
            						DefectComponentId,
            						DefectComponent,
            						HowFoundId,
            						HowFound,
            						PriorityId,
            						Priority,
            						WorkPlanId,
            						SourceEventID,
            						SourceRecordID,
            						UserName,
            						Description,
            						ClosedBy,
            						FoundBy,
            						CreatedBy,
            						FixedBy,
            						OtherFLDescription,
            						FLId,
            						CILLongDescription,
            						NonEquipment,
									FLCode,
									SummaryType)

	SELECT			d.Id,
            		d.CM1,
            		d.CM2,
            		d.CM3,
            		d.CM1,
            		d.CM2,
            		d.CM3,
            		d.DateFound,
            		d.DateSolved,
            		d.FileURL,
            		d.NotificationNum,
           	 		d.PMCloseDate,
            		d.PMNotification,
            		d.PMOpenDate,
            		d.PMStatus,
            		d.Responsibility,
            		d.DefectTypeId,
            		defectType.GlobalName,
            		d.DefectComponentId,
            		defectComponent.GlobalName,
            		d.HowFoundId,
           			howFound.GlobalName,
            		d.PriorityId,
           			priority.GlobalName,
            		d.WorkPlanId,
            		d.SourceEventID,
            		d.SourceRecordID,
            		d.UserName,
            		d.Description,
            		d.ClosedBy,
            		d.FoundBy,
            		d.CreatedBy,
            		d.FixedBy,
            		d.OtherFLDescription,
           	 		d.FLId,
            		d.CILLongDescription,
            		d.NonEquipment,
		   			fl.FLCode,
					'TimeBased'		
	FROM 	dbo.Local_eDH_Defects d
	LEFT JOIN dbo.Local_eDH_List defectType ON d.DefectTypeId = defectType.Id
	LEFT JOIN dbo.Local_eDH_List defectComponent ON d.DefectComponentId = defectComponent.Id
	LEFT JOIN dbo.Local_eDH_List howFound ON d.HowFoundId = howFound.Id
 	LEFT JOIN dbo.Local_eDH_List priority ON d.PriorityId = priority.Id
	LEFT JOIN dbo.Local_eDH_FuncLocation fl ON d.FLId = fl.FLId 
	WHERE (DateFound <=@EndTime AND DateFound >=@StartTime OR @StartTime IS NULL)



-------------------------------------------------------------------------------------
--GET DATA Time Based.
-------------------------------------------------------------------------------------

	INSERT INTO @eDefects (			Id,
            						CM1,
            						CM2,
            						CM3,
            						CM1Text,
            						CM2Text,
            						CM3Text,
            						DateFound,
            						DateSolved,
            						FileURL,
            						NotificationNum,
            						PMCloseDate,
            						PMNotification,
            						PMOpenDate,
            						PMStatus,
            						Responsibility,
            						DefectTypeId,
            						DefectType,
            						DefectComponentId,
            						DefectComponent,
            						HowFoundId,
            						HowFound,
            						PriorityId,
            						Priority,
            						WorkPlanId,
            						SourceEventID,
            						SourceRecordID,
            						UserName,
            						Description,
            						ClosedBy,
            						FoundBy,
            						CreatedBy,
            						FixedBy,
            						OtherFLDescription,
            						FLId,
            						CILLongDescription,
            						NonEquipment,
									FLCode,
									SummaryType)

	SELECT			d.Id,
            		d.CM1,
            		d.CM2,
            		d.CM3,
            		d.CM1,
            		d.CM2,
            		d.CM3,
            		d.DateFound,
            		d.DateSolved,
            		d.FileURL,
            		d.NotificationNum,
           	 		d.PMCloseDate,
            		d.PMNotification,
            		d.PMOpenDate,
            		d.PMStatus,
            		d.Responsibility,
            		d.DefectTypeId,
            		defectType.GlobalName,
            		d.DefectComponentId,
            		defectComponent.GlobalName,
            		d.HowFoundId,
           			howFound.GlobalName,
            		d.PriorityId,
           			priority.GlobalName,
            		d.WorkPlanId,
            		d.SourceEventID,
            		d.SourceRecordID,
            		d.UserName,
            		d.Description,
            		d.ClosedBy,
            		d.FoundBy,
            		d.CreatedBy,
            		d.FixedBy,
            		d.OtherFLDescription,
           	 		d.FLId,
            		d.CILLongDescription,
            		d.NonEquipment,
		   			fl.FLCode,
					'OpenDefect'		
	FROM 	dbo.Local_eDH_Defects d
	LEFT JOIN dbo.Local_eDH_List defectType ON d.DefectTypeId = defectType.Id
	LEFT JOIN dbo.Local_eDH_List defectComponent ON d.DefectComponentId = defectComponent.Id
	LEFT JOIN dbo.Local_eDH_List howFound ON d.HowFoundId = howFound.Id
 	LEFT JOIN dbo.Local_eDH_List priority ON d.PriorityId = priority.Id
	LEFT JOIN dbo.Local_eDH_FuncLocation fl ON d.FLId = fl.FLId 
	WHERE DateSolved IS NULL




-------------------------------------------------------------------------------------
--GET Plant Model Ids
-------------------------------------------------------------------------------------

			---- Deparment
	UPDATE e
	SET e.DepartmentId = e.flid
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.flid = l.flid
	WHERE l.level = 1

			---- line
	UPDATE e
	SET 	e.ProdLineId = e.flid,	
		e.departmentid = l.ParentFLId
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.flid = l.flid
	WHERE l.level = 2

			---- Unit
	UPDATE e
	SET 	e.ProdUnitId = e.flid,	
		e.ProdLineId = l.ParentFLId
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.flid = l.flid
	WHERE l.level = 3

			---- Group
	UPDATE e
	SET 	e.PUGroupId = e.flid,	
		e.ProdUnitId = l.ParentFLId
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.flid = l.flid
	WHERE l.level = 4

			---- line 2
	UPDATE e
	SET 	e.ProdLineId = l.ParentFLId
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.ProdUnitId = l.flid
	WHERE e.ProdLineId IS NULL

			-- Deparment 2
	UPDATE e
	SET 	e.DepartmentId = l.ParentFLId
	FROM @eDefects e
		JOIN Local_eDH_FuncLocation l ON e.ProdLineId = l.flid
	WHERE e.DepartmentId IS NULL


-------------------------------------------------------------------------------------
--GET Plant Model Descriptions
-------------------------------------------------------------------------------------
	UPDATE e
	SET 	Department = d.EquipmentDesc,
		ProdLineDesc = ISNULL(' / '+l.EquipmentDesc,''),
		ProdUnitDesc = ISNULL(' / '+u.EquipmentDesc,''),
		PUGroupDesc = ISNULL(' / '+g.EquipmentDesc,'')
	FROM  @eDefects e
		LEFT JOIN Local_eDH_FuncLocation d ON e.departmentid = d.flid
		LEFT JOIN Local_eDH_FuncLocation l ON e.prodlineid = l.flid
		LEFT JOIN Local_eDH_FuncLocation u ON e.ProdUnitId = u.flid
		LEFT JOIN Local_eDH_FuncLocation g ON e.pugroupid = g.flid
				

	UPDATE e
	SET Department = Department + ISNULL(ProdLineDesc,'') + ISNULL(ProdUnitDesc,'') + ISNULL(PUGroupDesc,'')
	FROM  @eDefects e
	WHERE NonEquipment = 0 OR NonEquipment IS NULL

-------------------------------------------------------------------------------------
--UPDATE Plant Model Non Equipment
-------------------------------------------------------------------------------------


	UPDATE e
	SET 	DepartmentId = -1,
		Department = 'Non Equipment'
	FROM  @eDefects e
	WHERE NonEquipment = 1 AND DepartmentId IS NULL

	UPDATE e
	SET	ProdLineId = -1,
		Department = Department + ' / Non Equipment'
	FROM  @eDefects e
	WHERE NonEquipment = 1
		AND ProdLineId IS NULL
		AND DepartmentId > 0

	UPDATE e
	SET 	ProdUnitId = -1,
		Department = Department +  ProdLineDesc +' / Non Equipment'
	FROM  @eDefects e
	WHERE NonEquipment = 1
		AND ProdUnitId IS NULL
		AND DepartmentId > 0
		AND ProdLineId > 0

	UPDATE e
	SET 	PUGroupId = -1,
		Department = Department +  ProdLineDesc + ProdUnitDesc +' / Non Equipment'
	FROM  @eDefects e
	WHERE NonEquipment = 1
		AND PUGroupId IS NULL
		AND DepartmentId > 0
		AND ProdLineId > 0
		AND ProdUnitId > 0

-------------------------------------------------------------------------------------
--Get Counts 
-------------------------------------------------------------------------------------
	
	SELECT  @TotalOpen = COUNT(*) 
			FROM @eDefects ed 
			WHERE
				(ProdUnitId IN(SELECT FLId FROM dbo.Local_eDH_FuncLocation WHERE MasterUnitId = @MasterUnitId))
				AND   SummaryType = 'OpenDefect'		
		
				--Total OPEN +30 Dias
			
			SELECT	@OpenThirtyDays = COUNT(*) 
			FROM @eDefects ed 
			WHERE	(ProdUnitId IN(SELECT FLId FROM dbo.Local_eDH_FuncLocation WHERE MasterUnitId = @MasterUnitId))
				AND   SummaryType = 'OpenDefect'
				AND DATEADD(DAY,30,DateFound) <= GETDATE()
			

				
					--Total Defects Date Based
			SELECT	@TotalDefects = COUNT(*) 
			FROM @eDefects ed 
			WHERE	 (ProdUnitId IN(SELECT FLId FROM dbo.Local_eDH_FuncLocation WHERE MasterUnitId = @MasterUnitId))
				AND   (DateFound <=@EndTime AND DateFound >=@StartTime OR @StartTime IS NULL) 
				AND   SummaryType = 'TimeBased'
				

			SELECT	@TotalFixed = COUNT(*) 
			FROM @eDefects ed
			WHERE	(ProdUnitId IN(SELECT FLId FROM dbo.Local_eDH_FuncLocation WHERE MasterUnitId = @MasterUnitId))
				AND	(DateFound <=@EndTime AND DateFound >=@StartTime OR @StartTime IS NULL) 
				AND DateSolved IS NOT NULL
				AND SummaryType = 'TimeBased'
	

	
-------------------------------------------------------------------------------------
--OUTPUT
-------------------------------------------------------------------------------------


	SELECT			@OpenThirtyDays 'open30', 
					@TotalOpen		'totalOpen' ,
					@TotalFixed		'totalFixed',
					@TotalDefects	'totalDefects'
