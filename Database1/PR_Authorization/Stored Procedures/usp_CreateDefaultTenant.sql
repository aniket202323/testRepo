-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: [PR_Authorization].usp_CreateDefaultTenant

-- Create the default tenant record.

CREATE PROCEDURE [PR_Authorization].[usp_CreateDefaultTenant]
AS
BEGIN

	DECLARE @TenantId UNIQUEIDENTIFIER

	-- See if the default record exists already
	SELECT @TenantId = [PR_Authorization].ufn_GetDefaultTenant()

	-- default tenant does not exist, create it
	IF (@TenantId IS NULL)
		BEGIN
		INSERT INTO [PR_Authorization].Tenant (
			TenantId,
			Name,
			Description,
			Version
		) VALUES (
			'00000000-0000-0000-0000-000000000000',
			'Root System Tenant',
			'Root System Tenant',
			1
		)
	END

	RETURN 0
END