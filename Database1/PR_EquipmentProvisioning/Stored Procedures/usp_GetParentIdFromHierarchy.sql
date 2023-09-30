
-- =============================================
-- Author:		R Berry
-- Description:	Determines the immediate parent ID based on the parent hierarchy
-- =============================================
CREATE PROCEDURE PR_EquipmentProvisioning.usp_GetParentIdFromHierarchy
(
	@parent1 nvarchar(50),
	@parent2 nvarchar(50),
	@parent3 nvarchar(50),
	@parent4 nvarchar(50),
	@parent5 nvarchar(50),
	@parent6 nvarchar(50),
	@parent7 nvarchar(50),
	@parent8 nvarchar(50),
	@parent9 nvarchar(50),
	@parentId uniqueidentifier OUTPUT
)
AS
BEGIN
	SET @parentId = 
				CASE
					WHEN @parent1 IS NULL THEN NULL
					WHEN @parent2 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)
					WHEN @parent3 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2, PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))
					WHEN @parent4 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))
					WHEN @parent5 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))
					WHEN @parent6 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))
					WHEN @parent7 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))))
					WHEN @parent8 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))))
					WHEN @parent9 IS NULL THEN PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent8, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1))))))))					
					ELSE PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent9, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent8, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent7, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent6,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent5, PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent4 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent3 ,PR_EquipmentProvisioning.ufn_GetEquipmentIdFromName(@parent2 ,PR_EquipmentProvisioning.ufn_GetEnterpriseIdFromName(@parent1)))))))))				
				END
	RETURN
END