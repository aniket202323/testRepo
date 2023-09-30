
-- =============================================
-- Author:		R Berry
-- Description:	Determines an equipment id based on name and the names of parents
-- =============================================
CREATE PROCEDURE PR_EquipmentProvisioning.usp_GetEquipmentIdFromHierarchy
(
	@equipmentName nvarchar(50),
	@parent1 nvarchar(50),
	@parent2 nvarchar(50),
	@parent3 nvarchar(50),
	@parent4 nvarchar(50),
	@parent5 nvarchar(50),
	@parent6 nvarchar(50),
	@parent7 nvarchar(50),
	@parent8 nvarchar(50),
	@parent9 nvarchar(50),
	@equipmentId uniqueidentifier OUTPUT
)
AS
BEGIN

	-- temporary table to cache EquipmentIds
	IF OBJECT_ID('tempdb..#EquipmentIdLookup') IS NULL
	BEGIN
		CREATE TABLE #EquipmentIdLookup (
			[EquipmentName] NVARCHAR(50) NOT NULL, 
			[Parent1] NVARCHAR(50) NULL, 
			[Parent2] NVARCHAR(50) NULL, 
			[Parent3] NVARCHAR(50) NULL, 
			[Parent4] NVARCHAR(50) NULL, 
			[Parent5] NVARCHAR(50) NULL, 
			[Parent6] NVARCHAR(50) NULL, 
			[Parent7] NVARCHAR(50) NULL, 
			[Parent8] NVARCHAR(50) NULL, 
			[Parent9] NVARCHAR(50) NULL, 
			[EquipmentId] UNIQUEIDENTIFIER NOT NULL,
			CONSTRAINT [PK_EquipmentIdLookup] PRIMARY KEY NONCLUSTERED (EquipmentId)
		)
		-- Deliberately leaving Parent9 out of index to avoid hitting SQL server max key length. Parent9 unlikely to be used in typical situations
		CREATE CLUSTERED INDEX [IX_EquipmentIdLookup_EquipmentParents] ON #EquipmentIdLookup(EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8)
	END

	SET @equipmentId = 
		(SELECT EquipmentId FROM #EquipmentIdLookup WHERE
		  EquipmentName = @equipmentName AND
		  (Parent1 = @parent1 OR (Parent1 IS NULL AND @parent1 IS NULL)) AND
		  (Parent2 = @parent2 OR (Parent2 IS NULL AND @parent2 IS NULL)) AND
		  (Parent3 = @parent3 OR (Parent3 IS NULL AND @parent3 IS NULL)) AND
		  (Parent4 = @parent4 OR (Parent4 IS NULL AND @parent4 IS NULL)) AND
		  (Parent5 = @parent5 OR (Parent5 IS NULL AND @parent5 IS NULL)) AND
		  (Parent6 = @parent6 OR (Parent6 IS NULL AND @parent6 IS NULL)) AND
		  (Parent7 = @parent7 OR (Parent7 IS NULL AND @parent7 IS NULL)) AND
		  (Parent8 = @parent8 OR (Parent8 IS NULL AND @parent8 IS NULL)) AND
		  (Parent9 = @parent9 OR (Parent9 IS NULL AND @parent9 IS NULL)))

	IF @equipmentId IS NULL
		BEGIN
			SET @equipmentId = 
				CASE
					WHEN @parent1 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@equipmentName)
					WHEN @parent2 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))
					WHEN @parent3 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2, PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))	
					WHEN @parent4 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))
					WHEN @parent5 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))
					WHEN @parent6 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))))
					WHEN @parent7 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))))
					WHEN @parent8 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))))))
					WHEN @parent9 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent8, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))))))					
					ELSE PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@equipmentName, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent9, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent8, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))))))))				
				END

			IF (@equipmentId IS NOT NULL)
				INSERT INTO #EquipmentIdLookup (EquipmentName, Parent1, Parent2, Parent3, Parent4, Parent5, Parent6, Parent7, Parent8, Parent9, EquipmentId)
					VALUES(@equipmentName, @parent1, @parent2, @parent3, @parent4, @parent5, @parent6, @parent7, @parent8, @parent9, @equipmentId)	
		END

	RETURN
END